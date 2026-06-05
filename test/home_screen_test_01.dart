import 'package:flutter/material.dart';
import 'package:allinone_app/screens/finance/finance_screen.dart';
import 'package:allinone_app/screens/tasks/tasks_screen.dart';
import 'package:allinone_app/screens/goals/goals_screen.dart';
import 'package:allinone_app/screens/profile/profile_screen.dart';

//HomeScreen - Bottom navigation shell with 5 tabs
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
    ProfilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomNavaColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final unselectedIconColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
  
  return Scaffold(
    body: IndexedStack(index: _currentIndex, children: _screens),
    bottomNavigationBar: Container(
      decoration:BoxDecoration(
        color: bottomNavColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, -1))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          
        )
      )
    )
  )
  }