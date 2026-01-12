import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/domain/usecases/login_usecase.dart';
import 'package:frontend1/data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true; // Commencer avec true
  String? _error;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  final LoginUseCase _loginUseCase;
  
  AuthProvider() : _loginUseCase = LoginUseCase(AuthRepository()) {
    // Ne pas appeler loadStoredUser ici
  }
  
  // Méthode d'initialisation séparée
  Future<void> initialize() async {
    await loadStoredUser();
  }
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _user = await _loginUseCase.execute(
        email: email,
        password: password,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _user = null;
      print('Login error in provider: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    final repository = AuthRepository();
    await repository.logout();
    _user = null;
    notifyListeners();
  }
  
  Future<void> loadStoredUser() async {
    _isLoading = true;
    
    try {
      final repository = AuthRepository();
      _user = await repository.getStoredUser();
    } catch (e) {
      print('Error loading stored user: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}