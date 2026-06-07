import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';

/// GoalService — Firestore CRUD for users/{uid}/goals
class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be logged in to manage goals');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _goalsCollection =>
      _userDoc.collection('goals');

  Future<void> _ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to manage goals');
    }

    final snapshot = await _userDoc.get();
    if (snapshot.exists) return;

    await _userDoc.set({
      'name': user.displayName ?? 'User',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'preferences': <String, dynamic>{},
    });
  }

  Never _rethrowFirestoreError(Object e, String action) {
    if (e is FirebaseException) {
      throw Exception('Failed to $action: ${e.message ?? e.code}');
    }
    throw Exception('Failed to $action: ${e.toString()}');
  }

  /// Create a new goal
  Future<String> addGoal(GoalModel goal) async {
    try {
      await _ensureUserDocument();
      final docRef = await _goalsCollection.add(goal.toMap());
      return docRef.id;
    } catch (e) {
      _rethrowFirestoreError(e, 'add goal');
    }
  }

  /// Add to currentValue, capped at targetValue
  Future<void> updateGoalProgress(String goalId, double amountToAdd) async {
    try {
      final doc = await _goalsCollection.doc(goalId).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Goal not found');
      }

      final goal = GoalModel.fromMap(doc.data()!, doc.id);
      final updatedValue = (goal.currentValue + amountToAdd).clamp(
        0.0,
        goal.targetValue > 0 ? goal.targetValue : double.infinity,
      );

      await _goalsCollection.doc(goalId).update({
        'currentValue': updatedValue,
      });
    } catch (e) {
      _rethrowFirestoreError(e, 'update goal progress');
    }
  }

  /// Delete a goal by ID
  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalsCollection.doc(goalId).delete();
    } catch (e) {
      _rethrowFirestoreError(e, 'delete goal');
    }
  }

  /// Real-time stream of all goals, sorted by nearest deadline first
  Stream<List<GoalModel>> getGoals() {
    return _goalsCollection.snapshots().map((snapshot) {
      final goals = snapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();

      goals.sort((a, b) {
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });

      return goals;
    }).handleError((e) {
      throw Exception('Failed to fetch goals: ${e.toString()}');
    });
  }
}
