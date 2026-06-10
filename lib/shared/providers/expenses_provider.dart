import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/connectivity_provider.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/utils/firestore_write.dart';

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final couple = ref.watch(coupleProvider);
  
  if (couple.userId == null) return Stream.value([]);

  // Construit la liste des userIds à chercher
  final userIds = [couple.userId!];
  if (couple.partnerId != null) {
    userIds.add(couple.partnerId!);
  }

  // Récupère les dépenses de l'utilisateur ET du partenaire s'il existe
  return FirebaseFirestore.instance
      .collection('expenses')
      .where('userId', whereIn: userIds)
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map((doc) {
              try {
                return Expense.fromFirestore(doc);
              } catch (_) {
                return null;
              }
            })
            .whereType<Expense>()
            .toList();
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
    final isOnline = ref.read(connectivityProvider).asData?.value ?? true;
    state = await AsyncValue.guard<void>(() => guardedWrite(isOnline, () async {
      await FirebaseFirestore.instance
          .collection('expenses')
          .add(expense.toFirestore());
    }));
  }

  Future<void> deleteExpense(String expenseId) async {
    state = const AsyncValue.loading();
    final isOnline = ref.read(connectivityProvider).asData?.value ?? true;
    state = await AsyncValue.guard<void>(() => guardedWrite(isOnline, () async {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expenseId)
          .delete();
    }));
  }
}
