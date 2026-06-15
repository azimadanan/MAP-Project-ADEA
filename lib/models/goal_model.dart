import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// GoalModel — Long-term goal stored in Firestore at users/{uid}/goals/{id}
class GoalModel extends Equatable {
  final String id;
  final String title;
  final double targetValue;
  final double currentValue;
  final DateTime? deadline;
  final String unit;

  const GoalModel({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    this.deadline,
    this.unit = 'RM',
  });

  /// Progress from 0.0 to 1.0, clamped when target is zero
  double get progressFraction {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  int get progressPercent => (progressFraction * 100).round();

  /// Unit shown in progress text and feedback (infers from title when needed)
  String get displayUnit {
    if (unit != 'RM') return unit;
    return _inferUnitFromTitle(title) ?? 'RM';
  }

  static String? _inferUnitFromTitle(String title) {
    final lower = title.toLowerCase();
    final patterns = <String, RegExp>{
      'km': RegExp(r'\b\d*\s*km\b|\bkm\b'),
      'kg': RegExp(r'\b\d*\s*kg\b|\bkg\b'),
      'g': RegExp(r'\b\d+\s*g\b'),
      'lbs': RegExp(r'\blbs?\b'),
      'pages': RegExp(r'\bpages?\b'),
      'glasses': RegExp(r'\bglasses?\b'),
      'litres': RegExp(r'\blitres?|\bliters?\b'),
      'hours': RegExp(r'\bhours?|\bhrs?\b'),
      'minutes': RegExp(r'\bminutes?|\bmins?\b'),
    };

    for (final entry in patterns.entries) {
      if (entry.value.hasMatch(lower)) return entry.key;
    }
    return null;
  }

  static String resolveUnit(String inputUnit, String title) {
    if (inputUnit.trim().isNotEmpty) return inputUnit.trim();
    return _inferUnitFromTitle(title) ?? 'RM';
  }

  /// Personalized coaching text based on progress, deadline, and pace required
  String getPersonalizedFeedback() {
    if (targetValue <= 0) {
      return 'Set a valid target amount to start tracking this goal.';
    }

    final percent = progressPercent;
    final remaining = (targetValue - currentValue).clamp(0.0, targetValue);

    if (progressFraction >= 1.0) {
      return 'Goal accomplished! You have reached 100% of your target.';
    }

    if (deadline == null) {
      return 'You are $percent% there! '
          '${_formatQuantity(remaining)} left to reach your target.';
    }

    final today = _dateOnly(DateTime.now());
    final due = _dateOnly(deadline!);
    final daysLeft = due.difference(today).inDays;

    if (daysLeft < 0) {
      return 'Deadline passed. You are $percent% there with '
          '${_formatQuantity(remaining)} still to go.';
    }

    if (daysLeft == 0) {
      return 'Due today! You need ${_formatQuantity(remaining)} more '
          'to complete this goal.';
    }

    final dailyRequired = remaining / daysLeft;
    final deadlineLabel = _formatShortDate(due);

    if (daysLeft >= 7) {
      final weeklyRequired = dailyRequired * 7;
      return 'You are $percent% there! You need '
          '${_formatPace(weeklyRequired)}/week to hit your target by $deadlineLabel.';
    }

    return 'You are $percent% there! You need '
        '${_formatPace(dailyRequired)}/day to hit your target by $deadlineLabel.';
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatValue(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  String _formatQuantity(double amount) =>
      '${_formatValue(amount)} $displayUnit';

  String _formatPace(double amount) => '${_formatValue(amount)} $displayUnit';

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

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
      unit: _parseUnit(map['unit'], map['title'] as String? ?? ''),
    );
  }

  static String _parseUnit(dynamic rawUnit, String title) {
    final value = rawUnit as String?;
    if (value != null && value.trim().isNotEmpty) return value.trim();
    return _inferUnitFromTitle(title) ?? 'RM';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'unit': unit,
    };
  }

  GoalModel copyWith({
    String? id,
    String? title,
    double? targetValue,
    double? currentValue,
    DateTime? deadline,
    String? unit,
    bool clearDeadline = false,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, targetValue, currentValue, deadline, unit];
}
