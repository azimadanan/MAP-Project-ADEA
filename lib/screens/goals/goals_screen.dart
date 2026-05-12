import 'package:flutter/material.dart';

/// Goals Screen — Goal tracking UI matching Stitch Design
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

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
        title: Text('Goals', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.5)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryContainer,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Navigation
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFe2e0fc), borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: const Text('Daily', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: Text('Monthly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subtextColor)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: Text('Yearly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subtextColor)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Goal Cards
            _goalCard(
              'Drink Water', 'Health & Wellness', '8 of 10 glasses', 0.8, '80%', 
              Icons.water_drop_rounded, const Color(0xFF185FA5), const Color(0xFFd4e3ff), 
              Icons.trending_up_rounded, 'On track! Keep it up.', 
              cardColor, textColor, subtextColor, outlineColor
            ),
            const SizedBox(height: 16),
            _goalCard(
              'Read 20 Pages', 'Personal Growth', '9 of 20 pages', 0.45, '45%', 
              Icons.menu_book_rounded, const Color(0xFF584fbc), const Color(0xFFe8e5ff), 
              Icons.schedule_rounded, 'Slightly behind schedule.', 
              cardColor, textColor, subtextColor, outlineColor
            ),
            const SizedBox(height: 16),
            _goalCard(
              'Morning Jog', 'Fitness', '0.5 of 5 km', 0.1, '10%', 
              Icons.directions_run_rounded, const Color(0xFFba1a1a), const Color(0xFFffdad6), 
              Icons.warning_rounded, 'Needs attention today!', 
              cardColor, textColor, subtextColor, outlineColor
            ),
            const SizedBox(height: 16),
            _goalCard(
              'Save \$50', 'Finance', 'Done!', 1.0, '100%', 
              Icons.savings_rounded, const Color(0xFF265000), const Color(0xFFb8f389), 
              Icons.check_circle_rounded, 'Goal accomplished.', 
              cardColor, textColor, subtextColor, outlineColor,
              borderColor: const Color(0xFF9dd770).withOpacity(0.3)
            ),
            
            const SizedBox(height: 24),

            // Insights Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFe8e5ff), Color(0xFFe2e0fc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: primaryContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Daily Insight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 8),
                  Text(
                    "You've hit 3 out of 5 goals today! Completing your \"Morning Jog\" will boost your daily streak to 7 days. You're doing great!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subtextColor, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(
    String title, String category, String progressText, double progress, String percentageText,
    IconData icon, Color mainColor, Color bgIconColor,
    IconData statusIcon, String statusText,
    Color cardColor, Color textColor, Color subtextColor, Color outlineColor,
    {Color? borderColor}
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: mainColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 2),
                    Text(category, style: TextStyle(fontSize: 12, color: outlineColor)),
                  ],
                ),
              ),
              Text(percentageText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: mainColor)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFe2e0fc),
              valueColor: AlwaysStoppedAnimation<Color>(mainColor),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(progressText, style: TextStyle(fontSize: 12, color: subtextColor)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: outlineColor.withOpacity(0.3)))),
            child: Row(
              children: [
                Icon(statusIcon, color: mainColor, size: 16),
                const SizedBox(width: 6),
                Text(statusText, style: TextStyle(fontSize: 12, color: subtextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
