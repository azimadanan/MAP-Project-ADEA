import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../finance/finance_screen.dart';
import '../tasks/tasks_screen.dart';
import '../goals/goals_screen.dart';
import '../profile/profile_screen.dart';

/// HomeScreen — Bottom navigation shell with 5 tabs
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeDashboard(),
    FinanceScreen(),
    TasksScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ]; 

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomNavColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final unselectedIconColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, -1))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', isDark, unselectedIconColor),
                _navItem(1, Icons.payments_outlined, Icons.payments_rounded, 'Finance', isDark, unselectedIconColor),
                _navItem(2, Icons.checklist_outlined, Icons.checklist_rounded, 'Tasks', isDark, unselectedIconColor),
                _navItem(3, Icons.workspace_premium_outlined, Icons.workspace_premium_rounded, 'Goals', isDark, unselectedIconColor),
                _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', isDark, unselectedIconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, bool isDark, Color unselectedColor) { // Separate method for nav item to keep build() clean.
    final isSelected = _currentIndex == index;
    final secondaryContainer = isDark ? const Color(0xFF958dff) : const Color(0xFFe3dfff);
    final onSecondaryContainer = isDark ? const Color(0xFF2b1c8f) : const Color(0xFF140067);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque, // what makes the icons easier to tap by allowing taps in the padding area
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? onSecondaryContainer : unselectedColor, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? onSecondaryContainer : unselectedColor, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// SECTION 01 

/// Rich home dashboard tab content matching Stitch Design
class _HomeDashboard extends StatelessWidget { // This is just a static mockup to get the design right before adding real data and interactivity.
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) { // Define all the colors at the top of build() to keep the widget tree cleaner and ensure consistent theming throughout the screen.
    final isDark = Theme.of(context).brightness == Brightness.dark; // Where is brightness.dark defined? It's a property of the ThemeData class in Flutter. 
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
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFfcf8ff),
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
                Text('Good morning 🌤 PUNK', style: TextStyle(fontSize: 13, color: subtextColor, fontWeight: FontWeight.w400)),
                Text('AllInOne', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: primary)),
              ],
            ),
          ],
        ),cd
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: subtextColor),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ), // AppBar with profile avatar and greeting text, matching the design. The notification icon is just a placeholder for now.

      body: SingleChildScrollView( // Wraps the content so it can be scrolled if it overflows.
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 4),
                  const Text('RM 12,450.00', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.arrow_downward_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  const Text('Income', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('RM 4,200', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.arrow_upward_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  const Text('Expense', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('RM 1,850', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bento Stats
            Row(
              children: [
                Expanded(child: _bentoStat(Icons.checklist_rounded, primary, '5/8', 'Tasks', cardColor, textColor, subtextColor)),
                const SizedBox(width: 12),
                Expanded(child: _bentoStat(Icons.workspace_premium_rounded, const Color(0xFF584fbc), '2', 'Goals', cardColor, textColor, subtextColor)),
                const SizedBox(width: 12),
                Expanded(child: _bentoStat(Icons.pie_chart_rounded, const Color(0xFF386a0d), '65%', 'Budget', cardColor, textColor, subtextColor)),
              ],
            ),
            const SizedBox(height: 20),

            // Budget Progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                      Text('Details', style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Spent RM 1,850', style: TextStyle(fontSize: 12, color: subtextColor)),
                      Text('Left RM 1,150', style: TextStyle(fontSize: 12, color: subtextColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 1850 / 3000,
                      minHeight: 8,
                      backgroundColor: Color(0xFFefecff),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004782)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

  // SECTION 02

            // Upcoming Tasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                Text('See All', style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            _taskItem(Icons.menu_book_rounded, const Color(0xFFe8e5ff), primary, 'Read 3 chapters', 'Today, 8:00 PM', false, cardColor, textColor, subtextColor, outlineColor, primary),
            const SizedBox(height: 12),
            _taskItem(Icons.fitness_center_rounded, const Color(0xFFe3dfff), const Color(0xFF584fbc), 'Gym Session', 'Tomorrow, 7:00 AM', false, cardColor, textColor, subtextColor, outlineColor, primary),
            const SizedBox(height: 12),
            _taskItem(Icons.local_florist_rounded, const Color(0xFFb8f389), const Color(0xFF386a0d), 'Water Plants', 'Done', true, cardColor, textColor, subtextColor, outlineColor, primary),
            const SizedBox(height: 24),

            // Recent Transactions
            Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
              child: Column(
                children: [
                  _transactionItem('Lunch at Cafe', 'Food & Dining', '-RM 24.50', Icons.restaurant_rounded, textColor, subtextColor),
                  Divider(color: outlineColor.withOpacity(0.3), height: 32),
                  _transactionItem('Grab Ride', 'Transport', '-RM 15.00', Icons.directions_car_rounded, textColor, subtextColor),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // End of home dashboard build method.

  Widget _bentoStat(IconData icon, Color iconColor, String value, String label, Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      height: 96,
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          Text(label, style: TextStyle(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _taskItem(IconData icon, Color iconBg, Color iconColor, String title, String subtitle, bool isDone, Color cardColor, Color textColor, Color subtextColor, Color outlineColor, Color primary) {
    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor, decoration: isDone ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subtextColor)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isDone ? primary : Colors.transparent,
                border: Border.all(color: isDone ? primary : outlineColor, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionItem(String title, String category, String amount, IconData icon, Color textColor, Color subtextColor) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFFe2e0fc), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF424751), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
              const SizedBox(height: 2),
              Text(category, style: TextStyle(fontSize: 12, color: subtextColor)),
            ],
          ),
        ),
        Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }
}
