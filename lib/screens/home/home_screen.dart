import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../finance/finance_screen.dart';
import '../tasks/tasks_screen.dart';
import '../goals/goals_screen.dart';
import '../profile/profile_screen.dart';

/// HomeScreen — Bottom navigation shell with 5 tabs
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); 
  @override // @override: can detect if you misspell method names (i.e. cretstat()) and throws an error.
  State<HomeScreen> createState() => _HomeScreenState(); // HomeScreen is the widget class, _HomeScreenState is the state class. State class holds the variables that change like _currentIndex.
}

class _HomeScreenState extends State<HomeScreen> { //assigns the state (_HomeScreenState) to the HomeScreen config widget.
  int _currentIndex = 0; // For tracking the tabs, 0 is 1st tab, 1 is 2nd tab, etc.

  final List<Widget> _screens = const [ // A list that can only hold UI widgets. const make the values unchangeable.
    const DashboardScreen(),
    FinanceScreen(), // Each of these screens will be defined in their own files under lib/screens/ and imported at the top.
    TasksScreen(), // So, all the pages are given their indexes (0 - 4) and when we tap on the bottom nav, 
    GoalsScreen(), // it will update _currentIndex and show the corresponding screen from this list.
    ProfileScreen(),
  ]; 

  @override // @override: adjusting the default build() method.
  Widget build(BuildContext context) { // Widget build: a function that must return a widget (piece of UI). Widget is the return type.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomNavColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final unselectedIconColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);

    return Scaffold( // Scaffold is a structural framework. It does the heavy lifting of positioning major pieces like appBar(top), body(middle), and bottomNavigationBar(bottom).
      body: IndexedStack(index: _currentIndex, children: _screens), // This is how they change pages. _screens [LINE 17] is the list of all the pages, and _currentIndex is the index of the page to show. IndexedStack keeps all the pages ALIVE but only shows the one at _currentIndex.
      bottomNavigationBar: Container( // Standard Format for custom bottom nav. We use Container to add padding and background color, and then put the Row of nav items inside it.
        decoration: BoxDecoration( // To decorate the Container (Invisible by default) with background color and shadow.
          color: bottomNavColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, -1))],
        ),
        child: SafeArea( // To avoid the widgets from being blocked by the system's UI like the home indicator.
          child: Padding( // Auto padding. We could also use SizedBox(height: 16) for vertical spacing, but Padding is more flexible for both horizontal and vertical.
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // similar to CSS flexbox justify-content.
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

// SECTION 1 

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, bool isDark, Color unselectedColor) {
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
