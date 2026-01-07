import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController(text: "surveillant@univ.fr");
  final _passCtrl = TextEditingController(text: "password123");

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Récupère le provider AVANT l'async
    final authProvider = context.read<AuthProvider>();

    // Stocke les inputs avant l'async
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    try {
      // Appel async
      await authProvider.login(email, password);

      // Vérifie que le widget est encore monté
      if (!mounted) return;

      // Si authentifié, navigue vers dashboard
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed("/dashboard");
      }
    } catch (e) {
      // Affiche l'erreur via le provider
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observe le provider pour rebuild quand l'état change
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Affiche l'erreur du provider
            if (auth.error != null)
              Text(
                auth.error!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _handleLogin,
                child: auth.loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Se connecter"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
