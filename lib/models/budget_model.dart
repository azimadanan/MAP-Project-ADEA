import 'package:equatable/equatable.dart';

/// BudgetModel — Monthly spending limit per category
/// Stored in Firestore at users/{uid}/budgets/{id}
class BudgetModel extends Equatable {
  final String id;
  final String category;
  final double limitAmount;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      category: map['category'] as String? ?? 'Other',
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limitAmount': limitAmount,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? limitAmount,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }

  @override
  List<Object?> get props => [id, category, limitAmount];
}
