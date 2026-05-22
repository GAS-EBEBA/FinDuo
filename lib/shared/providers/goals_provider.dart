import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/goals/domain/goal_model.dart';
import 'package:gestionbudget/features/goals/domain/planned_expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';

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

final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final coupleId = ref.watch(coupleFutureProvider).asData?.value;
  if (coupleId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('goals')
      .where('coupleId', isEqualTo: coupleId)
      .snapshots()
      .map((snap) {
    final list = snap.docs.map(Goal.fromFirestore).toList();
    list.sort((a, b) {
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      return a.targetDate!.compareTo(b.targetDate!);
    });
    return list;
  });
});

final plannedExpensesStreamProvider = StreamProvider<List<PlannedExpense>>((ref) {
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

final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, void>(GoalsNotifier.new);

class GoalsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addGoal(Goal goal) async {
    await FirebaseFirestore.instance
        .collection('goals')
        .add(goal.toFirestore());
  }

  Future<void> addFunds(String goalId, double amount) async {
    final goalRef = FirebaseFirestore.instance.collection('goals').doc(goalId);
    final batch = FirebaseFirestore.instance.batch();
    // Incrémente le montant courant
    batch.update(goalRef, {'currentAmount': FieldValue.increment(amount)});
    // Enregistre l'alimentation dans la sous-collection
    batch.set(goalRef.collection('fundings').doc(), {
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteGoal(String goalId) async {
    await FirebaseFirestore.instance
        .collection('goals')
        .doc(goalId)
        .delete();
  }
}

final plannedExpensesProvider =
    AsyncNotifierProvider<PlannedExpensesNotifier, void>(
        PlannedExpensesNotifier.new);

class PlannedExpensesNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> add(PlannedExpense expense) async {
    await FirebaseFirestore.instance
        .collection('planned_expenses')
        .add(expense.toFirestore());
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance
        .collection('planned_expenses')
        .doc(id)
        .delete();
  }
}
