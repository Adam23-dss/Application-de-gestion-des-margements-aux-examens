import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/pages/admin/admin_dashboard.dart';
import 'package:frontend1/presentation/pages/attendance/scan_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Redirect based on role
    if (user.isAdmin) {
      return const AdminDashboard();
    } else if (user.isSupervisor) {
      return const ScanPage();
    }
    
    // Fallback
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            Text('Welcome ${user.fullName}!'),
            Text('Role: ${user.role}'),
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