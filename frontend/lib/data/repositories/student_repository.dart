import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/data/models/student_model.dart';

class StudentRepository {
  final Dio _dio = ApiClient.instance;
  
  Future<StudentResponse> getStudents({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.students,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (filters != null) ...filters,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final students = (responseData['data']['students'] as List)
              .map((studentJson) => StudentModel.fromJson(studentJson))
              .toList();
          
          final pagination = responseData['data']['pagination'];
          
          return StudentResponse(
            students: students,
            pagination: PaginationData.fromJson(pagination),
          );
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch students');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching students: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
  
  Future<List<StudentModel>> searchStudents(String query) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.students}/search',
        queryParameters: {
          'q': query,
          'limit': 10,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final students = (responseData['data']['students'] as List)
              .map((studentJson) => StudentModel.fromJson(studentJson))
              .toList();
          
          return students;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to search students');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error searching students: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
  
  Future<StudentModel?> getStudentByCode(String studentCode) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.students}/code/$studentCode',
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return StudentModel.fromJson(responseData['data']);
        } else {
          return null;
        }
      } else {
        return null;
      }
    } on DioException catch (e) {
      print('❌ Dio error getting student by code: ${e.message}');
      return null;
    }
  }
  
  Future<Map<String, dynamic>> getUfrStats() async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.students}/stats/ufr',
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get stats');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error getting UFR stats: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
}

class StudentResponse {
  final List<StudentModel> students;
  final PaginationData pagination;
  
  StudentResponse({
    required this.students,
    required this.pagination,
  });
}