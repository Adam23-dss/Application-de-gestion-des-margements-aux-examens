import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Token methods
  static Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      print('⚠️ WARNING: Trying to save empty token');
      return;
    }
    await _storage.write(key: _tokenKey, value: token);
    print('💾 Token saved to secure storage');
    print('   Token length: ${token.length}');
    print('   First 20 chars: ${token.substring(0, min(20, token.length))}...');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User data methods
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userDataKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
