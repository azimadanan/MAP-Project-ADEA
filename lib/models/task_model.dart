import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// TaskModel — Daily task stored in Firestore at users/{uid}/tasks/{id}
class TaskModel extends Equatable {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? reminderDateTime;

  const TaskModel({
    required this.id,
    required this.title,
    required this.isCompleted,
    this.dueDate,
    this.reminderDateTime,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parsedDueDate;
    final rawDueDate = map['dueDate'];
    if (rawDueDate is Timestamp) {
      parsedDueDate = rawDueDate.toDate();
    } else if (rawDueDate != null) {
      parsedDueDate = DateTime.tryParse(rawDueDate.toString());
    }

    DateTime? parsedReminderDateTime;
    final rawReminder = map['reminderDateTime'];
    if (rawReminder is Timestamp) {
      parsedReminderDateTime = rawReminder.toDate();
    } else if (rawReminder != null) {
      parsedReminderDateTime = DateTime.tryParse(rawReminder.toString());
    }

    return TaskModel(
      id: id,
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      dueDate: parsedDueDate,
      reminderDateTime: parsedReminderDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'reminderDateTime': reminderDateTime != null ? Timestamp.fromDate(reminderDateTime!) : null,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? reminderDateTime,
    bool clearDueDate = false,
    bool clearReminderDateTime = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderDateTime: clearReminderDateTime ? null : (reminderDateTime ?? this.reminderDateTime),
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted, dueDate, reminderDateTime];
}
