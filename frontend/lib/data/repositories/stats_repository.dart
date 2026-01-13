// lib/data/repositories/stats_repository.dart
import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/stats_model.dart';

class StatsRepository {
  final Dio _dio = ApiClient.instance;

  Future<DashboardStats> getDashboardStats() async {
    try {
      print('📊 Fetching dashboard stats from: ${ApiEndpoints.dashboardStats}');

      final response = await _dio.get(ApiEndpoints.dashboardStats);

      print('📦 Response status: ${response.statusCode}');
      print('📦 Full response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Vérifier si la requête a réussi
        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          print('✅ Success! Data: $data');
          return DashboardStats.fromJson(data);
        } else {
          throw Exception(
            'API returned success: false - ${responseData['message']}',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('🌐 Dio error: ${e.message}');
      print('🌐 Response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  Future<DailyStats> getDailyStats({String? date}) async {
    try {
      String endpoint;
      if (date != null) {
        endpoint = '${ApiEndpoints.baseUrl}/stats/daily/$date';
      } else {
        endpoint = '${ApiEndpoints.baseUrl}/stats/daily';
      }

      print('📅 Fetching daily stats from: $endpoint');
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          return DailyStats.fromJson(data);
        } else {
          throw Exception(
            'API returned success: false - ${responseData['message']}',
          );
        }
      }
      throw Exception('API error: ${response.statusCode}');
    } on DioException catch (e) {
      print('🌐 Daily stats error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getExamStats(int examId) async {
    try {
      final endpoint = '${ApiEndpoints.baseUrl}/stats/exam/$examId';
      print('📈 Fetching exam stats from: $endpoint');

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception('API returned success: false');
        }
      }
      throw Exception('API error: ${response.statusCode}');
    } on DioException catch (e) {
      print('🌐 Exam stats error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
}
