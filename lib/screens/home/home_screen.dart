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
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Finance'),
                _navItem(2, Icons.check_box_outlined, Icons.check_box_rounded, 'Tasks'),
                _navItem(3, Icons.flag_outlined, Icons.flag_rounded, 'Goals'),
                _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F1FB) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? const Color(0xFF185FA5) : const Color(0xFF9CA3AF), size: 26),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Color(0xFF185FA5), fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}

/// Simple home dashboard tab content
class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) { greeting = 'Good morning'; }
    else if (hour < 17) { greeting = 'Good afternoon'; }
    else { greeting = 'Good evening'; }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
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
                      Text('Welcome, $name!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    ])),
                    Container(width: 52, height: 52,
                      decoration: const BoxDecoration(color: Color(0xFF185FA5), shape: BoxShape.circle),
                      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                  ]),
                  const SizedBox(height: 32),

                  // Quick overview cards
                  Row(children: [
                    Expanded(child: _card(Icons.account_balance_wallet_rounded, 'Finance', 'Track expenses', const Color(0xFF185FA5))),
                    const SizedBox(width: 12),
                    Expanded(child: _card(Icons.check_box_rounded, 'Tasks', 'Manage todos', const Color(0xFF3B6D11))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _card(Icons.flag_rounded, 'Goals', 'Set targets', const Color(0xFF854F0B))),
                    const SizedBox(width: 12),
                    Expanded(child: _card(Icons.person_rounded, 'Profile', 'Your account', const Color(0xFF0C447C))),
                  ]),

                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF185FA5), Color(0xFF0C447C)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('AllInOne', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Your personal management hub.\nFinance, tasks, and goals — all in one place.', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.4)),
                    ]),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
      ]),
    );
  }
}
