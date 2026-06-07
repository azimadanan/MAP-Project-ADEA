import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

/// Live balance snapshot: baseBalance + income - expenses
class RunningBalanceSummary {
  final double baseBalance;
  final double totalIncome;
  final double totalExpenses;

  const RunningBalanceSummary({
    required this.baseBalance,
    required this.totalIncome,
    required this.totalExpenses,
  });

  double get runningBalance => baseBalance + totalIncome - totalExpenses;
}

/// Finance Service — Handles all Firestore CRUD operations for transactions
/// Transactions are stored in users/{uid}/transactions collecthion
class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be logged in to save finance data');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// Get reference to user's transactions collection
  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _userDoc.collection('transactions');

  /// Get reference to user's budgets collection
  CollectionReference<Map<String, dynamic>> get _budgetsCollection =>
      _userDoc.collection('budgets');

  /// Ensures the parent user document exists before writing subcollections
  Future<void> _ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to save finance data');
    }

    final snapshot = await _userDoc.get();
    if (snapshot.exists) return;

    await _userDoc.set({
      'name': user.displayName ?? 'User',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'preferences': <String, dynamic>{},
      'baseBalance': 0.0,
    });
  }

  double _readBaseBalance(Map<String, dynamic>? data) {
    return (data?['baseBalance'] as num?)?.toDouble() ?? 0.0;
  }

  ({double income, double expenses}) _totalsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    double income = 0.0;
    double expenses = 0.0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      if (data['type'] == 'income') {
        income += amount;
      } else if (data['type'] == 'expense') {
        expenses += amount;
      }
    }

    return (income: income, expenses: expenses);
  }

  /// Real-time stream of the user's starting balance (defaults to 0)
  Stream<double> getBaseBalance() {
    return _userDoc.snapshots().map((snapshot) {
      return _readBaseBalance(snapshot.data());
    });
  }

  /// Persist a new base balance on the user document
  Future<void> updateBaseBalance(double newBalance) async {
    try {
      await _ensureUserDocument();
      await _userDoc.set(
        {'baseBalance': newBalance},
        SetOptions(merge: true),
      );
    } catch (e) {
      _rethrowFirestoreError(e, 'update base balance');
    }
  }

  /// Running balance = baseBalance + totalIncome - totalExpenses
  Stream<RunningBalanceSummary> watchRunningBalance() {
    return Stream.multi((controller) {
      double baseBalance = 0.0;
      QuerySnapshot<Map<String, dynamic>>? transactionsSnapshot;

      void emitSummary() {
        if (transactionsSnapshot == null) return;

        final totals = _totalsFromSnapshot(transactionsSnapshot!);
        controller.add(
          RunningBalanceSummary(
            baseBalance: baseBalance,
            totalIncome: totals.income,
            totalExpenses: totals.expenses,
          ),
        );
      }

      final userSubscription = _userDoc.snapshots().listen(
        (snapshot) {
          baseBalance = _readBaseBalance(snapshot.data());
          emitSummary();
        },
        onError: controller.addError,
      );

      final transactionsSubscription = _transactionsCollection.snapshots().listen(
        (snapshot) {
          transactionsSnapshot = snapshot;
          emitSummary();
        },
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await userSubscription.cancel();
        await transactionsSubscription.cancel();
      };
    });
  }

  Never _rethrowFirestoreError(Object e, String action) {
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Deploy Firestore rules: firebase deploy --only firestore:rules',
        );
      }
      throw Exception('Failed to $action: ${e.message ?? e.code}');
    }
    throw Exception('Failed to $action: ${e.toString()}');
  }

  /// Add a new transaction to Firestore
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      await _ensureUserDocument();
      final docRef = await _transactionsCollection.add(transaction.toMap());
      return docRef.id;
    } catch (e) {
      _rethrowFirestoreError(e, 'add transaction');
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _ensureUserDocument();
      await _transactionsCollection.doc(transaction.id).update(transaction.toMap());
    } catch (e) {
      _rethrowFirestoreError(e, 'update transaction');
    }
  }

  /// Delete a transaction by ID
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactionsCollection.doc(transactionId).delete();
    } catch (e) {
      _rethrowFirestoreError(e, 'delete transaction');
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

  /// Set or update a monthly budget limit for a category
  Future<void> setBudgetLimit(BudgetModel budget) async {
    try {
      await _ensureUserDocument();
      final existing = await _budgetsCollection
          .where('category', isEqualTo: budget.category)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await _budgetsCollection
            .doc(existing.docs.first.id)
            .update(budget.toMap());
      } else if (budget.id.isNotEmpty) {
        await _budgetsCollection.doc(budget.id).set(budget.toMap());
      } else {
        await _budgetsCollection.add(budget.toMap());
      }
    } catch (e) {
      _rethrowFirestoreError(e, 'set budget limit');
    }
  }

  /// Real-time stream of all budget limits
  Stream<List<BudgetModel>> getBudgets() {
    return _budgetsCollection.snapshots().map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      throw Exception('Failed to fetch budgets: ${e.toString()}');
    });
  }

  /// Get the budget limit for a specific category, if one exists
  Future<BudgetModel?> getBudgetForCategory(String category) async {
    try {
      final querySnapshot = await _budgetsCollection
          .where('category', isEqualTo: category)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return BudgetModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Failed to fetch budget for $category: ${e.toString()}');
    }
  }

  /// Sum all expense transactions for a category within the given month
  Future<double> calculateCategorySpend(String category, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month);
      final startOfNextMonth = DateTime(month.year, month.month + 1);

      final querySnapshot = await _transactionsCollection
          .where('type', isEqualTo: 'expense')
          .where('category', isEqualTo: category)
          .get();

      double total = 0.0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final date = data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : DateTime.tryParse(data['date']?.toString() ?? '');
        if (date == null) continue;
        if (!date.isBefore(startOfMonth) && date.isBefore(startOfNextMonth)) {
          total += ((data['amount'] as num?)?.toDouble() ?? 0.0);
        }
      }
      return total;
    } catch (e) {
      throw Exception(
        'Failed to calculate spend for $category: ${e.toString()}',
      );
    }
  }
}
