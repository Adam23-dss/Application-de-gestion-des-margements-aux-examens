import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/core/utils/secure_storage.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/data/models/student_model.dart';

class ExamRepository {
  final Dio _dio = ApiClient.instance;

  Future<ExamResponse> getExams({
    int page = 1,
    int limit = 20,
    String? status,
    int? courseId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('📚 Fetching exams from API (page: $page, limit: $limit)');

      // Vérifier le token
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.get(
        ApiEndpoints.exams,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (courseId != null) 'course_id': courseId,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📡 Exams API response: ${response.statusCode}');
      print('📊 Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          // Vérifier la structure de la réponse
          print('✅ Response keys: ${responseData.keys.toList()}');
          print('✅ Data type: ${responseData['data'].runtimeType}');

          // Deux possibilités :
          // 1. La réponse contient directement une liste d'examens
          // 2. La réponse contient {exams: [...], pagination: {...}}

          dynamic examsData;
          PaginationData pagination;

          if (responseData['data'] is List) {
            // Cas 1: La réponse est directement une liste
            examsData = responseData['data'];
            pagination = PaginationData(
              currentPage: page,
              totalPages: 1,
              totalItems: examsData.length,
              itemsPerPage: limit,
            );
          } else if (responseData['data'] is Map &&
              (responseData['data'] as Map).containsKey('exams')) {
            // Cas 2: Structure {exams: [...], pagination: {...}}
            final data = responseData['data'] as Map<String, dynamic>;
            examsData = data['exams'] ?? [];
            pagination = PaginationData.fromJson(data['pagination'] ?? {});
          } else {
            // Structure inattendue
            print('⚠️ Unexpected response structure: ${responseData['data']}');
            examsData = [];
            pagination = PaginationData(
              currentPage: page,
              totalPages: 1,
              totalItems: 0,
              itemsPerPage: limit,
            );
          }

          // Convertir les données en ExamModel
          final examsList = (examsData as List)
              .map((examJson) => ExamModel.fromJson(examJson))
              .toList();

          print('✅ Found ${examsList.length} exams');

          return ExamResponse(exams: examsList, pagination: pagination);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch exams');
        }
      } else if (response.statusCode == 401) {
        await SecureStorage.clearAll();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching exams: ${e.message}');

      if (e.response != null) {
        print('❌ Response status: ${e.response!.statusCode}');
        print('❌ Response data: ${e.response!.data}');
      }

      if (e.response?.statusCode == 401) {
        await SecureStorage.clearAll();
        throw Exception('Session expired. Please login again.');
      }

      if (e.response != null) {
        final errorMsg = e.response?.data?['message'] ?? 'Network error';
        throw Exception(errorMsg);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error fetching exams: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<ExamModel> getExamDetails(int examId) async {
    try {
      print('🔍 Fetching exam details for ID: $examId');

      final response = await _dio.get('${ApiEndpoints.exams}/$examId');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final exam = ExamModel.fromJson(responseData['data']);
          print('✅ Exam details loaded: ${exam.name}');
          return exam;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch exam details',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching exam details: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<StudentModel>> getExamStudents(int examId) async {
    try {
      print('👥 Fetching students for exam ID: $examId');

      final response = await _dio.get('${ApiEndpoints.exams}/$examId/students');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final students = (responseData['data'] as List)
              .map((studentJson) => StudentModel.fromJson(studentJson))
              .toList();
          print('✅ Found ${students.length} students');
          return students;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch students',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching exam students: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> startExam(int examId) async {
    try {
      print('▶️ Starting exam ID: $examId');

      final response = await _dio.post('${ApiEndpoints.exams}/$examId/start');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] != true) {
          throw Exception(responseData['message'] ?? 'Failed to start exam');
        }
        print('✅ Exam started successfully');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error starting exam: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> endExam(int examId) async {
    try {
      print('⏹️ Ending exam ID: $examId');

      final response = await _dio.post('${ApiEndpoints.exams}/$examId/end');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] != true) {
          throw Exception(responseData['message'] ?? 'Failed to end exam');
        }
        print('✅ Exam ended successfully');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error ending exam: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
}
