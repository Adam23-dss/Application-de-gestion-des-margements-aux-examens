import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/user_model.dart';

class UserRepository {
  final Dio _dio = ApiClient.instance;

  // Récupérer tous les utilisateurs avec pagination
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? status,
  }) async {
    try {
      print('👥 Fetching users - Page: $page, Limit: $limit');

      final Map<String, dynamic> params = {
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        params['role'] = role;
      }
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }

      final response = await _dio.get(
        ApiEndpoints.users,
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final List<UserModel> users = (responseData['data'] as List)
              .map((json) => UserModel.fromJson(json))
              .toList();

          return {
            'users': users,
            'total': responseData['total'] ?? 0,
            'page': responseData['page'] ?? 1,
            'totalPages': responseData['total_pages'] ?? 1,
          };
        }
      }

      return {
        'users': [],
        'total': 0,
        'page': 1,
        'totalPages': 1,
      };
    } on DioException catch (e) {
      print('❌ Error fetching users: ${e.message}');
      throw Exception('Erreur lors de la récupération des utilisateurs');
    }
  }

  // Récupérer un utilisateur par ID
  Future<UserModel> getUserById(int id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.users}/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return UserModel.fromJson(responseData['data']);
        }
      }

      throw Exception('Utilisateur non trouvé');
    } on DioException catch (e) {
      print('❌ Error fetching user $id: ${e.message}');
      throw Exception('Erreur lors de la récupération de l\'utilisateur');
    }
  }

  // Créer un nouvel utilisateur
  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    try {
      print('➕ Creating user with data: $userData');

      final response = await _dio.post(
        ApiEndpoints.createUser,
        data: userData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return UserModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Erreur inconnue');
        }
      }

      throw Exception('Échec de la création de l\'utilisateur');
    } on DioException catch (e) {
      print('❌ Error creating user: ${e.message}');
      
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          final errorCode = errorData['error'];
          final message = errorData['message'] ?? 'Erreur de création';

          switch (errorCode) {
            case 'EMAIL_EXISTS':
              throw Exception('Cet email est déjà utilisé');
            case 'VALIDATION_ERROR':
              throw Exception(message);
            default:
              throw Exception(message);
          }
        }
      }
      
      throw Exception('Erreur réseau: ${e.message}');
    }
  }

  // Mettre à jour un utilisateur
  Future<UserModel> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      print('✏️ Updating user $id with data: $userData');

      final response = await _dio.put(
        '${ApiEndpoints.users}/$id',
        data: userData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return UserModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Erreur inconnue');
        }
      }

      throw Exception('Échec de la mise à jour de l\'utilisateur');
    } on DioException catch (e) {
      print('❌ Error updating user: ${e.message}');
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur');
    }
  }

  // Désactiver/Activer un utilisateur
  Future<void> toggleUserStatus(int id, bool isActive) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.users}/$id/status',
        data: {'is_active': isActive},
      );

      if (response.statusCode != 200) {
        throw Exception('Échec du changement de statut');
      }
    } on DioException catch (e) {
      print('❌ Error toggling user status: ${e.message}');
      throw Exception('Erreur lors du changement de statut');
    }
  }

  // Supprimer un utilisateur (soft delete)
  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('${ApiEndpoints.users}/$id');
    } on DioException catch (e) {
      print('❌ Error deleting user: ${e.message}');
      throw Exception('Erreur lors de la suppression de l\'utilisateur');
    }
  }

  // Changer le mot de passe d'un utilisateur
  Future<void> changeUserPassword(int id, String newPassword) async {
    try {
      await _dio.post(
        '${ApiEndpoints.users}/$id/password',
        data: {'new_password': newPassword},
      );
    } on DioException catch (e) {
      print('❌ Error changing password: ${e.message}');
      throw Exception('Erreur lors du changement de mot de passe');
    }
  }

  // Rechercher des utilisateurs
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.users}/search',
        queryParameters: {'q': query, 'limit': 10},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map((json) => UserModel.fromJson(json))
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error searching users: ${e.message}');
      return [];
    }
  }

  // Obtenir les statistiques des utilisateurs
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _dio.get('${ApiEndpoints.users}/stats');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return responseData['data'] ?? {};
        }
      }

      return {};
    } on DioException catch (e) {
      print('❌ Error fetching user stats: ${e.message}');
      return {};
    }
  }
}