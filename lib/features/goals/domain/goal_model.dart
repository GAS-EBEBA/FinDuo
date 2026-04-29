import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String userId;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.userId,
  });

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      title: data['title'],
      targetAmount: data['targetAmount']?.toDouble() ?? 0.0,
      currentAmount: data['currentAmount']?.toDouble() ?? 0.0,
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': Timestamp.fromDate(targetDate),
      'userId': userId,
    };
  }
}