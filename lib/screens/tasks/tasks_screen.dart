import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import 'task_calendar_screen.dart';

/// Tasks Screen — CRUD task list backed by Firestore
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late TaskService _taskService;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _taskService = TaskService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dueDate.weekday - 1]}, '
        '${months[dueDate.month - 1]} ${dueDate.day}, ${dueDate.year}';
  }

  void _showAddTaskSheet() {
    _titleController.clear();
    DateTime? selectedDueDate;
    TimeOfDay? selectedReminderTime;
    bool hasReminder = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter task title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDueDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        selectedDueDate == null
                            ? 'Set due date (optional)'
                            : 'Due: ${_formatDueDate(selectedDueDate)}',
                      ),
                    ),
                    if (selectedDueDate != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setSheetState(() => selectedDueDate = null);
                        },
                        child: const Text('Clear due date'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Set Reminder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        selectedReminderTime == null
                            ? 'Notify me on the due date'
                            : 'Remind at ${selectedReminderTime!.format(context)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: hasReminder,
                      activeColor: const Color(0xFF185FA5),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) async {
                        setSheetState(() => hasReminder = val);
                        if (val && selectedReminderTime == null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (pickedTime != null) {
                            setSheetState(() => selectedReminderTime = pickedTime);
                          } else {
                            setSheetState(() => hasReminder = false);
                          }
                        }
                      },
                    ),
                    if (hasReminder && selectedReminderTime != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedReminderTime!,
                          );
                          if (pickedTime != null) {
                            setSheetState(() => selectedReminderTime = pickedTime);
                          }
                        },
                        icon: const Icon(Icons.access_time_rounded),
                        label: Text('Change Time (${selectedReminderTime!.format(context)})'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveTask(sheetContext, selectedDueDate, hasReminder ? selectedReminderTime : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF185FA5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Task',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTask(
    BuildContext sheetContext,
    DateTime? dueDate,
    TimeOfDay? reminderTime,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      DateTime? reminderDateTime;
      if (dueDate != null && reminderTime != null) {
        reminderDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          reminderTime.hour,
          reminderTime.minute,
        );
      }

      final task = TaskModel(
        id: '',
        title: _titleController.text.trim(),
        isCompleted: false,
        dueDate: dueDate,
        reminderDateTime: reminderDateTime,
      );

      final taskId = await _taskService.addTask(task);
      final savedTask = task.copyWith(id: taskId);

      if (reminderDateTime != null) {
        await NotificationService.instance.scheduleTaskReminder(savedTask);
      }

      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      if (!mounted) return;
      _showSnackBar('Task added');
      _titleController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleTask(TaskModel task, bool? value) async {
    if (value == null) return;
    try {
      await _taskService.toggleTaskCompletion(task.id, value);

      final updatedTask = task.copyWith(isCompleted: value);
      if (value) {
        await NotificationService.instance.cancelTaskReminder(updatedTask);
      } else {
        if (updatedTask.reminderDateTime != null) {
          await NotificationService.instance.scheduleTaskReminder(updatedTask);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    try {
      await _taskService.deleteTask(task.id);
      await NotificationService.instance.cancelTaskReminder(task);
      if (!mounted) return;
      _showSnackBar('Task deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textVariantColor =
        isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
    final scaffoldBg =
        isDark ? const Color(0xFF0F0F1A) : const Color(0xFFfcf8ff);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final primaryContainer = const Color(0xFF185FA5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_month_rounded, color: primaryContainer, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TaskCalendarScreen()),
                      );
                    },
                    tooltip: 'View Calendar',
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: _taskService.getTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryContainer),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    );
                  }

                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No tasks yet. Tap + to add one.',
                        style: TextStyle(color: textVariantColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];

                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.horizontal,
                        background: _dismissBackground(Alignment.centerLeft),
                        secondaryBackground:
                            _dismissBackground(Alignment.centerRight),
                        onDismissed: (_) => _deleteTask(task),
                        child: Card(
                          color: cardColor,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            value: task.isCompleted,
                            activeColor: primaryContainer,
                            onChanged: (value) => _toggleTask(task, value),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              _formatDueDate(task.dueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: textVariantColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: primaryContainer,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _dismissBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
    );
  }
}
