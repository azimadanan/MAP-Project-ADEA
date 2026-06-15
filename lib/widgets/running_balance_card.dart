import 'package:flutter/material.dart';
import '../services/finance_service.dart';

class RunningBalanceCard extends StatelessWidget {
  final Stream<RunningBalanceSummary> balanceStream;
  final void Function(double currentBaseBalance) onEditBaseBalance;
  final Color primaryContainer;

  const RunningBalanceCard({
    super.key,
    required this.balanceStream,
    required this.onEditBaseBalance,
    this.primaryContainer = const Color(0xFF185FA5),
  });

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return 'RM $whole.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RunningBalanceSummary>(
      stream: balanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Could not load balance: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final summary = snapshot.data ??
            const RunningBalanceSummary(
              baseBalance: 0,
              totalIncome: 0,
              totalExpenses: 0,
            );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(summary.runningBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onEditBaseBalance(summary.baseBalance),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Edit base balance',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Base ${_formatCurrency(summary.baseBalance)} · '
                'Income ${_formatCurrency(summary.totalIncome)} · '
                'Expenses ${_formatCurrency(summary.totalExpenses)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
