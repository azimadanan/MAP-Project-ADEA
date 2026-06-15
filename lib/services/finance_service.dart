import 'dart:async'; // Needed for future and stream.

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

  double get runningBalance => baseBalance + totalIncome - totalExpenses; // Not a hardcoded variable. This is so when UI asks for runningbalance, it gives the instantenous value.
}

/// Finance Service — Handles all Firestore CRUD operations for transactions
/// Transactions are stored in users/{uid}/transactions collecthion
class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Allows CRUD operations in firebase
  final FirebaseAuth _auth = FirebaseAuth.instance; // Use current connection instead of making a new one

  String get _uid {
    final uid = _auth.currentUser?.uid; // Remember to use ? for safety, otherwise it'll crash if null.
    if (uid == null) {
      throw Exception('You must be logged in to save finance data');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid); // Set uid under _userDoc. Crucial to prevent users overwriting each other.

  /// Get reference to user's transactions collection
  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _userDoc.collection('transactions'); 

  /// Get reference to user's budgets collection
  CollectionReference<Map<String, dynamic>> get _budgetsCollection =>
      _userDoc.collection('budgets');

  /// Ensures the parent user document exists before writing subcollections
  Future<void> _ensureUserDocument() async {
    final user = _auth.currentUser; //Eventhough we already checked at the top
    if (user == null) {              // good backend practice to keep checking everytime.
      throw Exception('You must be logged in to save finance data');
    }

    final snapshot = await _userDoc.get(); // Check if the user already exists.
    if (snapshot.exists) return;  

    await _userDoc.set({ // Set new user's profile.
      'name': user.displayName ?? 'User',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(), // DateTime.now() relies on the user's phone clock (could be altered).
      'preferences': <String, dynamic>{},        // .serverTimeStamp() takes the time this file arrives at Google server.
      'baseBalance': 0.0,
    });
  }

  double _readBaseBalance(Map<String, dynamic>? data) { // Helper function (used below) - it's just a function: [return type] [function name] ([argument type] [parameter]) {Implementation}
    return (data?['baseBalance'] as num?)?.toDouble() ?? 0.0;
  }

  ({double income, double expenses}) _totalsFromSnapshot( // Record (introduced in Dart v3): Can return 2 things at once.
    QuerySnapshot<Map<String, dynamic>> snapshot, //DocumentSnapshot: single file, QuerySnapshot: a folder of files.
  ) {
    double income = 0.0;
    double expenses = 0.0;
                                        // .data() is for DocumentSnapshot - one "paper"
    for (final doc in snapshot.docs) {  // QuerySnapsot is a folder, so you use a for loop to pull out each individual "paper"
      final data = doc.data();          // now data holds a single "paper", we can use .data() to read it.
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      if (data['type'] == 'income') {
        income += amount;
      } else if (data['type'] == 'expense') {
        expenses += amount;
      }
    }

    return (income: income, expenses: expenses); // ':' is a label matcher (used in Records, Maps, and Constructors). 
  }                                              //  Matches the income variable in computer memory to income: in this record package.

  /// Real-time stream of the user's starting balance (defaults to 0)
  Stream<double> getBaseBalance() { // Stream: watches for changes in database and updates immediately. Paired with StreamBuilder in UI.
    return _userDoc.snapshots().map((snapshot) {
      return _readBaseBalance(snapshot.data());
    });
  }

  /// Persist a new base balance on the user document
  Future<void> updateBaseBalance(double newBalance) async {
    try { // Whenever you use await to talk to the internet, you should wrap it in a try / catch block.
      await _ensureUserDocument(); // Because of the await keyword, the code literally pauses here. It will not move to the next line until it guarantees the folder exists.
      await _userDoc.set( // By default, .set() acts like a bulldozer. If you tell it to set the baseBalance, it will completely wipe out the user's entire folder (deleting their name, email, and preferences) and replace it with a folder that only contains a baseBalance.
        {'baseBalance': newBalance}, // To prevent that, we add SetOptions(merge: true). This changes the bulldozer into a surgical scalpel. It tells Firebase: "Open the folder, find the sticky note labeled 'baseBalance', and update just that one number. Leave their name, email, and everything else exactly as it is."
        SetOptions(merge: true), // Crucial
      );
    } catch (e) {
      _rethrowFirestoreError(e, 'update base balance'); // Helper function
    }
  }

  /// Running balance = baseBalance + totalIncome - totalExpenses
  Stream<RunningBalanceSummary> watchRunningBalance() { //RunningBalanceSummary: class defined at the top
    return Stream.multi((controller) { // Stream.multi: for watching multiple things.
      double baseBalance = 0.0;
      QuerySnapshot<Map<String, dynamic>>? transactionsSnapshot;  // transactionsSnapshot is the folder containing every single transaction you have ever made.

      void emitSummary() {
        if (transactionsSnapshot == null) return;

        final totals = _totalsFromSnapshot(transactionsSnapshot!); // "!" is the bang operator. it assures the compiler that the value is not null.
        controller.add( // controller is inbuilt to flutter/dart.
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

  // Never: It 'never' returns because all ends of this function throws an exception. It aborts the program.
  Never _rethrowFirestoreError(Object e, String action) { // Helper function for errors
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Deploy Firestore rules: firebase deploy --only firestore:rules',
        );
      }
      throw Exception('Failed to $action: ${e.message ?? e.code}'); // the ":" is just a colon (it's in quotes).
    }                                                               // Reminder: "$" is for string interpolation. If it is a complex action that requires math or digging into an object, you wrap it in brackets: ${e.message}. This tells Dart, "Wait, before you print this, do the calculation inside the brackets first."
    throw Exception('Failed to $action: ${e.toString()}'); // Every single object in Dart has a .toString() method built into it. It is a universal command that forces the object to translate itself into text as best as it can so you can print it to the screen and figure out what went wrong.
  }

  /// Add a new transaction to Firestore
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      await _ensureUserDocument(); // Double check user id again.
      final docRef = await _transactionsCollection.add(transaction.toMap()); // .toMap(): converts the dart object to a raw dictionary (JSON Format) so firebase can read it.
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
  Future<void> deleteTransaction(String transactionId) async {     // When you want to delete a transaction, you don't care about the title, the amount, or the date. 
    try {                                                          // You literally just want to throw the file in the shredder. Passing the entire TransactionModel would be a waste of memory. 
      await _transactionsCollection.doc(transactionId).delete();   // The UI just hands the Waiter a tiny scrap of paper with the ID written on it (a String), and the Waiter hands that directly to the .doc() command.
    } catch (e) {
      _rethrowFirestoreError(e, 'delete transaction');
    }
  }

  /// Get real-time stream of all transactions ordered by date (descending)
  /// Automatically rebuilds the UI whenever transactions change
  Stream<List<TransactionModel>> getTransactions() { 
    return _transactionsCollection // In case of confusion: This entire block is one sentence, that's why return is at the top.
        .orderBy('date', descending: true)
        .snapshots()
        .map((querySnapshot) { // querySnapshot is an anonymous function.
      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) { // You can't use try / catch in Stream cause it never closes. it's basically the stream version of a try / catch block.
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
        .map((querySnapshot) { // Anonymous function: no function name, just the argument (in parantheses), and body.
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

  /// Auto-categorize a transaction based on its title using keyword matching.
  /// Returns the best-matching category, or 'Other' if no match is found.
  ///
  /// This implements Sprint 1 ID 2 — automatic expense categorization.
  /// Uses a simple keyword-based approach that matches common merchant names
  /// and transaction descriptions to predefined categories.
  static String autoCategorize(String title) {
    final lower = title.toLowerCase().trim();

    // Food & Dining keywords
    const foodKeywords = [
      'mcdonald', 'kfc', 'pizza', 'starbucks', 'grab food', 'grabfood',
      'foodpanda', 'restaurant', 'cafe', 'coffee', 'lunch', 'dinner',
      'breakfast', 'burger', 'sushi', 'nasi', 'makan', 'mamak',
      'subway', 'domino', 'tealive', 'boba', 'bakery', 'groceries',
      'grocery', 'supermarket', 'tesco', 'aeon', 'jaya grocer',
      'mydin', 'village grocer', 'food', 'eat', 'meal',
    ];

    // Transport keywords
    const transportKeywords = [
      'grab', 'uber', 'taxi', 'mrt', 'lrt', 'bus', 'train',
      'petrol', 'fuel', 'shell', 'petronas', 'parking', 'toll',
      'touch n go', 'tng', 'highway', 'transit', 'rapidkl',
      'gas', 'diesel', 'car wash', 'carwash', 'transport',
    ];

    // Shopping keywords
    const shoppingKeywords = [
      'shopee', 'lazada', 'amazon', 'uniqlo', 'h&m', 'zara',
      'nike', 'adidas', 'mr diy', 'ikea', 'daiso', 'watson',
      'guardian', 'sephora', 'shopping', 'mall', 'cloth', 'shoes',
      'bag', 'accessory', 'fashion', 'online shop',
    ];

    // Housing keywords
    const housingKeywords = [
      'rent', 'rental', 'mortgage', 'house', 'apartment', 'condo',
      'maintenance', 'property', 'landlord', 'tenancy', 'housing',
      'room', 'accommodation',
    ];

    // Entertainment keywords
    const entertainmentKeywords = [
      'netflix', 'spotify', 'youtube', 'disney', 'hbo', 'cinema',
      'movie', 'tgv', 'gsc', 'game', 'playstation', 'xbox',
      'steam', 'concert', 'ticket', 'entertainment', 'subscribe',
      'subscription', 'apple music', 'gym', 'fitness',
    ];

    // Utilities keywords
    const utilitiesKeywords = [
      'electric', 'tenaga', 'tnb', 'water', 'wifi', 'internet',
      'phone', 'digi', 'maxis', 'celcom', 'unifi', 'astro',
      'bill', 'utility', 'utilities', 'indah water', 'syabas',
      'telco', 'broadband', 'postpaid', 'prepaid',
    ];

    // Check each category (order matters — more specific first)
    for (final keyword in foodKeywords) {
      if (lower.contains(keyword)) return 'Food & Dining';
    }
    for (final keyword in entertainmentKeywords) {
      if (lower.contains(keyword)) return 'Entertainment';
    }
    for (final keyword in shoppingKeywords) {
      if (lower.contains(keyword)) return 'Shopping';
    }
    for (final keyword in housingKeywords) {
      if (lower.contains(keyword)) return 'Housing';
    }
    for (final keyword in utilitiesKeywords) {
      if (lower.contains(keyword)) return 'Utilities';
    }
    for (final keyword in transportKeywords) {
      if (lower.contains(keyword)) return 'Transport';
    }

    return 'Other';
  }
}
