import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend1/data/models/exam_registration_model.dart';
import 'package:frontend1/presentation/providers/exam_registration_provider.dart';
import 'package:frontend1/presentation/providers/export_provider.dart';
import 'package:frontend1/presentation/providers/room_provider.dart';
import 'package:frontend1/presentation/providers/user_provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Ajoute cette importation
import 'package:frontend1/presentation/pages/attendance/scan_page.dart';
import 'package:frontend1/presentation/pages/auth/login_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/pages/admin/admin_dashboard.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/student_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/providers/dashboard_provider.dart';
import 'package:frontend1/presentation/providers/course_provider.dart';
import 'package:frontend1/core/themes/app_theme.dart';

void main() async {
  // Assure que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialise les données de localisation pour le formatage des dates
  await initializeDateFormatting('fr_FR', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => ExportProvider()),
        ChangeNotifierProvider(create: (_) => ExamRegistrationProvider()),
      ],
      child: MaterialApp(
        title: 'Système de Gestion des Émargements',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr', 'FR'), // Définit le locale français
        home: const InitializationWrapper(),
      ),
    );
  }
}

class InitializationWrapper extends StatefulWidget {
  const InitializationWrapper({super.key});

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Utilise un délai pour éviter les problèmes de contexte
    await Future.delayed(Duration.zero);
    await Provider.of<AuthProvider>(context, listen: false).initialize();
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return const AuthWrapper();
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Utiliser un ValueListenableBuilder pour écouter les changements
        return ValueListenableBuilder<bool>(
          valueListenable: ValueNotifier<bool>(authProvider.isAuthenticated),
          builder: (context, isAuthenticated, child) {
            print('🔄 AuthWrapper - isAuthenticated: $isAuthenticated');
            print('🔄 AuthWrapper - user role: ${authProvider.user?.role}');
            
            // Si authentifié, rediriger selon le rôle
            if (isAuthenticated) {
              if (authProvider.user?.isAdmin == true) {
                print('🎯 Redirecting to Admin Dashboard');
                return const AdminDashboard();
              } else {
                print('🎯 Redirecting to Scan Page');
                return const ScanPage();
              }
            }
            
            // Sinon, afficher la page de login
            print('🔐 User not authenticated, showing Login Page');
            return const LoginPage();
          },
        );
      },
    );
  }
}