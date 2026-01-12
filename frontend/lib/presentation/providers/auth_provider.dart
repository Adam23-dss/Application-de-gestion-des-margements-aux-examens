import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend1/core/utils/secure_storage.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/data/repositories/auth_repository.dart';
import 'package:frontend1/presentation/pages/auth/login_page.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
 bool get isAuthenticated => _user != null && _accessToken != null && _accessToken!.isNotEmpty;
  String? get accessToken => _accessToken;
  
  final AuthRepository _repository = AuthRepository();
  final SecureStorage _storage = SecureStorage.instance;
  
  // Variable pour notifier les listeners que l'état a changé
  final ValueNotifier<bool> _authStateChanged = ValueNotifier<bool>(false);
  
  Future<void> initialize() async {
    print('🔄 Initializing auth provider...');
    await loadStoredUserAndToken();
  }
  
 Future<void> loadStoredUserAndToken() async {
    try {
      // Charger le token d'abord
      final token = await _storage.read(key: 'access_token');
      print('🔍 Checking stored token...');
      
      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        print('✅ Token found in storage');
        
        // Charger l'utilisateur
        final userJson = await _storage.read(key: 'user');
        if (userJson != null) {
          final userData = jsonDecode(userJson);
          _user = UserModel.fromStorage(userData);
          print('✅ Loaded stored user: ${_user!.fullName}');
        } else {
          print('⚠️ No user data found, only token exists');
        }
      } else {
        print('❌ No token found in storage');
        _accessToken = null;
        _user = null;
      }
    } catch (e) {
      print('❌ Error loading stored credentials: $e');
      _accessToken = null;
      _user = null;
    }
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
      // S'assurer que le token est stocké
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        _accessToken = token;
      }

      _error = null;
      print('✅ Login successful: ${_user!.fullName}');
      print('🔑 Token available: ${_accessToken != null}');
    } catch (e) {
      _error = e.toString();
      _user = null;
      print('❌ Login error: $_error');
    } finally {
      _isLoading = false;
      _authStateChanged.value = !_authStateChanged.value; // Notifier le changement
    }
  }
  
  Future<void> logout({BuildContext? context}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _repository.logout();
      _user = null;
      _accessToken = null;
      print('✅ Logout successful');
      
      // Notifier que l'état d'authentification a changé
      _authStateChanged.value = !_authStateChanged.value;
      
      // Si un contexte est fourni, naviguer vers login
      if (context != null && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Ajoute un listener pour les changements d'état d'authentification
  void addAuthStateListener(VoidCallback listener) {
    _authStateChanged.addListener(listener);
  }
  
  void removeAuthStateListener(VoidCallback listener) {
    _authStateChanged.removeListener(listener);
  }
  
  // Méthode pour rafraîchir le token si nécessaire
  Future<bool> refreshTokenIfNeeded() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No token to refresh');
        return false;
      }
      
      // Ici tu pourrais implémenter la logique de rafraîchissement du token
      // Pour l'instant, on retourne juste true si le token existe
      _accessToken = token;
      print('✅ Token refreshed (placeholder)');
      return true;
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}