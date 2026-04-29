import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ExpenseCategory {
  nourriture('Nourriture'),
  transport('Transport'),
  maison('Maison'),
  loisirs('Loisirs'),
  sante('Santé'),
  autres('Autres');

  const ExpenseCategory(this.displayName);
  final String displayName;

  IconData get icon => switch (this) {
        nourriture => Icons.restaurant_rounded,
        transport  => Icons.directions_car_rounded,
        maison     => Icons.home_rounded,
        loisirs    => Icons.celebration_rounded,
        sante      => Icons.favorite_rounded,
        autres     => Icons.grid_view_rounded,
      };

  Color get color => switch (this) {
        nourriture => const Color(0xFFFF7043),
        transport  => const Color(0xFF42A5F5),
        maison     => const Color(0xFF66BB6A),
        loisirs    => const Color(0xFFAB47BC),
        sante      => const Color(0xFFEF5350),
        autres     => const Color(0xFF78909C),
      };
}

class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String payerName;
  final DateTime date;
  final String? note;
  final String userId;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.payerName,
    required this.date,
    this.note,
    required this.userId,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      amount: data['amount']?.toDouble() ?? 0.0,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExpenseCategory.autres,
      ),
      payerName: data['payerName'] as String? ?? 'Moi',
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'],
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'amount': amount,
        'category': category.name,
        'payerName': payerName,
        'date': Timestamp.fromDate(date),
        'note': note,
        'userId': userId,
      };
}
