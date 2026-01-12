import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/core/utils/secure_storage.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/api/auth_interceptor.dart';
import 'package:frontend1/data/models/user_model.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🚀 AuthRepository.login called');
      print('📧 Email: $email');

      // Réinitialise l'intercepteur pour éviter le token expiré
      _dio.interceptors.clear();
      _dio.interceptors.add(AuthInterceptor());

      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          print('✅ Login API call successful');
          
          // Créer l'utilisateur avec les tokens
          UserModel user;
          
          if (responseData['data'] is Map<String, dynamic>) {
            final data = responseData['data'] as Map<String, dynamic>;
            
            if (data.containsKey('user')) {
              // Format 1: user et tokens séparés
              final userJson = data['user'] as Map<String, dynamic>;
              final tokensJson = data['tokens'] as Map<String, dynamic>;
              
              // Fusionner user et tokens
              final mergedJson = {
                ...userJson,
                ...tokensJson,
              };
              
              user = UserModel.fromJson(mergedJson);
            } else {
              // Format 2: tout dans data
              user = UserModel.fromJson(data);
            }
          } else {
            // Format 3: réponse directe
            user = UserModel.fromJson(responseData);
          }
          
          print('👤 User created successfully: ${user.fullName}');
          
          // Sauvegarder le token d'accès séparément
          if (user.accessToken != null) {
            print('💾 Saving access token to secure storage');
            await _storage.write(
              key: 'access_token', 
              value: user.accessToken!
            );
          }
          
          // Sauvegarder le token de rafraîchissement s'il existe
          if (user.refreshToken != null) {
            await _storage.write(
              key: 'refresh_token', 
              value: user.refreshToken!
            );
          }
          
          // Sauvegarder les données utilisateur (sans tokens)
          await _storage.write(
            key: 'user',
            value: jsonEncode(user.toStorageJson()),
          );
          
          print('💾 Credentials saved to secure storage');
          
          return user;
        } else {
          throw Exception(responseData['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error: ${e.message}');
      if (e.response != null) {
        print('📡 Response status: ${e.response!.statusCode}');
        print('📊 Response data: ${e.response!.data}');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
  
  Future<UserModel?> getStoredUser() async {
    try {
      final userJson = await _storage.read(key: 'user');
      final token = await _storage.read(key: 'access_token');
      
      print('📱 Reading stored user: ${userJson != null ? 'Found' : 'Not found'}');
      print('📱 Reading stored token: ${token != null ? 'Found' : 'Not found'}');
      
      if (userJson != null && token != null) {
        final userData = jsonDecode(userJson);
        
        // Créer l'utilisateur avec le token récupéré
        final user = UserModel.fromStorage(userData).copyWith(
          accessToken: token,
        );
        
        return user;
      }
      return null;
    } catch (e) {
      print('❌ Error reading stored user: $e');
      return null;
    }
  }
  
  Future<void> logout() async {
    try {
      await _storage.delete(key: 'user');
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      print('✅ All credentials deleted from storage');
    } catch (e) {
      print('❌ Error during logout: $e');
      // Continue même en cas d'erreur
    }
  }
  
  // Fonction utilitaire pour obtenir le minimum
  int min(int a, int b) => a < b ? a : b;
}