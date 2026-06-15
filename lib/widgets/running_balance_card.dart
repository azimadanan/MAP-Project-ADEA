import 'package:flutter/material.dart'; // imports the material library.
import '../services/finance_service.dart'; // imports the finance service. for running balance.

class RunningBalanceCard extends StatelessWidget { // RunningBalanceCard: class defined at the top
  final Stream<RunningBalanceSummary> balanceStream; // Stream: watches for changes in database and updates immediately. Paired with StreamBuilder in UI.
  final void Function(double currentBaseBalance) onEditBaseBalance; // void Function: a function that doesn't return anything.
  final Color primaryContainer; // Color: a color object.

  const RunningBalanceCard({ // RunningBalanceCard: constructor
    super.key, // super.key: the key of the widget.
    required this.balanceStream, // required: the balance stream is required.
    required this.onEditBaseBalance, // required: the on edit base balance function is required.
    this.primaryContainer = const Color(0xFF185FA5),
  });

  // MOREXP
  String _formatCurrency(double amount) { // _formatCurrency: a helper function that formats the currency.
    final formatted = amount.toStringAsFixed(2); // formatted: the formatted amount.
    final parts = formatted.split('.'); // parts: the parts of the amount.
    final whole = parts[0].replaceAllMapped( // whole: the whole part of the amount.
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), // RegExp: a regular expression. The weird symbols are for formatting the currency.
      (match) => '${match[1]},', // match: the match of the regular expression. 
    );
    return 'RM $whole.${parts[1]}'; // return: the formatted amount.
  } // this.primaryContainer: the primary container is the color of the container.

  @override
  Widget build(BuildContext context) { // build: the function that builds the widget. Context is to tell the location of the widget.
    return StreamBuilder<RunningBalanceSummary>( // why is the streambuilder here? because we are watching the balance stream and updating the UI immediately.
      stream: balanceStream, // balanceStream: the balance stream.
      builder: (context, snapshot) { // builder: the function that builds the widget. Context is to tell the location of the widget.
        if (snapshot.connectionState == ConnectionState.waiting) { // if the connection state is waiting, show a loading indicator.
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
