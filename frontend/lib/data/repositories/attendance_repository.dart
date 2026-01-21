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
          throw Exception(
            responseData['message'] ?? 'Failed to validate attendance',
          );
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
          throw Exception(
            responseData['message'] ?? 'Failed to fetch attendance',
          );
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
      final response = await _dio.get(
        '/students/search',
        queryParameters: {'q': query, 'limit': 10},
      );

      print('🔍 Search response: ${response.data}');

      // ICI EST LE PROBLÈME : La réponse a une structure différente
      if (response.data['success'] == true && response.data['data'] != null) {
        // LES ÉTUDIANTS SONT DANS response.data['data']
        final List<dynamic> studentList = response.data['data'];

        return studentList.map((json) {
          print('📄 Student JSON: $json');
          return StudentModel.fromJson(json);
        }).toList();
      } else {
        print('⚠️ Response format incorrect: ${response.data}');
        return [];
      }
    } catch (e) {
      print('❌ Error in searchStudent: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // data/repositories/attendance_repository.dart - Ajouter
Future<StudentModel?> getStudentDetails(String studentCode) async {
  try {
    final response = await _dio.get(
      '/students/code/$studentCode',
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        return StudentModel.fromJson(responseData['data']);
      }
    }
    return null;
  } catch (e) {
    print('❌ Error getting student details: $e');
    return null;
  }
}

Future<List<StudentModel>> getExamStudents(int examId) async {
  try {
    final response = await _dio.get(
      '/exams/$examId/students',
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        return (responseData['data'] as List)
            .map((studentJson) => StudentModel.fromJson(studentJson))
            .toList();
      }
    }
    return [];
  } catch (e) {
    print('❌ Error getting exam students: $e');
    return [];
  }
}

Future<Map<String, dynamic>> getStudentAttendanceHistory(int studentId) async {
  try {
    final response = await _dio.get(
      '/students/$studentId/attendance',
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      return responseData['data'] ?? {};
    }
    return {};
  } catch (e) {
    print('❌ Error getting attendance history: $e');
    return {};
  }
}

// Validation en masse (pour admin)
Future<List<AttendanceModel>> bulkValidateAttendance({
  required int examId,
  required List<String> studentCodes,
  String status = 'present',
  String validationMethod = 'manual',
}) async {
  try {
    final response = await _dio.post(
      '/attendance/bulk',
      data: {
        'exam_id': examId,
        'student_codes': studentCodes,
        'status': status,
        'validation_method': validationMethod,
      },
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        return (responseData['data'] as List)
            .map((attendanceJson) => AttendanceModel.fromJson(attendanceJson))
            .toList();
      }
    }
    throw Exception('Failed to bulk validate');
  } on DioException catch (e) {
    if (e.response != null) {
      final errorData = e.response!.data;
      throw Exception(errorData['message'] ?? 'Network error');
    }
    throw Exception('Network error: ${e.message}');
  }
}
}