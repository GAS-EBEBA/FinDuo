import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/goals/domain/goal_model.dart';
import 'package:gestionbudget/features/goals/domain/planned_expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';

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
    final ref =
        FirebaseFirestore.instance.collection('goals').doc(goalId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final current =
          (doc.data()?['currentAmount'] as num?)?.toDouble() ?? 0.0;
      tx.update(ref, {'currentAmount': current + amount});
    });
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
