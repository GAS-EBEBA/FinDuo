import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FundingEntry {
  final String id;
  final double amount;
  final DateTime date;

  const FundingEntry({
    required this.id,
    required this.amount,
    required this.date,
  });

  factory FundingEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FundingEntry(
      id:     doc.id,
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      date:   (d['date'] as Timestamp).toDate(),
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String coupleId;
  final int colorValue;
  final bool isArchived;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.coupleId,
    required this.colorValue,
    this.isArchived = false,
  });

  Color get color => Color(colorValue);
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Goal(
      id:            doc.id,
      title:         data['title']         as String? ?? '',
      description:   data['description']   as String?,
      targetAmount:  (data['targetAmount']  as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate:    data['targetDate'] != null
          ? (data['targetDate'] as Timestamp).toDate()
          : null,
      coupleId:      data['coupleId']   as String? ?? '',
      colorValue:    data['colorValue'] as int?    ?? 0xFF6C63FF,
      isArchived:    data['isArchived'] == true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title':         title,
        'description':   description,
        'targetAmount':  targetAmount,
        'currentAmount': currentAmount,
        'targetDate':
            targetDate != null ? Timestamp.fromDate(targetDate!) : null,
        'coupleId':   coupleId,
        'colorValue': colorValue,
        'isArchived': isArchived,
      };
}
