import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/course_model.dart';
import 'package:frontend1/data/models/exam_model.dart';

class CourseRepository {
  final Dio _dio = ApiClient.instance;

  Future<CourseResponse> getCourses({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.courses,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (filters != null) ...filters,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final courses = (responseData['data']['courses'] as List)
              .map((courseJson) => CourseModel.fromJson(courseJson))
              .toList();

          final pagination = responseData['data']['pagination'];

          return CourseResponse(
            courses: courses,
            pagination: PaginationData.fromJson(pagination),
          );
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch courses');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<CourseModel> getCourseById(int courseId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.courses}/$courseId');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return CourseModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch course');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<CourseModel>> searchCourses(String query) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.courses}/search',
        queryParameters: {'q': query, 'limit': 10},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return (responseData['data']['courses'] as List)
              .map((courseJson) => CourseModel.fromJson(courseJson))
              .toList();
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to search courses',
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

class CourseResponse {
  final List<CourseModel> courses;
  final PaginationData pagination;

  CourseResponse({required this.courses, required this.pagination});
}
