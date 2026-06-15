import 'package:flutter/material.dart';
import '../../models/recurring_transaction_model.dart';
import '../../services/recurring_transaction_service.dart';

/// RecurringTransactionsScreen — Manage auto-repeating income and expenses
///
/// Users can create, toggle, and delete recurring transactions such as
/// monthly rent, weekly groceries, salary, subscriptions, etc.
class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  late RecurringTransactionService _recurringService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _recurringService = RecurringTransactionService();
  }

  // ─── Category icon mapping ──────────────────────────────────────────
  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Housing':
        return Icons.home_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Utilities':
        return Icons.bolt_rounded;
      case 'Salary':
        return Icons.account_balance_rounded;
      case 'Freelance':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  // ─── Category color mapping ─────────────────────────────────────────
  Color _categoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return const Color(0xFFFF6B6B);
      case 'Transport':
        return const Color(0xFF4ECDC4);
      case 'Shopping':
        return const Color(0xFFFFBE0B);
      case 'Housing':
        return const Color(0xFF845EC2);
      case 'Entertainment':
        return const Color(0xFFFF9F1C);
      case 'Utilities':
        return const Color(0xFF2EC4B6);
      case 'Salary':
        return const Color(0xFF00B4D8);
      case 'Freelance':
        return const Color(0xFF06D6A0);
      default:
        return const Color(0xFF8D99AE);
    }
  }

  // ─── Process due recurring transactions ─────────────────────────────
  Future<void> _processDueTransactions() async {
    setState(() => _isProcessing = true);
    try {
      final count = await _recurringService.processDueTransactions();
      if (!mounted) return;
      _showSnackBar(
        count > 0
            ? '$count recurring transaction${count > 1 ? 's' : ''} generated!'
            : 'No transactions are due yet.',
        icon: count > 0 ? Icons.check_circle_rounded : Icons.info_rounded,
        color: count > 0 ? const Color(0xFF06D6A0) : const Color(0xFF00B4D8),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error_rounded,
        color: Colors.red.shade700,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, {IconData? icon, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color ?? const Color(0xFF185FA5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Show add/edit recurring transaction sheet ──────────────────────
  void _showAddEditSheet({RecurringTransactionModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();
    String selectedType = existing?.type ?? 'expense';
    String selectedCategory = existing?.category ?? 'Food & Dining';
    String selectedFrequency = existing?.frequency ?? 'monthly';
    DateTime selectedStartDate = existing?.nextDueDate ?? DateTime.now();
    bool isSaving = false;

    final categories = [
      'Food & Dining',
      'Transport',
      'Shopping',
      'Housing',
      'Entertainment',
      'Utilities',
      'Salary',
      'Freelance',
      'Other',
    ];

    final frequencies = ['daily', 'weekly', 'monthly', 'yearly'];
    final frequencyLabels = {
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
    };

    final types = ['income', 'expense'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
          final cardColor = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF5F6FA);

          Future<void> pickStartDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedStartDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (picked != null) {
              setSheetState(() => selectedStartDate = picked);
            }
          }

          Future<void> saveRecurring() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);

            try {
              final model = RecurringTransactionModel(
                id: existing?.id ?? '',
                title: titleController.text.trim(),
                amount: double.parse(amountController.text.trim()),
                type: selectedType,
                category: selectedCategory,
                frequency: selectedFrequency,
                nextDueDate: selectedStartDate,
                createdAt: existing?.createdAt ?? DateTime.now(),
                isActive: existing?.isActive ?? true,
              );

              if (existing == null) {
                await _recurringService.addRecurringTransaction(model);
              } else {
                await _recurringService.updateRecurringTransaction(model);
              }

              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              if (!mounted) return;
              _showSnackBar(
                existing == null
                    ? 'Recurring transaction created!'
                    : 'Recurring transaction updated!',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF06D6A0),
              );
            } catch (e) {
              if (!mounted) return;
              _showSnackBar(
                e.toString().replaceFirst('Exception: ', ''),
                icon: Icons.error_rounded,
                color: Colors.red.shade700,
              );
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() => isSaving = false);
              }
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle bar ──
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Title ──
                    Text(
                      existing == null
                          ? 'New Recurring Transaction'
                          : 'Edit Recurring Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E2C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set up automatic repeating income or expenses',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Title field ──
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Netflix, Rent, Salary',
                        prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Amount field ──
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount (RM)',
                        hintText: 'e.g. 49.90',
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Type + Frequency row ──
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              labelText: 'Type',
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            items: types
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t[0].toUpperCase() + t.substring(1)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setSheetState(() => selectedType = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedFrequency,
                            decoration: InputDecoration(
                              labelText: 'Frequency',
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            items: frequencies
                                .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(frequencyLabels[f]!),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => selectedFrequency = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Category dropdown ──
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(_categoryIcon(c),
                                        size: 18, color: _categoryColor(c)),
                                    const SizedBox(width: 8),
                                    Text(c),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Start date picker ──
                    GestureDetector(
                      onTap: pickStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing == null ? 'Start Date' : 'Next Due Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${selectedStartDate.day}/${selectedStartDate.month}/${selectedStartDate.year}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E1E2C),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveRecurring,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185FA5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                existing == null ? 'Create Recurring' : 'Update',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    // ── Delete button (only for editing) ──
                    if (existing != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Recurring?'),
                                content: const Text(
                                    'This will stop all future auto-generated transactions.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _recurringService
                                  .deleteRecurringTransaction(existing.id);
                              if (!sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                              if (!mounted) return;
                              _showSnackBar(
                                'Recurring transaction deleted',
                                icon: Icons.delete_rounded,
                                color: Colors.red.shade600,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Delete Recurring',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121220) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Recurring Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Process due transactions button
          IconButton(
            onPressed: _isProcessing ? null : _processDueTransactions,
            tooltip: 'Generate Due Transactions',
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: const Color(0xFF185FA5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Recurring', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<RecurringTransactionModel>>(
        stream: _recurringService.getRecurringTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading recurring transactions',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF185FA5).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.repeat_rounded,
                        size: 40,
                        color: Color(0xFF185FA5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Recurring Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up automatic repeating transactions\nlike rent, salary, or subscriptions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Separate into active and inactive
          final active = items.where((i) => i.isActive).toList();
          final inactive = items.where((i) => !i.isActive).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // ── Summary card ──
              _buildSummaryCard(items, isDark, cardColor),
              const SizedBox(height: 20),

              // ── Active section ──
              if (active.isNotEmpty) ...[
                _buildSectionHeader('Active', active.length, isDark),
                const SizedBox(height: 10),
                ...active.map((item) =>
                    _buildRecurringCard(item, isDark, cardColor)),
              ],

              // ── Inactive section ──
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('Paused', inactive.length, isDark),
                const SizedBox(height: 10),
                ...inactive.map((item) =>
                    _buildRecurringCard(item, isDark, cardColor)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── Summary Card ───────────────────────────────────────────────────
  Widget _buildSummaryCard(
      List<RecurringTransactionModel> items, bool isDark, Color cardColor) {
    final activeItems = items.where((i) => i.isActive).toList();
    double monthlyIncome = 0;
    double monthlyExpenses = 0;

    for (final item in activeItems) {
      double monthlyAmount;
      switch (item.frequency) {
        case 'daily':
          monthlyAmount = item.amount * 30;
          break;
        case 'weekly':
          monthlyAmount = item.amount * 4;
          break;
        case 'monthly':
          monthlyAmount = item.amount;
          break;
        case 'yearly':
          monthlyAmount = item.amount / 12;
          break;
        default:
          monthlyAmount = item.amount;
      }
      if (item.type == 'income') {
        monthlyIncome += monthlyAmount;
      } else {
        monthlyExpenses += monthlyAmount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF185FA5), Color(0xFF2E86DE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF185FA5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Recurring Summary',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Income',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${monthlyIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF06D6A0),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expenses',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${monthlyExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Net: RM ${(monthlyIncome - monthlyExpenses).toStringAsFixed(2)}/month',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section header ─────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E1E2C),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF185FA5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF185FA5),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Individual recurring card ──────────────────────────────────────
  Widget _buildRecurringCard(
      RecurringTransactionModel item, bool isDark, Color cardColor) {
    final color = _categoryColor(item.category);
    final isIncome = item.type == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: item.isOverdue && item.isActive
            ? Border.all(color: Colors.red.withOpacity(0.4), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showAddEditSheet(existing: item),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Category icon ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(item.category),
                    color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // ── Title + frequency + next due ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E1E2C),
                        decoration:
                            item.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.frequencyLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.isOverdue && item.isActive
                              ? 'Overdue!'
                              : item.isDueToday && item.isActive
                                  ? 'Due today'
                                  : 'Next: ${item.nextDueDate.day}/${item.nextDueDate.month}/${item.nextDueDate.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: item.isOverdue && item.isActive
                                ? Colors.red
                                : isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                            fontWeight: item.isOverdue && item.isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Amount ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} RM ${item.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isIncome
                          ? const Color(0xFF06D6A0)
                          : const Color(0xFFFF6B6B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Active toggle
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: item.isActive,
                      onChanged: (value) {
                        _recurringService.toggleActive(item.id, value);
                      },
                      activeColor: const Color(0xFF185FA5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
