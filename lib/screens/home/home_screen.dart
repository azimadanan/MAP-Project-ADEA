import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
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
    final unselectedIconColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', isDark, unselectedIconColor),
                _navItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Finance', isDark, unselectedIconColor),
                _navItem(2, Icons.check_box_outlined, Icons.check_box_rounded, 'Tasks', isDark, unselectedIconColor),
                _navItem(3, Icons.flag_outlined, Icons.flag_rounded, 'Goals', isDark, unselectedIconColor),
                _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', isDark, unselectedIconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, bool isDark, Color unselectedColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF185FA5).withOpacity(0.2) : const Color(0xFFE6F1FB)) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? const Color(0xFF185FA5) : unselectedColor, size: 26),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Color(0xFF185FA5), fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}

/// Rich home dashboard tab content
class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) { greeting = 'Good morning'; }
    else if (hour < 17) { greeting = 'Good afternoon'; }
    else { greeting = 'Good evening'; }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF2F3F7);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final name = state is AuthAuthenticated ? state.user.name : 'User';
              final initials = state is AuthAuthenticated ? state.user.initials : 'U';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(greeting, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Welcome, $name!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    ])),
                    Container(width: 52, height: 52,
                      decoration: const BoxDecoration(color: Color(0xFF185FA5), shape: BoxShape.circle),
                      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                  ]),
                  const SizedBox(height: 32),

                  // Big Finance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF185FA5), Color(0xFF0C447C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF185FA5).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      const Text('\$12,450.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Row(children: [
                        _financeStat(Icons.arrow_downward_rounded, 'Income', '\$4,200', const Color(0xFF4CAF50)),
                        const SizedBox(width: 24),
                        _financeStat(Icons.arrow_upward_rounded, 'Expense', '\$1,150', const Color(0xFFF44336)),
                      ])
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // Today's Tasks
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Today\'s Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const Text('See all', style: TextStyle(fontSize: 14, color: Color(0xFF185FA5), fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 16),
                  _taskItem('Pay electricity bill', 'Due Today', true, cardColor, textColor),
                  const SizedBox(height: 12),
                  _taskItem('Submit project proposal', 'Tomorrow', false, cardColor, textColor),
                  const SizedBox(height: 12),
                  _taskItem('Groceries', 'No date', false, cardColor, textColor),
                  
                  const SizedBox(height: 32),

                  // Active Goals
                  Text('Active Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  _goalItem('Save for Vacation', 3000, 5000, Icons.flight_takeoff_rounded, const Color(0xFF854F0B), cardColor, textColor),
                  const SizedBox(height: 12),
                  _goalItem('Emergency Fund', 8000, 10000, Icons.shield_rounded, const Color(0xFF185FA5), cardColor, textColor),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _financeStat(IconData icon, String label, String amount, Color color) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ])
    ]);
  }

  Widget _taskItem(String title, String subtitle, bool isDone, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF185FA5) : Colors.transparent,
            border: Border.all(color: isDone ? const Color(0xFF185FA5) : const Color(0xFF9CA3AF), width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: isDone ? FontWeight.w500 : FontWeight.w600, color: isDone ? const Color(0xFF9CA3AF) : textColor, decoration: isDone ? TextDecoration.lineThrough : null)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ])),
      ]),
    );
  }

  Widget _goalItem(String title, double current, double target, IconData icon, Color color, Color cardColor, Color textColor) {
    final progress = current / target;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 8),
          Text('\$${current.toInt()} / \$${target.toInt()}', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ])),
      ]),
    );
  }
}
