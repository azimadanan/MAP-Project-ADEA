import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

/// TaskService — Firestore CRUD for users/{uid}/tasks
class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be logged in to manage tasks');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _userDoc.collection('tasks');

  Future<void> _ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to manage tasks');
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

  /// Add a new task to Firestore
  Future<String> addTask(TaskModel task) async {
    try {
      await _ensureUserDocument();
      final docRef = await _tasksCollection.add(task.toMap());
      return docRef.id;
    } catch (e) {
      _rethrowFirestoreError(e, 'add task');
    }
  }

  /// Toggle a task's completion status
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _tasksCollection.doc(taskId).update({'isCompleted': isCompleted});
    } catch (e) {
      _rethrowFirestoreError(e, 'toggle task completion');
    }
  }

  /// Delete a task by ID
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      _rethrowFirestoreError(e, 'delete task');
    }
  }

  /// Real-time stream of all tasks, sorted: incomplete first, then by due date
  Stream<List<TaskModel>> getTasks() {
    return _tasksCollection.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();

      tasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      return tasks;
    }).handleError((e) {
      throw Exception('Failed to fetch tasks: ${e.toString()}');
    });
  }
}
