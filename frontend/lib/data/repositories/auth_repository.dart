import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/core/utils/secure_storage.dart';
import 'package:frontend1/test_backend.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🚀 AuthRepository.login called');
      print('📧 Email: $email');

      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Login API call successful');

        final responseData = response.data;
        print('📊 Response keys: ${responseData.keys.toList()}');

        if (responseData['success'] == true) {
          final user = UserModel.fromJson(responseData);

          print('👤 User created successfully: ${user.fullName}');
          print('🔑 Access token extracted: ${user.accessToken.isNotEmpty}');
          print(
            '🔑 Token (first 30): ${user.accessToken.substring(0, min(30, user.accessToken.length))}...',
          );

          // Save token and user data
          await SecureStorage.saveToken(user.accessToken);
          await SecureStorage.saveUserData(user.toJson().toString());

          print('💾 Credentials saved to secure storage');

          return user;
        } else {
          throw Exception(responseData['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response!.data}');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (e) {
      print('Warning: Logout API call failed: $e');
    } finally {
      await SecureStorage.clearAll();
    }
  }

  Future<UserModel?> getStoredUser() async {
    try {
      final token = await SecureStorage.getToken();

      if (token == null || token.isEmpty) {
        print('❌ No token found in storage');
        return null;
      }

      print('🔍 Checking stored token...');

      // Vérifier le token avec l'API
      try {
        final response = await _dio.get(
          ApiEndpoints.testAuth,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          print('✅ Token is valid');

          // Récupérer le profil utilisateur
          final profileResponse = await _dio.get(
            ApiEndpoints.profile,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (profileResponse.statusCode == 200 &&
              profileResponse.data['success'] == true) {
            final user = UserModel.fromJson(profileResponse.data);
            print('✅ User profile loaded from API: ${user.fullName}');

            // Sauvegarder à nouveau pour mettre à jour les données
            await SecureStorage.saveToken(token);
            await SecureStorage.saveUserData(user.toJson().toString());

            return user;
          }
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          print('❌ Token expired or invalid');
          await SecureStorage.clearAll();
          return null;
        }
        print('⚠️ Error checking token: ${e.message}');
      }

      // Si le token n'est pas valide, vérifier les données stockées
      final userData = await SecureStorage.getUserData();
      if (userData != null && userData.isNotEmpty) {
        try {
          final jsonData = json.decode(userData);
          final user = UserModel.fromJson(jsonData);
          print('⚠️ Using cached user data (token check failed)');
          return user;
        } catch (e) {
          print('❌ Error parsing stored user data: $e');
        }
      }

      print('❌ No valid user found');
      return null;
    } catch (e) {
      print('❌ Error getting stored user: $e');
      return null;
    }
  }
}
