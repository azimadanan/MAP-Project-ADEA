/testing some features
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

