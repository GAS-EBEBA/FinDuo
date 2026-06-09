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
    nourriture => Icons.lunch_dining_rounded,
    transport => Icons.directions_bus_rounded,
    maison => Icons.house_rounded,
    loisirs => Icons.local_activity_rounded,
    sante => Icons.medical_services_rounded,
    autres => Icons.receipt_long_rounded,
  };

  Color get color => switch (this) {
    nourriture => const Color(0xFFFF7043),
    transport => const Color(0xFF42A5F5),
    maison => const Color(0xFF66BB6A),
    loisirs => const Color(0xFFAB47BC),
    sante => const Color(0xFFEF5350),
    autres => const Color(0xFF78909C),
  };
}

class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String payerName;
  final String creatorName;
  final DateTime date;
  final String? note;
  final String userId;
  final String? coupleId;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.payerName,
    required this.creatorName,
    required this.date,
    this.note,
    required this.userId,
    this.coupleId,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawDate = data['date'];
    final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();
    return Expense(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExpenseCategory.autres,
      ),
      payerName: data['payerName'] as String? ?? 'Moi',
      creatorName: data['creatorName'] as String? ?? 'Moi',
      date: date,
      note: data['note'] as String?,
      userId: data['userId'] as String? ?? '',
      coupleId: data['coupleId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'amount': amount,
    'category': category.name,
    'payerName': payerName,
    'creatorName': creatorName,
    'date': Timestamp.fromDate(date),
    'note': note,
    'userId': userId,
    'coupleId': coupleId,
  };
}
