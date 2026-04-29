import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final double monthlyLimit;
  final DateTime month;
  final String userId;

  Budget({
    required this.id,
    required this.monthlyLimit,
    required this.month,
    required this.userId,
  });

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      monthlyLimit: data['monthlyLimit']?.toDouble() ?? 0.0,
      month: (data['month'] as Timestamp).toDate(),
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monthlyLimit': monthlyLimit,
      'month': Timestamp.fromDate(month),
      'userId': userId,
    };
  }
}