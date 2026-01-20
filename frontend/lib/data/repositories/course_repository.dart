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
          // Correction du format - les cours sont directement dans 'data'
          final courses = (responseData['data'] as List)
              .map((courseJson) => CourseModel.fromJson(courseJson))
              .toList();

          final pagination = responseData['pagination'];

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
          return (responseData['data'] as List)
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

  // CRÉER UN COURS
  Future<CourseModel> createCourse(Map<String, dynamic> courseData) async {
    try {
      final response = await _dio.post(ApiEndpoints.courses, data: courseData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return CourseModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create course');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          switch (errorData['error']) {
            case 'DUPLICATE_COURSE':
              throw Exception('Un cours avec ce code existe déjà');
            case 'MISSING_REQUIRED_FIELDS':
              throw Exception(
                errorData['message'] ?? 'Champs requis manquants',
              );
            default:
              throw Exception(errorData['message'] ?? 'Erreur de création');
          }
        }
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // METTRE À JOUR UN COURS
  Future<CourseModel> updateCourse(
    int id,
    Map<String, dynamic> courseData,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.courses}/$id',
        data: courseData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return CourseModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update course');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // SUPPRIMER UN COURS
  Future<void> deleteCourse(int id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.courses}/$id');

      if (response.statusCode != 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == false) {
          if (responseData['error'] == 'COURSE_IN_USE') {
            throw Exception(
              'Ce cours est utilisé par des examens. Supprimez d\'abord les examens associés.',
            );
          }
          throw Exception(responseData['message'] ?? 'Failed to delete course');
        }
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] == 'COURSE_IN_USE') {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // OBTENIR LES STATISTIQUES PAR UFR
  Future<Map<String, dynamic>> getUfrStats() async {
    try {
      final response = await _dio.get('${ApiEndpoints.courses}/stats/ufr');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final stats = <String, dynamic>{};
          final List<dynamic> ufrData = responseData['data'];

          for (var item in ufrData) {
            if (item is Map<String, dynamic>) {
              final ufr = item['ufr']?.toString();
              final count = item['count'] ?? 0;
              if (ufr != null) {
                stats[ufr] = count;
              }
            }
          }

          return stats;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get stats');
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
      final response = await _dio.get(
        '${ApiEndpoints.courses}/filters/options',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final options = responseData['data'];
          return {
            'ufr': List<String>.from(options['ufr'] ?? []),
            'departments': List<String>.from(options['departments'] ?? []),
          };
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to get filter options',
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
