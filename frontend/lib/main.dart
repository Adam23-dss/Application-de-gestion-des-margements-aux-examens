import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:attendance_frontend/presentation/providers/auth_provider.dart';
// import 'package:attendance_frontend/core/themes/app_theme.dart';
// import 'package:attendance_frontend/presentation/pages/auth/login_page.dart';

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
        // Ajouter d'autres providers ici
      ],
      child: MaterialApp(
        title: 'Attendance Manager',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const LoginPage(),
      ),
    );
  }
}