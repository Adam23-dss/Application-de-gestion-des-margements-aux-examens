import 'package:dio/dio.dart';
import 'dart:convert';
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
    print('🚀 AuthRepository.login called');
    print('📧 Email: $email');
    
    try {
      print('🌐 Making request to: ${ApiEndpoints.login}');
      
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('✅ Login API call successful');
        
        // Vérifier si la réponse est vide
        if (response.data == null) {
          print('❌ Response data is null');
          throw Exception('Empty response from server');
        }
        
        print('📊 Response data type: ${response.data.runtimeType}');
        print('📊 Response data: ${response.data}');
        
        // Si la réponse est vide ou très courte
        if (response.data is String && (response.data as String).isEmpty) {
          print('⚠️ Response is an empty string');
          throw Exception('Server returned empty response');
        }
        
        // Essayer de créer le modèle utilisateur
        try {
          final user = UserModel.fromJson(response.data);
          
          if (user.accessToken.isEmpty) {
            print('⚠️ No access token in response');
            throw Exception('No authentication token received');
          }
          
          print('👤 User parsed successfully: ${user.fullName}');
          
          // Sauvegarder le token
          await SecureStorage.saveToken(user.accessToken);
          await SecureStorage.saveUserData(user.toJson().toString());
          
          print('💾 Token saved to secure storage');
          
          return user;
        } catch (e) {
          print('❌ Error creating UserModel: $e');
          
          // Si le parsing échoue, essayer une approche différente
          print('🔄 Trying alternative parsing...');
          
          // Vérifier si c'est du JSON valide
          if (response.data is String) {
            final strData = response.data as String;
            if (strData.trim().isEmpty) {
              throw Exception('Empty response from server');
            }
            
            // Essayer de parser manuellement
            try {
              final parsed = json.decode(strData);
              print('✅ Manually parsed JSON: $parsed');
              
              final user = UserModel.fromJson(parsed);
              await SecureStorage.saveToken(user.accessToken);
              await SecureStorage.saveUserData(user.toJson().toString());
              return user;
            } catch (parseError) {
              print('❌ Manual parsing failed: $parseError');
              throw Exception('Invalid server response format');
            }
          }
          
          throw Exception('Failed to parse user data: $e');
        }
      } else {
        print('❌ Non-200 response: ${response.statusCode}');
        
        // Essayer d'extraire un message d'erreur
        String errorMessage = 'Login failed (${response.statusCode})';
        
        if (response.data != null) {
          if (response.data is Map) {
            errorMessage = response.data['message']?.toString() ?? 
                          response.data['error']?.toString() ?? 
                          errorMessage;
          } else if (response.data is String && (response.data as String).isNotEmpty) {
            errorMessage = response.data as String;
          }
        }
        
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('❌ DioException in login:');
      print('   Type: ${e.type}');
      print('   Message: ${e.message}');
      
      if (e.response != null) {
        print('   Status: ${e.response!.statusCode}');
        print('   Data: ${e.response!.data}');
        
        String errorMessage = 'Login failed: ${e.response!.statusCode}';
        
        if (e.response!.data != null) {
          if (e.response!.data is Map) {
            errorMessage = e.response!.data['message']?.toString() ?? 
                          e.response!.data['error']?.toString() ?? 
                          errorMessage;
          } else if (e.response!.data is String && (e.response!.data as String).isNotEmpty) {
            errorMessage = e.response!.data as String;
          }
        }
        
        throw Exception(errorMessage);
      }
      
      throw Exception('Network error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Unexpected error in login: $e');
      print('Stack trace: $stackTrace');
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
      
      if (token != null && token.isNotEmpty) {
        print('✅ Found stored token, length: ${token.length}');
        
        // Pour l'instant, retourner un utilisateur de base
        return UserModel(
          id: 'stored_user',
          firstName: 'Stored',
          lastName: 'User',
          email: 'user@stored.com',
          role: 'ADMIN',
          isActive: true,
          accessToken: token,
          refreshToken: '',
        );
      } else {
        print('❌ No stored token found');
        return null;
      }
    } catch (e) {
      print('Error getting stored user: $e');
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