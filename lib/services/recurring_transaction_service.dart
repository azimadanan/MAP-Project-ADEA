import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';

/// RecurringTransactionService — Handles CRUD for recurring transactions
/// and auto-generates real transactions when they are due.
///
/// Recurring transactions are stored in users/{uid}/recurringTransactions
class RecurringTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be logged in to manage recurring transactions');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// Get reference to user's recurring transactions collection
  CollectionReference<Map<String, dynamic>> get _recurringCollection =>
      _userDoc.collection('recurringTransactions');

  /// Get reference to user's transactions collection (for generating real transactions)
  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _userDoc.collection('transactions');

  /// Ensures the parent user document exists before writing subcollections
  Future<void> _ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to manage recurring transactions');
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

  /// Add a new recurring transaction
  Future<String> addRecurringTransaction(RecurringTransactionModel recurring) async {
    try {
      await _ensureUserDocument();
      final docRef = await _recurringCollection.add(recurring.toMap());
      return docRef.id;
    } catch (e) {
      _rethrowFirestoreError(e, 'add recurring transaction');
    }
  }

  /// Update an existing recurring transaction
  Future<void> updateRecurringTransaction(RecurringTransactionModel recurring) async {
    try {
      await _ensureUserDocument();
      await _recurringCollection.doc(recurring.id).update(recurring.toMap());
    } catch (e) {
      _rethrowFirestoreError(e, 'update recurring transaction');
    }
  }

  /// Delete a recurring transaction by ID
  Future<void> deleteRecurringTransaction(String id) async {
    try {
      await _recurringCollection.doc(id).delete();
    } catch (e) {
      _rethrowFirestoreError(e, 'delete recurring transaction');
    }
  }

  /// Toggle active/inactive status of a recurring transaction
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _recurringCollection.doc(id).update({'isActive': isActive});
    } catch (e) {
      _rethrowFirestoreError(e, 'toggle recurring transaction');
    }
  }

  /// Get real-time stream of all recurring transactions
  Stream<List<RecurringTransactionModel>> getRecurringTransactions() {
    return _recurringCollection
        .orderBy('nextDueDate', descending: false)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => RecurringTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      throw Exception('Failed to fetch recurring transactions: ${e.toString()}');
    });
  }

  /// Process all due recurring transactions:
  /// 1. Find active recurring transactions where nextDueDate <= today
  /// 2. Create a real transaction for each
  /// 3. Advance the nextDueDate to the next cycle
  ///
  /// Returns the number of transactions generated.
  Future<int> processDueTransactions() async {
    try {
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _recurringCollection
          .where('isActive', isEqualTo: true)
          .get();

      int generatedCount = 0;

      for (final doc in snapshot.docs) {
        final recurring = RecurringTransactionModel.fromMap(doc.data(), doc.id);

        // Check if the next due date is today or in the past
        if (recurring.nextDueDate.isBefore(todayEnd) ||
            recurring.nextDueDate.isAtSameMomentAs(todayEnd)) {
          // Generate a real transaction from the recurring template
          final transaction = TransactionModel(
            id: '',
            title: '${recurring.title} (Recurring)',
            amount: recurring.amount,
            date: recurring.nextDueDate,
            type: recurring.type,
            category: recurring.category,
          );

          await _transactionsCollection.add(transaction.toMap());

          // Advance the next due date
          final nextDate = recurring.calculateNextDueDate();
          await _recurringCollection.doc(doc.id).update({
            'nextDueDate': Timestamp.fromDate(nextDate),
          });

          generatedCount++;
        }
      }

      return generatedCount;
    } catch (e) {
      _rethrowFirestoreError(e, 'process due transactions');
    }
  }
}
