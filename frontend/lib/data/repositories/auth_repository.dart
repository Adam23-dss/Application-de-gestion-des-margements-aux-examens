import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/user_model.dart';
import 'package:frontend1/core/constants/app_constants.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user = User.fromJson(data['user']);
        final token = data['token'];
        
        // Sauvegarder token et user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, token);
        await prefs.setString(AppConstants.authUserKey, user.toJson().toString());
        
        return user.copyWith(token: token);
      } else {
        throw Exception('Erreur de connexion: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      }
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.authUserKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.authUserKey);
    final token = prefs.getString(AppConstants.authTokenKey);
    
    if (userJson == null || token == null) {
      return null;
    }
    
    try {
      final userMap = Map<String, dynamic>.from(userJson as Map);
      return User.fromJson(userMap).copyWith(token: token);
    } catch (e) {
      return null;
    }
  }
}