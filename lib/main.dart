import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';

// ============================================================
// AllInOne App - Personal Management Mobile Application
// Built by Team ADEA (Section 15) for MAP @ UTM Malaysia
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.initialize();

  runApp(const AllInOneApp());
}
