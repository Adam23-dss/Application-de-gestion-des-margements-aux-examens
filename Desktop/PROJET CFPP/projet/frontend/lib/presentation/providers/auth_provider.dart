import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl repo;

  AuthProvider({required this.repo});

  bool _loading = false;
  String? _error;
  bool _isAuthenticated = false;

  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await repo.login(email: email, password: password);
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await repo.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}