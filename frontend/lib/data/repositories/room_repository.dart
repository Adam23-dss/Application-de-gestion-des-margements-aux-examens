// data/repositories/room_repository.dart
import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/room_model.dart';

class RoomRepository {
  final Dio _dio = ApiClient.instance;
  
  // RÉCUPÉRER LES SALLES
  Future<RoomResponse> getRooms({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rooms,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (filters != null) ...filters,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final rooms = (responseData['data'] as List)
              .map((roomJson) => RoomModel.fromJson(roomJson))
              .toList();
          
          final pagination = responseData['pagination'];
          
          return RoomResponse(
            rooms: rooms,
            pagination: PaginationData.fromJson(pagination),
          );
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch rooms');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // RÉCUPÉRER UNE SALLE PAR ID
  Future<RoomModel> getRoomById(int roomId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.rooms}/$roomId');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return RoomModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch room');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // RECHERCHER DES SALLES
  Future<List<RoomModel>> searchRooms(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.rooms,
        queryParameters: {
          'search': query,
          'limit': 10,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((roomJson) => RoomModel.fromJson(roomJson))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to search rooms');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // CRÉER UNE SALLE
  Future<RoomModel> createRoom(Map<String, dynamic> roomData) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rooms,
        data: roomData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return RoomModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create room');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          switch (errorData['error']) {
            case 'DUPLICATE_ROOM':
              throw Exception('Une salle avec ce code existe déjà');
            case 'MISSING_REQUIRED_FIELDS':
              throw Exception(errorData['message'] ?? 'Champs requis manquants');
            case 'INVALID_CAPACITY':
              throw Exception('La capacité doit être positive');
            default:
              throw Exception(errorData['message'] ?? 'Erreur de création');
          }
        }
      }
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // METTRE À JOUR UNE SALLE
  Future<RoomModel> updateRoom(int id, Map<String, dynamic> roomData) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.rooms}/$id',
        data: roomData,
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return RoomModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update room');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // SUPPRIMER (DÉSACTIVER) UNE SALLE
  Future<void> deleteRoom(int id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.rooms}/$id');
      
      if (response.statusCode != 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == false) {
          if (responseData['error'] == 'ROOM_IN_USE') {
            throw Exception('Cette salle est utilisée par des examens. Modifiez d\'abord les examens associés.');
          }
          throw Exception(responseData['message'] ?? 'Failed to delete room');
        }
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] == 'ROOM_IN_USE') {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // OBTENIR LES SALLES DISPONIBLES
  Future<List<RoomModel>> getAvailableRooms({
    required int capacity,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.rooms}/available',
        queryParameters: {
          'capacity': capacity,
          'date': date,
          'start_time': startTime,
          'end_time': endTime,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((roomJson) => RoomModel.fromJson(roomJson))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get available rooms');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // OBTENIR LES STATISTIQUES PAR BÂTIMENT
  Future<Map<String, dynamic>> getBuildingStats() async {
    try {
      final response = await _dio.get('${ApiEndpoints.rooms}/stats/building');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final stats = <String, dynamic>{};
          final List<dynamic> buildingData = responseData['data'];
          
          for (var item in buildingData) {
            if (item is Map<String, dynamic>) {
              final building = item['building']?.toString();
              final count = item['count'] ?? 0;
              if (building != null) {
                stats[building] = count;
              }
            }
          }
          
          return stats;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get building stats');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // OBTENIR LES OPTIONS DE FILTRES
  Future<Map<String, List<String>>> getFilterOptions() async {
    try {
      final response = await _dio.get('${ApiEndpoints.rooms}/filters/options');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final options = responseData['data'];
          return {
            'buildings': List<String>.from(options['buildings'] ?? []),
            'capacities': List<String>.from(options['capacities'] ?? []),
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get filter options');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}