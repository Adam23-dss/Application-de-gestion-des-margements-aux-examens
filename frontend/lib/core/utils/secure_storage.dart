import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  static SecureStorage get instance => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<void> write({required String key, required String value}) async {
    try {
      print('💾 Saving to secure storage - Key: $key');
      print('💾 Value length: ${value.length}');
      if (value.length < 50) {
        print('💾 Value: $value');
      } else {
        print('💾 Value (first 50 chars): ${value.substring(0, 50)}...');
      }
      
      await _storage.write(key: key, value: value);
      print('✅ Saved to secure storage');
    } catch (e) {
      print('❌ Error saving to secure storage: $e');
      rethrow;
    }
  }

  Future<String?> read({required String key}) async {
    try {
      print('📖 Reading from secure storage - Key: $key');
      final value = await _storage.read(key: key);
      
      if (value != null) {
        print('✅ Found value for key: $key');
        print('📖 Value length: ${value.length}');
        if (value.length < 50) {
          print('📖 Value: $value');
        } else {
          print('📖 Value (first 50 chars): ${value.substring(0, 50)}...');
        }
      } else {
        print('⚠️ No value found for key: $key');
      }
      
      return value;
    } catch (e) {
      print('❌ Error reading from secure storage: $e');
      return null;
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
      print('🗑️ Deleted key: $key');
    } catch (e) {
      print('❌ Error deleting from secure storage: $e');
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      print('🗑️ All data deleted from secure storage');
    } catch (e) {
      print('❌ Error deleting all from secure storage: $e');
    }
  }

  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      print('❌ Error checking key: $e');
      return false;
    }
  }
}