import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/attendance_model.dart';
import 'package:frontend1/data/models/student_model.dart';

class AttendanceRepository {
  final Dio _dio = ApiClient.instance;
  
  Future<AttendanceModel> validateAttendance({
    required int examId,
    required String studentCode,
    String status = 'present',
    String validationMethod = 'manual',
  }) async {
    try {
      print('✅ Validating attendance for exam: $examId, student: $studentCode');
      
      final response = await _dio.post(
        ApiEndpoints.validateAttendance,
        data: {
          'exam_id': examId,
          'student_code': studentCode,
          'status': status,
          'validation_method': validationMethod,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final attendance = AttendanceModel.fromJson(responseData['data']);
          print('✅ Attendance validated: ${attendance.status}');
          return attendance;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to validate attendance');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error validating attendance: ${e.message}');
      
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          // Extraire le message d'erreur spécifique
          final errorCode = errorData['error'];
          final message = errorData['message'];
          
          switch (errorCode) {
            case 'EXAM_NOT_FOUND':
              throw Exception('Examen non trouvé');
            case 'EXAM_NOT_IN_PROGRESS':
              throw Exception('L\'examen n\'est pas en cours');
            case 'STUDENT_NOT_FOUND':
              throw Exception('Étudiant non trouvé');
            case 'STUDENT_NOT_REGISTERED':
              throw Exception('Étudiant non inscrit à cet examen');
            default:
              throw Exception(message ?? 'Erreur de validation');
          }
        }
        throw Exception(e.response?.data?['message'] ?? 'Network error');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
  
  Future<List<AttendanceModel>> getExamAttendance(int examId) async {
    try {
      print('📊 Fetching attendance for exam ID: $examId');
      
      final response = await _dio.get(
        '${ApiEndpoints.attendance}/exam/$examId',
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final attendanceList = (responseData['data'] as List)
              .map((attendanceJson) => AttendanceModel.fromJson(attendanceJson))
              .toList();
          print('✅ Found ${attendanceList.length} attendance records');
          return attendanceList;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch attendance');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching attendance: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
  
  Future<Map<String, dynamic>> getAttendanceStats(int examId) async {
    try {
      print('📈 Fetching attendance stats for exam ID: $examId');
      
      final response = await _dio.get(
        '${ApiEndpoints.attendance}/stats/$examId',
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final stats = responseData['data'];
          print('✅ Attendance stats loaded');
          return stats;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch stats');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching stats: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
  
  Future<List<StudentModel>> searchStudent(String query) async {
    try {
      print('🔍 Searching student: $query');
      
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
          print('✅ Found ${students.length} students');
          return students;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to search students');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error searching student: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
}