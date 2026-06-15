import 'package:flutter/material.dart';
import '../../models/reminder_model.dart';
import '../../services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService();

  // Helper to get time categorization label
  String _getDateGroupLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = reminderDate.difference(today).inDays;

    if (difference < 0) {
      return 'Passed';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference <= 7) {
      return 'This Week';
    } else {
      return 'Upcoming';
    }
  }

  // ─── Add/Edit Reminder Sheet ───────────────────────────────────────
  void _showAddEditSheet({ReminderModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime selectedDateTime = existing?.dateTime ?? DateTime.now().add(const Duration(minutes: 30));
    bool isUrgent = existing?.isUrgent ?? false;
    var isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

          Future<void> pickDateTime() async {
            final datePicked = await showDatePicker(
              context: context,
              initialDate: selectedDateTime,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (datePicked == null) return;

            if (!context.mounted) return;
            final timePicked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
            );
            if (timePicked == null) return;

            setSheetState(() {
              selectedDateTime = DateTime(
                datePicked.year, datePicked.month, datePicked.day,
                timePicked.hour, timePicked.minute,
              );
            });
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);
            try {
              if (existing == null) {
                await _reminderService.addReminder(ReminderModel(
                  id: '',
                  title: titleController.text.trim(),
                  dateTime: selectedDateTime,
                  isUrgent: isUrgent,
                  isActive: true,
                ));
              } else {
                await _reminderService.updateReminder(existing.copyWith(
                  title: titleController.text.trim(),
                  dateTime: selectedDateTime,
                  isUrgent: isUrgent,
                ));
              }
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            } catch (e) {
              setSheetState(() => isSaving = false);
              if (sheetCtx.mounted) {
                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                  SnackBar(content: Text('Failed to save reminder: $e')),
                );
              }
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Add Reminder' : 'Edit Reminder',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Reminder Title',
                      hintText: 'e.g. Feed the cat',
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.alarm_rounded, color: Color(0xFFFBBC05)),
                    title: Text(
                      'Date & Time: ${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: pickDateTime,
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Mark as Urgent (Yellow Alert)'),
                    value: isUrgent,
                    onChanged: (v) => setSheetState(() => isUrgent = v ?? false),
                    activeColor: const Color(0xFFFBBC05),
                    checkColor: Colors.black,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving ? null : save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBC05),
                      foregroundColor: Colors.black,
                    ),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Delete Confirmation ───────────────────────────────────────────
  void _confirmDelete(ReminderModel reminder) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _reminderService.deleteReminder(reminder);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? const Color(0xFFC2C6D2) : const Color(0xFF424751);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: const Color(0xFFFBBC05),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<ReminderModel>>(
        stream: _reminderService.getReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFBBC05)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load reminders: ${snapshot.error}',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_paused_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders set',
                    style: TextStyle(fontSize: 16, color: subtextColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add your first reminder.',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                ],
              ),
            );
          }

          // Build feed dynamically
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final groupLabel = _getDateGroupLabel(reminder.dateTime);
              
              // Group dividers (only show for the first item in each date group)
              final showHeader = index == 0 ||
                  _getDateGroupLabel(reminders[index - 1].dateTime) != groupLabel;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Chip(
                        label: Text(
                          groupLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        backgroundColor: _getChipColor(groupLabel, isDark),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                  _buildReminderCard(reminder, cardColor, textColor, subtextColor),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _getChipColor(String group, bool isDark) {
    switch (group) {
      case 'Passed':
        return isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50;
      case 'Today':
        return const Color(0xFFFBBC05).withOpacity(0.25);
      case 'Tomorrow':
        return Colors.blue.withOpacity(isDark ? 0.15 : 0.08);
      default:
        return isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE5E7EB);
    }
  }

  Widget _buildReminderCard(
    ReminderModel reminder,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isUrgent = reminder.isUrgent;
    
    // Urgent styling uses Google Yellow fill with dark text
    final bg = isUrgent ? const Color(0xFFFBBC05) : cardColor;
    final titleColor = isUrgent ? Colors.black : textColor;
    final timeColor = isUrgent ? Colors.black.withOpacity(0.8) : subtextColor;

    final timeString = '${reminder.dateTime.hour.toString().padLeft(2, '0')}:${reminder.dateTime.minute.toString().padLeft(2, '0')} — ${reminder.dateTime.day}/${reminder.dateTime.month}/${reminder.dateTime.year}';

    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        try {
          await _reminderService.deleteReminder(reminder);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
          }
        }
      },
      child: Card(
        color: bg,
        elevation: isUrgent ? 4 : 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isUrgent ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.12)),
        ),
        child: InkWell(
          onTap: () => _showAddEditSheet(existing: reminder),
          onLongPress: () => _confirmDelete(reminder),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Active Switch
                Switch(
                  value: reminder.isActive,
                  onChanged: (v) => _reminderService.toggleActive(reminder, v),
                  activeTrackColor: isUrgent ? Colors.black.withOpacity(0.2) : null,
                  activeColor: isUrgent ? Colors.black : const Color(0xFFFBBC05),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          decoration: reminder.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.alarm_rounded, size: 12, color: timeColor),
                          const SizedBox(width: 4),
                          Text(
                            timeString,
                            style: TextStyle(fontSize: 12, color: timeColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUrgent)
                  const Tooltip(
                    message: 'Urgent Alert',
                    child: Icon(Icons.warning_rounded, color: Colors.black, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
