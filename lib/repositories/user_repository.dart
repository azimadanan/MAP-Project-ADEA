import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// UserRepository — Firestore read/write for users/{uid} collection
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create a new user profile in Firestore after registration
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  /// Get user profile from Firestore by UID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  /// Update user profile fields (partial update)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  /// Create or update user profile for Google Sign-In
  /// Creates a new document if the user doesn't exist yet
  Future<UserModel> createOrUpdateGoogleUser(User firebaseUser) async {
    final existingUser = await getUser(firebaseUser.uid);

    if (existingUser != null) {
      return existingUser;
    }

    // First-time Google sign-in — create new profile
    final newUser = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
      createdAt: DateTime.now(),
      avatar: firebaseUser.photoURL,
      preferences: {},
    );

    await createUser(newUser);
    return newUser;
  }
}
