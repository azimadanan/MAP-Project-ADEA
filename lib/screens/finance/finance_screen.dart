import 'package:flutter/material.dart';

/// Finance Screen — Finance management UI matching Stitch Design
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

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
            // Month Selector
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

            // Big Summary Card
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
                  // Mini Bar Chart
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

            // Spending by Category
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Spending by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                      Text('See All', style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _categoryItem('Food & Dining', 'RM 850', Icons.restaurant_rounded, const Color(0xFFFF6B00), const Color(0xFFFFEFE5), 0.65, textColor),
                  const SizedBox(height: 12),
                  _categoryItem('Transport', 'RM 320', Icons.directions_car_rounded, const Color(0xFF137333), const Color(0xFFE6F4EA), 0.4, textColor),
                  const SizedBox(height: 12),
                  _categoryItem('Shopping', 'RM 450', Icons.shopping_bag_rounded, const Color(0xFFC5221F), const Color(0xFFFCE8E6), 0.5, textColor),
                  const SizedBox(height: 12),
                  _categoryItem('Housing', 'RM 1200', Icons.home_rounded, const Color(0xFF5F6368), const Color(0xFFE8EAED), 0.85, textColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                      Icon(Icons.filter_list_rounded, color: outlineColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _transactionItem('Jaya Grocer', 'Today, 2:30 PM', '-RM 142.50', Icons.storefront_rounded, textColor, subtextColor, textColor),
                  Divider(color: outlineColor.withOpacity(0.2), height: 24),
                  _transactionItem('Salary Transfer', 'Yesterday, 9:00 AM', '+RM 5,200.00', Icons.payments_rounded, const Color(0xFF137333), subtextColor, const Color(0xFF137333), iconBg: const Color(0xFFE6F4EA)),
                  Divider(color: outlineColor.withOpacity(0.2), height: 24),
                  _transactionItem('Starbucks', 'Oct 24, 10:15 AM', '-RM 18.00', Icons.local_cafe_rounded, textColor, subtextColor, textColor),
                  Divider(color: outlineColor.withOpacity(0.2), height: 24),
                  _transactionItem('Grab Ride', 'Oct 23, 6:45 PM', '-RM 24.50', Icons.directions_car_rounded, textColor, subtextColor, textColor),
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
        onPressed: () {},
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

  Widget _categoryItem(String title, String amount, IconData icon, Color color, Color bg, double progress, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                    Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFe2e0fc).withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionItem(String title, String subtitle, String amount, IconData icon, Color titleColor, Color subColor, Color amountColor, {Color? iconBg}) {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: iconBg ?? const Color(0xFFefecff), shape: BoxShape.circle),
          child: Icon(icon, color: iconBg == null ? const Color(0xFF424751) : amountColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
            ],
          ),
        ),
        Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: amountColor)),
      ],
    );
  }
}
