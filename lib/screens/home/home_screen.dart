import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../finance/finance_screen.dart';
import '../tasks/tasks_screen.dart';
import '../goals/goals_screen.dart';
import '../reminders/reminders_screen.dart';

/// HomeScreen — Bottom navigation shell with 5 tabs and localized color zones
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  ThemeData _buildZoneTheme(BuildContext context, int index) {
    final baseTheme = Theme.of(context);
    Color zoneColor;

    switch (index) {
      case 1:
        zoneColor = const Color(0xFF4285F4); // Finance (Google Blue)
        break;
      case 2:
        zoneColor = const Color(0xFFEA4335); // Tasks (Google Red)
        break;
      case 3:
        zoneColor = const Color(0xFF34A853); // Goals (Google Green)
        break;
      case 4:
        zoneColor = const Color(0xFFFBBC05); // Reminders (Google Yellow)
        break;
      default:
        zoneColor = const Color(0xFF185FA5); // Home (Brand Blue)
    }

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: zoneColor,
        secondary: zoneColor,
      ),
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: zoneColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: zoneColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: zoneColor,
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: zoneColor, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomNavColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final unselectedIconColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);

    // Dynamic screens mapped inside build to receive the correct context and zone theme overrides
    final List<Widget> themedScreens = [
      Theme(
        data: _buildZoneTheme(context, 0),
        child: DashboardScreen(onTabSwitch: _onTabChanged),
      ),
      Theme(
        data: _buildZoneTheme(context, 1),
        child: const FinanceScreen(),
      ),
      Theme(
        data: _buildZoneTheme(context, 2),
        child: const TasksScreen(),
      ),
      Theme(
        data: _buildZoneTheme(context, 3),
        child: const GoalsScreen(),
      ),
      Theme(
        data: _buildZoneTheme(context, 4),
        child: const RemindersScreen(),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: themedScreens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
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
                _navItem(3, Icons.track_changes_outlined, Icons.track_changes_rounded, 'Goals', isDark, unselectedIconColor),
                _navItem(4, Icons.notifications_none_rounded, Icons.notifications_rounded, 'Reminders', isDark, unselectedIconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, bool isDark, Color unselectedColor) {
    final isSelected = _currentIndex == index;
    Color zoneColor;

    switch (index) {
      case 1:
        zoneColor = const Color(0xFF4285F4); // Finance (Blue)
        break;
      case 2:
        zoneColor = const Color(0xFFEA4335); // Tasks (Red)
        break;
      case 3:
        zoneColor = const Color(0xFF34A853); // Goals (Green)
        break;
      case 4:
        zoneColor = const Color(0xFFFBBC05); // Reminders (Yellow)
        break;
      default:
        zoneColor = const Color(0xFF185FA5); // Home (Blue-grey brand)
    }

    final secondaryContainer = isSelected
        ? (isDark ? zoneColor.withOpacity(0.2) : zoneColor.withOpacity(0.12))
        : Colors.transparent;
        
    final activeColor = isDark 
        ? (index == 4 ? const Color(0xFFFFD60A) : zoneColor.withOpacity(0.95)) 
        : zoneColor;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : unselectedColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
