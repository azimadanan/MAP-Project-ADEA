import 'package:flutter/material.dart';

/// SplashScreen — Initial loading screen displayed during app initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf8ff),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon or Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF185FA5).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.work,
                size: 60,
                color: Color(0xFF185FA5),
              ),
            ),
            const SizedBox(height: 32),
            // App Name
            const Text(
              'AllInOne',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF185FA5),
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF185FA5)),
            ),
          ],
        ),
      ),
    );
  }
}
