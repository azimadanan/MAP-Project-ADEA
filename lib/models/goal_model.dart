import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// GoalModel — Long-term goal stored in Firestore at users/{uid}/goals/{id}
class GoalModel extends Equatable {
  final String id;
  final String title;
  final double targetValue;
  final double currentValue;
  final DateTime? deadline;

  const GoalModel({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    this.deadline,
  });

  /// Progress from 0.0 to 1.0, clamped when target is zero
  double get progressFraction {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  int get progressPercent => (progressFraction * 100).round();

  factory GoalModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parsedDeadline;
    final rawDeadline = map['deadline'];
    if (rawDeadline is Timestamp) {
      parsedDeadline = rawDeadline.toDate();
    } else if (rawDeadline != null) {
      parsedDeadline = DateTime.tryParse(rawDeadline.toString());
    }

    return GoalModel(
      id: id,
      title: map['title'] as String? ?? '',
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0.0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      deadline: parsedDeadline,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    };
  }

  GoalModel copyWith({
    String? id,
    String? title,
    double? targetValue,
    double? currentValue,
    DateTime? deadline,
    bool clearDeadline = false,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
    );
  }

  @override
  List<Object?> get props => [id, title, targetValue, currentValue, deadline];
}
