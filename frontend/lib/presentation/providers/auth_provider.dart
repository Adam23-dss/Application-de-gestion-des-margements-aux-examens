import 'package:flutter/foundation.dart';
// import 'package:attendance_frontend/data/repositories/auth_repository.dart';
// import 'package:attendance_frontend/data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isSupervisor => _user?.role == 'supervisor';
  
  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _user = await _authRepository.login(email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }
  
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = await _authRepository.getProfile();
      if (user != null) {
        _user = user;
      }
    } catch (e) {
      // Ne pas afficher d'erreur, juste ne pas authentifier
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}