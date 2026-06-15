import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ReminderModel — Chronological reminders stored at users/{uid}/reminders/{id}
class ReminderModel extends Equatable {
  final String id;
  final String title;
  final DateTime dateTime;
  final bool isUrgent;
  final bool isActive;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.dateTime,
    this.isUrgent = false,
    this.isActive = true,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDateTime = DateTime.now();
    final rawDateTime = map['dateTime'];
    if (rawDateTime is Timestamp) {
      parsedDateTime = rawDateTime.toDate();
    } else if (rawDateTime != null) {
      parsedDateTime = DateTime.tryParse(rawDateTime.toString()) ?? DateTime.now();
    }

    return ReminderModel(
      id: id,
      title: map['title'] as String? ?? '',
      dateTime: parsedDateTime,
      isUrgent: map['isUrgent'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'isUrgent': isUrgent,
      'isActive': isActive,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    bool? isUrgent,
    bool? isActive,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      isUrgent: isUrgent ?? this.isUrgent,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, title, dateTime, isUrgent, isActive];
}
