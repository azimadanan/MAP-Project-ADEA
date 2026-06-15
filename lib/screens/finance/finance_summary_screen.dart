import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction_model.dart';
import '../../services/finance_service.dart';

/// FinanceSummaryScreen — Graphical analytics of monthly/yearly incomes & expenses
class FinanceSummaryScreen extends StatefulWidget {
  const FinanceSummaryScreen({super.key});

  @override
  State<FinanceSummaryScreen> createState() => _FinanceSummaryScreenState();
}

class _FinanceSummaryScreenState extends State<FinanceSummaryScreen> {
  final FinanceService _financeService = FinanceService();
  DateTime _selectedDate = DateTime.now();
  bool _isYearly = false; // Toggle between monthly and yearly summaries
  int _touchedIndex = -1;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return const Color(0xFFFF9F43);
      case 'Transport':
        return const Color(0xFF00D2FC);
      case 'Shopping':
        return const Color(0xFFE84118);
      case 'Entertainment':
        return const Color(0xFF9C27B0);
      case 'Bills & Utilities':
      case 'Utilities':
        return const Color(0xFF4CD137);
      case 'Housing':
        return const Color(0xFF5A4FCF);
      case 'Other':
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  void _previousPeriod() {
    setState(() {
      if (_isYearly) {
        _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month);
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_isYearly) {
        _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month);
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFf2f3f7);
    final outlineColor = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFe2e4e8);
    final primary = const Color(0xFF185FA5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        title: Text(
          'Financial Analytics',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _financeService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF185FA5)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading analytics: ${snapshot.error}',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final allTransactions = snapshot.data ?? [];

          // 1. Filter transactions for the selected period (current month or year)
          final filteredTransactions = allTransactions.where((t) {
            if (_isYearly) {
              return t.date.year == _selectedDate.year;
            } else {
              return t.date.year == _selectedDate.year &&
                  t.date.month == _selectedDate.month;
            }
          }).toList();

          // 2. Filter transactions for the comparison period (previous month or year)
          final comparisonTransactions = allTransactions.where((t) {
            if (_isYearly) {
              return t.date.year == _selectedDate.year - 1;
            } else {
              final prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
              return t.date.year == prevDate.year && t.date.month == prevDate.month;
            }
          }).toList();

          // Calculate current totals
          double totalIncome = 0.0;
          double totalExpense = 0.0;
          final Map<String, double> categorySpending = {};

          for (final t in filteredTransactions) {
            if (t.type == 'income') {
              totalIncome += t.amount;
            } else if (t.type == 'expense') {
              totalExpense += t.amount;
              categorySpending[t.category] =
                  (categorySpending[t.category] ?? 0.0) + t.amount;
            }
          }

          // Calculate comparison totals
          double prevIncome = 0.0;
          double prevExpense = 0.0;
          for (final t in comparisonTransactions) {
            if (t.type == 'income') {
              prevIncome += t.amount;
            } else if (t.type == 'expense') {
              prevExpense += t.amount;
            }
          }

          final netBalance = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle between Monthly and Yearly
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: outlineColor),
                    ),
                    child: ToggleButtons(
                      isSelected: [!_isYearly, _isYearly],
                      onPressed: (index) {
                        setState(() {
                          _isYearly = index == 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      selectedColor: Colors.white,
                      fillColor: primary,
                      color: textColor,
                      constraints: const BoxConstraints(
                        minWidth: 100,
                        minHeight: 36,
                      ),
                      children: const [
                        Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Yearly', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                // Period Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: outlineColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded, color: primary),
                        onPressed: _previousPeriod,
                      ),
                      Text(
                        _isYearly
                            ? '${_selectedDate.year}'
                            : '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded, color: primary),
                        onPressed: _nextPeriod,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Cashflow Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Income',
                        amount: totalIncome,
                        color: const Color(0xFF2E7D32),
                        cardColor: cardColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Expenses',
                        amount: totalExpense,
                        color: const Color(0xFFC62828),
                        cardColor: cardColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  title: 'Net Balance',
                  amount: netBalance,
                  color: netBalance >= 0 ? const Color(0xFF185FA5) : const Color(0xFFBA1A1A),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  icon: Icons.account_balance_wallet_rounded,
                  isFullWidth: true,
                ),
                const SizedBox(height: 24),

                if (filteredTransactions.isEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Column(
                        children: [
                          Icon(Icons.query_stats_rounded, size: 64, color: subtextColor.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions recorded for this period.',
                            style: TextStyle(color: subtextColor, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                ] else ...[
                  // Expense breakdown pie chart
                  if (totalExpense > 0) ...[
                    Text(
                      'Expense Breakdown',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                                sections: _buildPieSections(categorySpending, totalExpense),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: categorySpending.keys.map((cat) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(cat),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Cashflow trend comparison
                  Text(
                    _isYearly ? 'Year-Over-Year Cashflow' : 'Month-Over-Month Cashflow',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      const style = TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      );
                                      if (value.toInt() == 0) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(_isYearly ? 'Prev Year' : 'Prev Month', style: style),
                                        );
                                      } else if (value.toInt() == 1) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            _isYearly
                                                ? '${_selectedDate.year}'
                                                : _months[_selectedDate.month - 1].substring(0, 3),
                                            style: style.copyWith(color: primary),
                                          ),
                                        );
                                      }
                                      return Container();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: prevIncome,
                                      color: const Color(0xFF81C784),
                                      width: 14,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    BarChartRodData(
                                      toY: prevExpense,
                                      color: const Color(0xFFE57373),
                                      width: 14,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: totalIncome,
                                      color: const Color(0xFF2E7D32),
                                      width: 16,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    BarChartRodData(
                                      toY: totalExpense,
                                      color: const Color(0xFFC62828),
                                      width: 16,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBarLegend('Income', const Color(0xFF2E7D32), subtextColor),
                            const SizedBox(width: 24),
                            _buildBarLegend('Expense', const Color(0xFFC62828), subtextColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown Table list
                  Text(
                    'Category Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: categorySpending.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: outlineColor,
                      ),
                      itemBuilder: (context, index) {
                        final cat = categorySpending.keys.elementAt(index);
                        final amt = categorySpending[cat]!;
                        final pct = totalExpense > 0 ? (amt / totalExpense) * 100 : 0.0;

                        return ListTile(
                          leading: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(cat),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'RM ${amt.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> spending, double total) {
    return spending.entries.map((entry) {
      final index = spending.keys.toList().indexOf(entry.key);
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final value = entry.value;
      final percent = total > 0 ? (value / total) * 100 : 0.0;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: value,
        title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isFullWidth ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarLegend(String label, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
