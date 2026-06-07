import 'package:flutter/material.dart';
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';

/// Goals Screen — Long-term goal tracking with progress bars
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late GoalService _goalService;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _progressController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _goalService = GoalService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _progressController.dispose();
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

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return 'No deadline';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Due ${months[deadline.month - 1]} ${deadline.day}, ${deadline.year}';
  }

  void _showAddGoalSheet() {
    _titleController.clear();
    _targetController.clear();
    DateTime? selectedDeadline;

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
                      'New Goal',
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
                        hintText: 'e.g. Save for vacation',
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
                    TextFormField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Target Amount',
                        hintText: 'e.g. 200',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter a target';
                        }
                        final target = double.tryParse(value!);
                        if (target == null || target <= 0) {
                          return 'Enter a valid target greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 10),
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDeadline = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        selectedDeadline == null
                            ? 'Set deadline (optional)'
                            : _formatDeadline(selectedDeadline),
                      ),
                    ),
                    if (selectedDeadline != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setSheetState(() => selectedDeadline = null);
                        },
                        child: const Text('Clear deadline'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveGoal(sheetContext, selectedDeadline),
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
                              'Create Goal',
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

  Future<void> _saveGoal(
    BuildContext sheetContext,
    DateTime? deadline,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final goal = GoalModel(
        id: '',
        title: _titleController.text.trim(),
        targetValue: double.parse(_targetController.text.trim()),
        currentValue: 0,
        deadline: deadline,
      );

      await _goalService.addGoal(goal);

      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      if (!mounted) return;
      _showSnackBar('Goal created');
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

  Future<void> _showUpdateProgressDialog(GoalModel goal) async {
    _progressController.clear();

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: _progressController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to add',
            hintText: 'e.g. 10',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(_progressController.text.trim());
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    try {
      await _goalService.updateGoalProgress(goal.id, amount);
      if (!mounted) return;
      _showSnackBar('Progress updated');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  Future<void> _confirmDeleteGoal(GoalModel goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Remove "${goal.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _goalService.deleteGoal(goal.id);
      if (!mounted) return;
      _showSnackBar('Goal deleted');
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
    final subtextColor =
        isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final scaffoldBg =
        isDark ? const Color(0xFF0F0F1A) : const Color(0xFFf2f3f7);
    final primaryContainer = const Color(0xFF185FA5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text(
          'Goals',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<List<GoalModel>>(
        stream: _goalService.getGoals(),
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

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return Center(
              child: Text(
                'No goals yet. Tap + to create one.',
                style: TextStyle(color: subtextColor),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progressText =
                  '${_formatValue(goal.currentValue)} / '
                  '${_formatValue(goal.targetValue)} '
                  '(${goal.progressPercent}%)';

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDeadline(goal.deadline),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${goal.progressPercent}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: primaryContainer,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                            onPressed: () => _confirmDeleteGoal(goal),
                            tooltip: 'Delete goal',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: goal.progressFraction,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFe2e0fc),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goal.progressFraction >= 1.0
                                ? const Color(0xFF137333)
                                : primaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        progressText,
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showUpdateProgressDialog(goal),
                          icon: const Icon(Icons.add_chart_rounded, size: 18),
                          label: const Text('Update Progress'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryContainer,
                            side: BorderSide(color: primaryContainer),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalSheet,
        backgroundColor: primaryContainer,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
