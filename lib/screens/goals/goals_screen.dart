import 'package:flutter/material.dart';

/// Goals Screen — Placeholder for Sprint 1
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(0xFFE6F1FB), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.flag_rounded, size: 40, color: Color(0xFF185FA5)),
              ),
              const SizedBox(height: 20),
              const Text('Goals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              const Text('Coming Soon', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }
}
