import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/goals/domain/goal_model.dart';
import 'package:gestionbudget/features/goals/domain/planned_expense_model.dart';
import 'package:gestionbudget/shared/providers/connectivity_provider.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/utils/firestore_write.dart';

/// Stream temps réel pour un projet individuel (rafraîchit le détail en live).
final goalStreamProvider = StreamProvider.family<Goal?, String>((ref, goalId) {
  return FirebaseFirestore.instance
      .collection('goals')
      .doc(goalId)
      .snapshots()
      .map((doc) => doc.exists ? Goal.fromFirestore(doc) : null);
});

/// Historique des alimentations d'un projet donné, trié par date décroissante.
final fundingHistoryProvider =
    StreamProvider.family<List<FundingEntry>, String>((ref, goalId) {
      return FirebaseFirestore.instance
          .collection('goals')
          .doc(goalId)
          .collection('fundings')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(FundingEntry.fromDoc).toList());
    });

/// Projets actifs (non archivés).
final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final coupleId = ref.watch(coupleFutureProvider).asData?.value;
  if (coupleId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('goals')
      .where('coupleId', isEqualTo: coupleId)
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map(Goal.fromFirestore)
            .where((g) => g.isArchived != true)
            .toList();
        list.sort((a, b) {
          if (a.targetDate == null) return 1;
          if (b.targetDate == null) return -1;
          return a.targetDate!.compareTo(b.targetDate!);
        });
        return list;
      });
});

final planningGoalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final goals = ref.watch(goalsStreamProvider).asData?.value ?? [];
  return Stream.value(
    goals.where((goal) => goal.type == GoalType.planning).toList(),
  );
});

final projectManagementGoalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final goals = ref.watch(goalsStreamProvider).asData?.value ?? [];
  return Stream.value(
    goals.where((goal) => goal.type == GoalType.project).toList(),
  );
});

/// Projets archivés.
final archivedGoalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final coupleId = ref.watch(coupleFutureProvider).asData?.value;
  if (coupleId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('goals')
      .where('coupleId', isEqualTo: coupleId)
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map(Goal.fromFirestore)
            .where((g) => g.isArchived == true)
            .toList();
        list.sort((a, b) => b.id.compareTo(a.id));
        return list;
      });
});

final plannedExpensesStreamProvider = StreamProvider<List<PlannedExpense>>((
  ref,
) {
  final coupleId = ref.watch(coupleFutureProvider).asData?.value;
  if (coupleId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('planned_expenses')
      .where('coupleId', isEqualTo: coupleId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(PlannedExpense.fromFirestore).toList();
        list.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
        return list;
      });
});

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, void>(
  GoalsNotifier.new,
);

class GoalsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  bool get _isOnline => ref.read(connectivityProvider).asData?.value ?? true;

  Future<void> addGoal(Goal goal) => guardedWrite(_isOnline, () async {
    await FirebaseFirestore.instance
        .collection('goals')
        .add(goal.toFirestore());
  });

  Future<void> addFunds(String goalId, double amount) =>
      guardedWrite(_isOnline, () async {
        final goalRef =
            FirebaseFirestore.instance.collection('goals').doc(goalId);
        final batch = FirebaseFirestore.instance.batch();
        batch.update(goalRef, {'currentAmount': FieldValue.increment(amount)});
        batch.set(goalRef.collection('fundings').doc(), {
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      });

  Future<void> archiveGoal(String goalId) => guardedWrite(_isOnline, () async {
    await FirebaseFirestore.instance.collection('goals').doc(goalId).update({
      'isArchived': true,
    });
  });

  Future<void> unarchiveGoal(String goalId) =>
      guardedWrite(_isOnline, () async {
        await FirebaseFirestore.instance
            .collection('goals')
            .doc(goalId)
            .update({'isArchived': false});
      });

  Future<void> deleteGoal(String goalId) => guardedWrite(_isOnline, () async {
    await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
  });

  Future<void> updateGoal(String goalId, Map<String, dynamic> data) =>
      guardedWrite(_isOnline, () async {
        await FirebaseFirestore.instance
            .collection('goals')
            .doc(goalId)
            .update(data);
      });

  Future<void> updateProjectStatus(String goalId, ProjectStatus status) async {
    await updateGoal(goalId, {'status': status.name});
  }

  Future<void> updateSpentAmount(String goalId, double spentAmount) async {
    await updateGoal(goalId, {'spentAmount': spentAmount});
  }

  Future<void> saveTasks(String goalId, List<ProjectTask> tasks) async {
    await updateGoal(goalId, {
      'tasks': tasks.map((task) => task.toMap()).toList(),
    });
  }
}

final plannedExpensesProvider =
    AsyncNotifierProvider<PlannedExpensesNotifier, void>(
      PlannedExpensesNotifier.new,
    );

class PlannedExpensesNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  bool get _isOnline => ref.read(connectivityProvider).asData?.value ?? true;

  Future<void> add(PlannedExpense expense) => guardedWrite(_isOnline, () async {
    await FirebaseFirestore.instance
        .collection('planned_expenses')
        .add(expense.toFirestore());
  });

  Future<void> delete(String id) => guardedWrite(_isOnline, () async {
    await FirebaseFirestore.instance
        .collection('planned_expenses')
        .doc(id)
        .delete();
  });
}
