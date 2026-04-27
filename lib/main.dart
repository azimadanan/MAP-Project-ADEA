import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/profile_screen.dart';

// ============================================================
// AllInOne App - Personal Management Mobile Application
// Built by Team ADEA (Section 15) for MAP @ UTM Malaysia
// ============================================================

/// AllInOne Color Theme Constants
class AppColors {
  static const Color primaryBlue = Color(0xFF185FA5);
  static const Color lightBlue = Color(0xFFE6F1FB);
  static const Color darkBlue = Color(0xFF0C447C);
  static const Color background = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color successGreen = Color(0xFF3B6D11);
  static const Color warningAmber = Color(0xFF854F0B);
  static const Color errorRed = Color(0xFFA32D2D);
}

void main() {
  // TODO: Initialize Firebase before running the app
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(const AllInOneApp());
}

/// Root application widget
class AllInOneApp extends StatelessWidget {
  const AllInOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AllInOne',
      debugShowCheckedModeBanner: false,

      // --- App Theme ---
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          error: AppColors.errorRed,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),

      // --- Routes ---
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

/// Main Screen with Bottom Navigation Bar
/// Contains 5 tabs: Home, Finance, Tasks, Goals, Profile
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = const [
    HomeScreen(),
    FinanceScreen(),
    TasksScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to preserve state when switching tabs
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Finance',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.notes_rounded,
                  activeIcon: Icons.notes_rounded,
                  label: 'Tasks',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.star_outline_rounded,
                  activeIcon: Icons.star_rounded,
                  label: 'Goals',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single bottom navigation item with animation
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE6F1FB)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF185FA5) : Colors.grey.shade400,
              size: 26,
            ),
            // Show label only when selected
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF185FA5),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
