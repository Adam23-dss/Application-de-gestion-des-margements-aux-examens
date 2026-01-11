import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/pages/admin/admin_dashboard.dart';
import 'package:frontend1/presentation/pages/attendance/scan_page.dart';
import 'package:frontend1/core/constants/user_roles.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}
class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null || !user.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Admin ${user.name}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => authProvider.logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}