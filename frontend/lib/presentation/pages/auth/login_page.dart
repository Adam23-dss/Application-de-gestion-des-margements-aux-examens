import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/pages/dashboard/dashboard_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill for testing
    _emailController.text = 'admin@univ.fr';
    _passwordController.text = 'password123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      print('🔄 Starting login process...');

      final authProvider = context.read<AuthProvider>();

      try {
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Vérifier si le widget est toujours monté
        if (!mounted) return;

        if (authProvider.user != null) {
          print('✅ Login successful! Navigating to dashboard...');
          print('👤 User role: ${authProvider.user!.role}');
          print('👤 User name: ${authProvider.user!.fullName}');

          // Navigate based on role
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (route) => false,
          );
        } else if (authProvider.error != null) {
          print('❌ Login failed: ${authProvider.error}');
          // Show error dialog with details
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Login Failed'),
              content: Text(authProvider.error!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('❌ Exception in login process: $e');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Login Error'),
              content: Text('An error occurred: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(20),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Title
                    Column(
                      children: [
                        Icon(Icons.school, size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Attendance System',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'University Attendance Monitoring',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _login(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    // Error Message
                    if (authProvider.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Test Credentials
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Text(
                      'Test Credentials:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildCredentialChip(
                          'Admin: admin@univ.fr / password123',
                          onTap: () {
                            _emailController.text = 'admin@univ.fr';
                            _passwordController.text = 'password123';
                          },
                        ),
                        _buildCredentialChip(
                          'Surveillant: surveillant@univ.fr / password123',
                          onTap: () {
                            _emailController.text = 'surveillant@univ.fr';
                            _passwordController.text = 'password123';
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialChip(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1), // Fond semi-transparent
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color:
                AppColors.primary, // Texte en couleur primaire sur fond clair
          ),
        ),
      ),
    );
  }
}
