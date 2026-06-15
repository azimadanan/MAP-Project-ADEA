import 'package:equatable/equatable.dart'; // This is needed because dart is bad at comparing objects by value. 
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp conversion in fromMap and toMap methods. Timestamp is firebase's proprietary date format.

/// TransactionModel — Represents an income or expense transaction
/// Stored in Firestore at users/{uid}/transactions/{id}
class TransactionModel extends Equatable { // Final is necessary for immutability.
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String category;

  const TransactionModel({ // Just a constructor.
    required this.id,     // 1. It's important to use curly braces for named parameters. 
    required this.title,  //    If not, the order of parameters would matter when creating an instance, which can lead to confusion and errors. 
    required this.amount, //    With named parameters, you can specify the values in any order, improving readability and reducing the chance of mistakes.
    required this.date,
    required this.type,   // 2. In dart, named parameters are optional by default.
    required this.category, //  required: makes them mandatory for obvious reasons.
  });

  /// Create from Firestore document snapshot                             // Factory constructor is used when you want to return an instance of the class, but you might not always want to create a new instance. It allows you to return an existing instance or a new one based on some condition. In this case, it's used to convert Firestore data into a TransactionModel instance.
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) { // This is like the "Translator" (Firebase format to Dart object format). In firestore, the ID is the document ID and not a field - that's why it's separate.
    return TransactionModel(                                              // Map<String, dynamic>. Map: A data structure, String: Keys are strings, dynamic: Values can be any type.
      id: id,
      title: map['title'] as String? ?? '', // ?? => Null-Coalescing operator. If the left is null, return the right.
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0, // kind of a safety net for devs. Firebase might store numbers as int or double, so we first cast to num (parent class of int/double), then convert to double.
      date: map['date'] is Timestamp                                              // 1. Firestore stores dates as Timestamps, Flutter as DateTime.
          ? (map['date'] as Timestamp).toDate()                                   // This is just a ternary operator in 3 lines (Condition ? If True : If False).
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(), 
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Other',
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return { // id is not included as it's the document ID in Firestore.
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date), /// Flutter's inbuilt tool to convert DateTime to Firebases' Timestamp.
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
