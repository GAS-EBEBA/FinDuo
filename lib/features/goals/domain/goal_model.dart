import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ProjectStatus {
  planning,
  active,
  paused,
  completed;

  String get label => switch (this) {
    planning => 'Planification',
    active => 'En cours',
    paused => 'En pause',
    completed => 'Terminé',
  };

  static ProjectStatus fromName(String? value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ProjectStatus.planning,
    );
  }
}

enum GoalType {
  planning,
  project;

  String get label => switch (this) {
    planning => 'Planification',
    project => 'Gestion de projet',
  };

  static GoalType fromName(String? value) {
    return GoalType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => GoalType.planning,
    );
  }
}

class ProjectTask {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDone;

  const ProjectTask({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isDone = false,
  });

  factory ProjectTask.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.now();
    }

    return ProjectTask(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      startDate: parseDate(data['startDate']),
      endDate: parseDate(data['endDate']),
      isDone: data['isDone'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'isDone': isDone,
  };

  ProjectTask copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDone,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isDone: isDone ?? this.isDone,
    );
  }
}

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
      id: doc.id,
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      date: (d['date'] as Timestamp).toDate(),
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final double spentAmount;
  final DateTime? startDate;
  final DateTime? targetDate;
  final String coupleId;
  final int colorValue;
  final bool isArchived;
  final ProjectStatus status;
  final List<ProjectTask> tasks;
  final GoalType type;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.spentAmount = 0,
    this.startDate,
    this.targetDate,
    required this.coupleId,
    required this.colorValue,
    this.isArchived = false,
    this.status = ProjectStatus.planning,
    this.tasks = const [],
    this.type = GoalType.planning,
  });

  Color get color => Color(colorValue);
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);
  double get budgetRemaining =>
      (targetAmount - spentAmount).clamp(0, double.infinity);
  double get spendingProgress =>
      targetAmount > 0 ? (spentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get taskProgress => tasks.isEmpty
      ? 0.0
      : tasks.where((task) => task.isDone).length / tasks.length;
  int get completedTasks => tasks.where((task) => task.isDone).length;

  int? get totalDurationDays {
    if (startDate == null || targetDate == null) return null;
    return targetDate!
        .difference(DateTime(startDate!.year, startDate!.month, startDate!.day))
        .inDays
        .clamp(0, 5000);
  }

  double get timeProgress {
    if (startDate == null || targetDate == null) return 0;
    final total = targetDate!.difference(startDate!).inDays;
    if (total <= 0) return 0;
    final elapsed = DateTime.now().difference(startDate!).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    double? spentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    String? coupleId,
    int? colorValue,
    bool? isArchived,
    ProjectStatus? status,
    List<ProjectTask>? tasks,
    GoalType? type,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      coupleId: coupleId ?? this.coupleId,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      type: type ?? this.type,
    );
  }

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (data['spentAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      targetDate: data['targetDate'] != null
          ? (data['targetDate'] as Timestamp).toDate()
          : null,
      coupleId: data['coupleId'] as String? ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFF6C63FF,
      isArchived: data['isArchived'] == true,
      status: ProjectStatus.fromName(data['status'] as String?),
      type: GoalType.fromName(data['type'] as String?),
      tasks: ((data['tasks'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => ProjectTask.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'spentAmount': spentAmount,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
    'coupleId': coupleId,
    'colorValue': colorValue,
    'isArchived': isArchived,
    'status': status.name,
    'tasks': tasks.map((task) => task.toMap()).toList(),
    'type': type.name,
  };
}
