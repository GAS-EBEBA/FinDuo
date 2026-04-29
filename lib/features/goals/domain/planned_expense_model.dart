import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';

class PlannedExpense {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime plannedDate;
  final String coupleId;
  final String? note;

  const PlannedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.plannedDate,
    required this.coupleId,
    this.note,
  });

  factory PlannedExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlannedExpense(
      id: doc.id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExpenseCategory.autres,
      ),
      plannedDate: (data['plannedDate'] as Timestamp).toDate(),
      coupleId: data['coupleId'] as String? ?? '',
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'amount': amount,
        'category': category.name,
        'plannedDate': Timestamp.fromDate(plannedDate),
        'coupleId': coupleId,
        'note': note,
      };
}
