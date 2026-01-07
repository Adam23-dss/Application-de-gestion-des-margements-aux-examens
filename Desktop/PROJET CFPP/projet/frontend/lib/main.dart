import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'data/api/dio_client.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  final dioClient = DioClient(storage: storage);
  final authRepo = AuthRepositoryImpl(
    client: dioClient,
    storage: storage,
  );

  runApp(MyApp(authRepo: authRepo));
}

class MyApp extends StatelessWidget {
  final AuthRepositoryImpl authRepo;

  const MyApp({
    super.key,
    required this.authRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repo: authRepo),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: "/login",
        routes: {
          "/login": (_) => const LoginPage(),
          "/dashboard": (_) => const DashboardPage(),
        },
      ),
    );
  }
}
