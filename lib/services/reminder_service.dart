import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';
import 'notification_service.dart';

/// ReminderService — Handles Firestore CRUD for users/{uid}/reminders
/// and integrates with NotificationService to schedule local OS notifications.
class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be logged in to manage reminders');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _remindersCollection =>
      _userDoc.collection('reminders');

  Future<void> _ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to manage reminders');
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

  /// Add a new reminder
  Future<String> addReminder(ReminderModel reminder) async {
    try {
      await _ensureUserDocument();
      final docRef = await _remindersCollection.add(reminder.toMap());
      final createdReminder = reminder.copyWith(id: docRef.id);
      
      // Schedule local OS notification
      await NotificationService.instance.scheduleCustomReminder(createdReminder);
      
      return docRef.id;
    } catch (e) {
      _rethrowFirestoreError(e, 'add reminder');
    }
  }

  /// Update an existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _ensureUserDocument();
      await _remindersCollection.doc(reminder.id).update(reminder.toMap());

      if (reminder.isActive) {
        await NotificationService.instance.scheduleCustomReminder(reminder);
      } else {
        await NotificationService.instance.cancelCustomReminder(reminder);
      }
    } catch (e) {
      _rethrowFirestoreError(e, 'update reminder');
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(ReminderModel reminder) async {
    try {
      await _remindersCollection.doc(reminder.id).delete();
      await NotificationService.instance.cancelCustomReminder(reminder);
    } catch (e) {
      _rethrowFirestoreError(e, 'delete reminder');
    }
  }

  /// Toggle active state of a reminder
  Future<void> toggleActive(ReminderModel reminder, bool isActive) async {
    try {
      final updated = reminder.copyWith(isActive: isActive);
      await _remindersCollection.doc(reminder.id).update({'isActive': isActive});

      if (isActive) {
        await NotificationService.instance.scheduleCustomReminder(updated);
      } else {
        await NotificationService.instance.cancelCustomReminder(updated);
      }
    } catch (e) {
      _rethrowFirestoreError(e, 'toggle reminder active status');
    }
  }

  /// Real-time stream of all reminders, sorted chronologically (soonest first)
  Stream<List<ReminderModel>> getReminders() {
    return _remindersCollection
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      throw Exception('Failed to fetch reminders: ${e.toString()}');
    });
  }

  /// Get the single most urgent upcoming reminder
  Stream<ReminderModel?> getMostUrgentReminder() {
    final now = Timestamp.fromDate(DateTime.now());
    return _remindersCollection
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime', descending: false)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return ReminderModel.fromMap(doc.data(), doc.id);
    });
  }
}
