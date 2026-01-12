import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/providers/student_provider.dart';
import 'package:frontend1/presentation/pages/auth/login_page.dart';
import 'package:frontend1/presentation/pages/dashboard/dashboard_page.dart';
import 'package:frontend1/presentation/pages/attendance/scan_page.dart';
import 'package:frontend1/presentation/pages/attendance/manual_validation_page.dart';
import 'package:frontend1/core/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: MaterialApp(
        title: 'Attendance System',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/scan': (context) => const ScanPage(),
          '/manual-validation': (context) => const ManualValidationPage(examId: 0),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (authProvider.user == null) {
      return const LoginPage();
    }
    
    // Redirection selon le rôle
    if (authProvider.user!.isAdmin) {
      return const DashboardPage();
    } else {
      return const ScanPage();
    }
  }
}