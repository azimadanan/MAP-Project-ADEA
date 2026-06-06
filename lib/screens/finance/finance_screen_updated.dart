import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/finance_service.dart';

/// Updated Finance Screen with CRUD operations
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late FinanceService _financeService;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  String _selectedType = 'expense';
  String _selectedCategory = 'Food & Dining';

  final List<String> _categories = [
    'Food & Dining',
    'Transport',
    'Shopping',
    'Housing',
    'Entertainment',
    'Utilities',
    'Other',
  ];

  final List<String> _types = ['income', 'expense'];

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Open bottom sheet for adding/editing transactions
  void _showTransactionForm({TransactionModel? transaction}) {
    if (transaction != null) {
      _titleController.text = transaction.title;
      _amountController.text = transaction.amount.toString();
      _selectedType = transaction.type;
      _selectedCategory = transaction.category;
    } else {
      _titleController.clear();
      _amountController.clear();
      _selectedType = 'expense';
      _selectedCategory = 'Food & Dining';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction == null ? 'Add Transaction' : 'Edit Transaction',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter transaction title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveTransaction(transaction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      transaction == null ? 'Add Transaction' : 'Update Transaction',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (transaction != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _deleteTransaction(transaction.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'Delete Transaction',
                        style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Save new or updated transaction
  void _saveTransaction(TransactionModel? transaction) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final newTransaction = TransactionModel(
        id: transaction?.id ?? '',
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: DateTime.now(),
        type: _selectedType,
        category: _selectedCategory,
      );

      if (transaction == null) {
        await _financeService.addTransaction(newTransaction);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
      } else {
        await _financeService.updateTransaction(newTransaction);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  /// Delete transaction with confirmation
  void _deleteTransaction(String id) async {
    Navigator.pop(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
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

    if (confirm == true) {
      try {
        await _financeService.deleteTransaction(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFf2f3f7);
    final outlineColor = isDark ? const Color(0xFF727782) : const Color(0xFFc2c6d2);
    final primaryContainer = const Color(0xFF185FA5);
    final primary = const Color(0xFF004782);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text('Finance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF185FA5), size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: outlineColor.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.chevron_left_rounded, color: outlineColor),
                  Text('October 2023', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  Icon(Icons.chevron_right_rounded, color: outlineColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryContainer,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          const Text('RM 14,250.00', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_upward_rounded, color: Color(0xFF9dd770), size: 14),
                            const SizedBox(width: 2),
                            const Text('+4.2%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _chartBar('Mon', 0.4, false),
                        _chartBar('Tue', 0.6, false),
                        _chartBar('Wed', 0.3, false),
                        _chartBar('Thu', 0.8, false),
                        _chartBar('Fri', 1.0, true),
                        _chartBar('Sat', 0.5, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transactions List with StreamBuilder
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                      Icon(Icons.filter_list_rounded, color: outlineColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<TransactionModel>>(
                    stream: _financeService.getTransactions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryContainer));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)),
                        );
                      }

                      final transactions = snapshot.data ?? [];

                      if (transactions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No transactions yet. Add one to get started!',
                              style: TextStyle(color: subtextColor),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => Divider(color: outlineColor.withOpacity(0.2), height: 24),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isIncome = transaction.type == 'income';
                          final amountColor = isIncome ? const Color(0xFF137333) : textColor;
                          final amountSign = isIncome ? '+' : '-';
                          final iconColor = isIncome ? const Color(0xFF137333) : Colors.red;
                          final iconBg = isIncome ? const Color(0xFFE6F4EA) : const Color(0xFFFFEFE5);

                          return GestureDetector(
                            onTap: () => _showTransactionForm(transaction: transaction),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: iconColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(transaction.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            transaction.category,
                                            style: TextStyle(fontSize: 12, color: subtextColor),
                                          ),
                                          Text(
                                            '${DateTime.now().difference(transaction.date).inDays}d ago',
                                            style: TextStyle(fontSize: 12, color: subtextColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$amountSign RM ${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: amountColor),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: outlineColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('View All Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: subtextColor)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionForm(),
        backgroundColor: primaryContainer,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _chartBar(String label, double heightRatio, bool isToday) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 40 * heightRatio,
          decoration: BoxDecoration(
            color: isToday ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            boxShadow: isToday ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 8)] : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isToday ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
