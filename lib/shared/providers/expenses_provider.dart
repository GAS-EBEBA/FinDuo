import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final userId = ref.watch(coupleProvider.select((s) => s.userId));
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('expenses')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(Expense.fromFirestore).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });
});

final addExpenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, void>(ExpenseNotifier.new);

class ExpenseNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addExpense(Expense expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<void>(() async {
      await FirebaseFirestore.instance
          .collection('expenses')
          .add(expense.toFirestore());
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<void>(() async {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expenseId)
          .delete();
    });
  }
}
