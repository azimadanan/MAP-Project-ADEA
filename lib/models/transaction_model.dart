import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// TransactionModel — Represents an income or expense transaction
/// Stored in Firestore at users/{uid}/transactions/{id}
class TransactionModel extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String category;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  /// Create from Firestore document snapshot
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Other',
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type,
      'category': category,
    };
  }

  /// Create a copy with updated fields
  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? type,
    String? category,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [id, title, amount, date, type, category];
}
