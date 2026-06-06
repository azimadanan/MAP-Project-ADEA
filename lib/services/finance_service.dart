import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

/// Finance Service — Handles all Firestore CRUD operations for transactions
/// Transactions are stored in users/{uid}/transactions collection
class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get reference to user's transactions collection
  CollectionReference<Map<String, dynamic>> get _transactionsCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  /// Add a new transaction to Firestore
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final docRef = await _transactionsCollection.add(transaction.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add transaction: ${e.toString()}');
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _transactionsCollection.doc(transaction.id).update(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to update transaction: ${e.toString()}');
    }
  }

  /// Delete a transaction by ID
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactionsCollection.doc(transactionId).delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: ${e.toString()}');
    }
  }

  /// Get real-time stream of all transactions ordered by date (descending)
  /// Automatically rebuilds the UI whenever transactions change
  Stream<List<TransactionModel>> getTransactions() {
    return _transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      throw Exception('Failed to fetch transactions: ${e.toString()}');
    });
  }

  /// Get transactions filtered by type (income or expense)
  Stream<List<TransactionModel>> getTransactionsByType(String type) {
    return _transactionsCollection
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      throw Exception('Failed to fetch $type transactions: ${e.toString()}');
    });
  }

  /// Get transactions for a specific category
  Stream<List<TransactionModel>> getTransactionsByCategory(String category) {
    return _transactionsCollection
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      throw Exception('Failed to fetch $category transactions: ${e.toString()}');
    });
  }

  /// Calculate total income
  Future<double> getTotalIncome() async {
    try {
      final querySnapshot = await _transactionsCollection
          .where('type', isEqualTo: 'income')
          .get();
      double total = 0.0;
      for (final doc in querySnapshot.docs) {
        total += ((doc['amount'] as num?)?.toDouble() ?? 0.0);
      }
      return total;
    } catch (e) {
      throw Exception('Failed to calculate income: ${e.toString()}');
    }
  }

  /// Calculate total expenses
  Future<double> getTotalExpenses() async {
    try {
      final querySnapshot = await _transactionsCollection
          .where('type', isEqualTo: 'expense')
          .get();
      double total = 0.0;
      for (final doc in querySnapshot.docs) {
        total += ((doc['amount'] as num?)?.toDouble() ?? 0.0);
      }
      return total;
    } catch (e) {
      throw Exception('Failed to calculate expenses: ${e.toString()}');
    }
  }
}
