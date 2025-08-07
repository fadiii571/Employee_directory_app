import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_projectry_app/screens/splash.dart';
import 'package:student_projectry_app/Services/section_shift_service.dart';
import 'firebase_options.dart';

/// Main entry point of the Student Project Management App
///
/// This app manages:
/// - Employee attendance tracking with QR codes
/// - Section-specific shift configurations
/// - KPI calculations and reporting
/// - Payroll management with 30-day fixed cycles
/// - PDF report generation
void main() async {
  await _initializeApp();
  runApp(const StudentProjectApp());
}

/// Initialize Firebase and core services
/// This ensures all necessary services are ready before the app starts
Future<void> _initializeApp() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize section shift service to load configurations
  // This populates the cache with shift settings for KPI calculations
  await SectionShiftService.initialize();
}

/// Root widget of the Student Project Management App
class StudentProjectApp extends StatelessWidget {
  const StudentProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Project Management',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const Splashh(),
    );
  }

  /// Build consistent app theme
  ThemeData _buildAppTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}


