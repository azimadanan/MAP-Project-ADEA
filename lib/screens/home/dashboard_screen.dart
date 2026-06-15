import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/transaction_model.dart';
import '../../services/finance_service.dart';
import '../../services/task_service.dart';
import '../../widgets/running_balance_card.dart';
import '../finance/finance_screen.dart';
import '../tasks/tasks_screen.dart';

/// DashboardScreen — Home tab dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceService _financeService = FinanceService();
  final TaskService _taskService = TaskService();
  late Stream<List<TaskModel>> _tasksStream;
  late Stream<List<TransactionModel>> _transactionsStream;
  final _baseBalanceController = TextEditingController();
  String? username;
  String? _highlightedTaskId;
  String? _highlightedTransactionId;

  @override
  void initState() {
    super.initState();
    _tasksStream = _taskService.getTasks();
    _transactionsStream = _financeService.getTransactions();
  }

  @override
  void dispose() {
    _baseBalanceController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Due ${months[dueDate.month - 1]} ${dueDate.day}, ${dueDate.year}';
  }

  void _showEditBaseBalanceDialog(double currentBaseBalance) {
    _baseBalanceController.text = currentBaseBalance.toStringAsFixed(2);
    var isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> saveBaseBalance() async {
            final value = double.tryParse(_baseBalanceController.text.trim());
            if (value == null) {
              _showSnackBar(
                'Please enter a valid amount',
                backgroundColor: Colors.red.shade700,
              );
              return;
            }

            setDialogState(() => isSaving = true);

            try {
              await _financeService.updateBaseBalance(value);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              _showSnackBar('Base balance updated');
            } catch (e) {
              if (!mounted) return;
              _showSnackBar(
                e.toString().replaceFirst('Exception: ', ''),
                backgroundColor: Colors.red.shade700,
              );
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isSaving = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Edit Base Balance'),
            content: TextField(
              controller: _baseBalanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'New balance (RM)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              enabled: !isSaving,
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : saveBaseBalance,
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onTaskTap(TaskModel task) {
    if (_highlightedTaskId == task.id) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TasksScreen()),
      );
    } else {
      setState(() {
        _highlightedTaskId = task.id;
        _highlightedTransactionId = null;
      });
    }
  }

  void _onTransactionTap(TransactionModel transaction) {
    if (_highlightedTransactionId == transaction.id) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FinanceScreen()),
      );
    } else {
      setState(() {
        _highlightedTransactionId = transaction.id;
        _highlightedTaskId = null;
      });
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
    final primary = const Color(0xFF004782);
    final greetingText =
        username != null ? 'Good morning, $username' : 'Good morning! 🌟';

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFFfcf8ff),
        elevation: 4,
        titleSpacing: 20,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFe2e0fc),
              child: Icon(Icons.person, color: Color(0xFF004782)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: subtextColor),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RunningBalanceCard(
              balanceStream: _financeService.watchRunningBalance(),
              onEditBaseBalance: _showEditBaseBalanceDialog,
              primaryContainer: primaryContainer,
            ),
            const SizedBox(height: 24),
            Text(
              'Upcoming Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<TaskModel>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: primaryContainer),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Could not load tasks',
                    style: TextStyle(color: subtextColor),
                  );
                }

                final upcoming = (snapshot.data ?? [])
                    .where((task) => !task.isCompleted)
                    .take(5)
                    .toList();

                if (upcoming.isEmpty) {
                  return Text(
                    'No upcoming tasks',
                    style: TextStyle(color: subtextColor),
                  );
                }

                return Column(
                  children: upcoming.map((task) {
                    final isHighlighted = _highlightedTaskId == task.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _onTaskTap(task),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.all(isHighlighted ? 18 : 16),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? const Color(0xFFe2e0fc)
                                : cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHighlighted
                                  ? primary
                                  : Colors.transparent,
                              width: isHighlighted ? 2 : 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isHighlighted ? 0.08 : 0.05,
                                ),
                                blurRadius: isHighlighted ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          transform: Matrix4.identity()
                            ..scale(isHighlighted ? 1.02 : 1.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFe8e5ff),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.checklist_rounded,
                                  color: primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDueDate(task.dueDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isHighlighted)
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: primary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<TransactionModel>>(
              stream: _transactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: primaryContainer),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Could not load transactions',
                    style: TextStyle(color: subtextColor),
                  );
                }

                final recent = (snapshot.data ?? []).take(3).toList();

                if (recent.isEmpty) {
                  return Text(
                    'No recent transactions',
                    style: TextStyle(color: subtextColor),
                  );
                }

                return Column(
                  children: recent.map((transaction) {
                    final isHighlighted =
                        _highlightedTransactionId == transaction.id;
                    final isIncome = transaction.type == 'income';
                    final amountSign = isIncome ? '+' : '-';
                    final amountColor =
                        isIncome ? const Color(0xFF137333) : textColor;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _onTransactionTap(transaction),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.all(isHighlighted ? 18 : 16),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? const Color(0xFFe2e0fc)
                                : cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHighlighted
                                  ? primary
                                  : Colors.transparent,
                              width: isHighlighted ? 2 : 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isHighlighted ? 0.08 : 0.05,
                                ),
                                blurRadius: isHighlighted ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          transform: Matrix4.identity()
                            ..scale(isHighlighted ? 1.02 : 1.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isIncome
                                      ? const Color(0xFFE6F4EA)
                                      : const Color(0xFFFFEFE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: isIncome
                                      ? const Color(0xFF137333)
                                      : Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      transaction.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$amountSign RM ${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: amountColor,
                                ),
                              ),
                              if (isHighlighted) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: primary,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
