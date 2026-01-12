import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  final AuthRepository _repository = AuthRepository();
  
  Future<void> initialize() async {
    print('🔄 Initializing auth provider...');
    await loadStoredUser();
  }
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    print('🔐 Attempting login with email: $email');
    
    try {
      _user = await _repository.login(
        email: email,
        password: password,
      );
      _error = null;
      print('✅ Login successful: ${_user!.fullName}');
    } catch (e) {
      _error = e.toString();
      _user = null;
      print('❌ Login error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _user = null;
      notifyListeners();
    }
  }
  
  Future<void> loadStoredUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await _repository.getStoredUser();
      print(_user != null 
          ? '✅ Loaded stored user: ${_user!.fullName}' 
          : '❌ No stored user found');
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