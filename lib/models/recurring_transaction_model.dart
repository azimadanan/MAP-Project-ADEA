import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// RecurringTransactionModel — Represents an auto-repeating transaction
/// Stored in Firestore at users/{uid}/recurringTransactions/{id}
///
/// When active, the app will automatically generate a real transaction
/// from this template on the next due date.
class RecurringTransactionModel extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime nextDueDate;
  final DateTime createdAt;
  final bool isActive;

  const RecurringTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.frequency,
    required this.nextDueDate,
    required this.createdAt,
    this.isActive = true,
  });

  /// Create from Firestore document snapshot
  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return RecurringTransactionModel(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Other',
      frequency: map['frequency'] as String? ?? 'monthly',
      nextDueDate: map['nextDueDate'] is Timestamp
          ? (map['nextDueDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['nextDueDate']?.toString() ?? '') ?? DateTime.now(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  RecurringTransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    String? frequency,
    DateTime? nextDueDate,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Calculate the next due date after the current one based on frequency
  DateTime calculateNextDueDate() {
    switch (frequency) {
      case 'daily':
        return nextDueDate.add(const Duration(days: 1));
      case 'weekly':
        return nextDueDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case 'yearly':
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
      default:
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
    }
  }

  /// Human-readable frequency label
  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }

  /// Icon data suggestion based on category
  bool get isDueToday {
    final now = DateTime.now();
    return nextDueDate.year == now.year &&
        nextDueDate.month == now.month &&
        nextDueDate.day == now.day;
  }

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.isBefore(today);
  }

  @override
  List<Object?> get props => [id, title, amount, type, category, frequency, nextDueDate, createdAt, isActive];
}
