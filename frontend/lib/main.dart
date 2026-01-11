import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/core/themes/app_theme.dart';
import 'package:frontend1/presentation/pages/auth/login_page.dart';
import 'package:frontend1/presentation/pages/dashboard/dashboard_page.dart';
import 'package:frontend1/presentation/pages/attendance/scan_page.dart';
=======
import 'package:frontend/presentation/pages/auth/login_page.dart';
import 'package:frontend/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/themes/app_theme.dart'; // ✅ IMPORTANT
>>>>>>> 26af70491dde05fe4bbce1d155db830ea5c2d08b

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => ExamProvider()),
        // ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp(
        title: 'Attendance Manager',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/dashboard': (context) => const DashboardPage(),
         // '/scan': (context) => const ScanPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return authProvider.isAuthenticated
        ? const DashboardPage()
        : const LoginPage();
  }
}