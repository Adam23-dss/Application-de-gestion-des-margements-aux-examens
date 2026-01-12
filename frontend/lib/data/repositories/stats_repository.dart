import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/stats_model.dart';

class StatsRepository {
  final Dio _dio = ApiClient.instance;

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get('${ApiEndpoints.stats}/dashboard');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return DashboardStats.fromJson(responseData['data']);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch dashboard stats',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<DailyStats> getDailyStats({String? date}) async {
    try {
      final endpoint = date != null
          ? '${ApiEndpoints.stats}/daily/$date'
          : '${ApiEndpoints.stats}/daily';

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return DailyStats.fromJson(responseData['data']);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch daily stats',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getExamStats(int examId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.stats}/exam/$examId');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch exam stats',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
