import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// UserModel — App user data stored in Firestore users/{uid}
class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? avatar;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.avatar,
    this.preferences = const {},
  });

  /// Create from Firestore document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      avatar: map['avatar'] as String?,
      preferences:
          Map<String, dynamic>.from(map['preferences'] as Map? ?? {}),
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'avatar': avatar,
      'preferences': preferences,
    };
  }

  /// Get initials for avatar display
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
      avatar: avatar ?? this.avatar,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [uid, name, email, createdAt, avatar, preferences];
}
