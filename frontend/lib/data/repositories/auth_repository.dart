import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/core/utils/secure_storage.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;
  
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        
        // Save token and user data
        await SecureStorage.saveToken(user.token);
        await SecureStorage.saveUserData(user.toJson().toString());
        
        return user;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
  
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (e) {
      // Even if API call fails, clear local data
    } finally {
      await SecureStorage.clearAll();
    }
  }
  
  Future<UserModel?> getStoredUser() async {
    try {
      final userData = await SecureStorage.getUserData();
      final token = await SecureStorage.getToken();
      
      if (userData != null && token != null && token.isNotEmpty) {
        // Simple parsing - in real app you'd use jsonDecode
        // For now, we'll just verify token and fetch fresh user data
        final isValid = await verifyToken();
        if (isValid) {
          // Token is valid, return a placeholder user
          // In Phase 2, we'll add an endpoint to get user profile
          return UserModel(
            id: 'stored_id',
            name: 'Stored User',
            email: 'stored@email.com',
            role: 'ADMIN', // Default to admin for testing
            token: token,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> verifyToken() async {
    try {
      final response = await _dio.get(ApiEndpoints.verifyToken);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}