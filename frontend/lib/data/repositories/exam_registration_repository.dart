// data/repositories/exam_registration_repository.dart
import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/exam_registration_model.dart';
import 'package:frontend1/data/models/student_model.dart';

class ExamRegistrationRepository {
  final Dio _dio = ApiClient.instance;
  
  // AJOUTER UN ÉTUDIANT À UN EXAMEN
  Future<ExamRegistration> addStudentToExam({
    required int examId,
    required int studentId,
    String? notes,
  }) async {
    try {
      print('🎯 Adding student $studentId to exam $examId');
      
      final response = await _dio.post(
        '${ApiEndpoints.exams}/$examId/students',
        data: {
          'student_id': studentId,
        },
      );
      
      if (response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final registration = ExamRegistration.fromJson(responseData['data']);
          print('✅ Student added successfully');
          return registration;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to add student to exam',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error adding student to exam: ${e.message}');
      
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          final errorCode = errorData['error'];
          final message = errorData['message'];
          
          switch (errorCode) {
            case 'EXAM_NOT_FOUND':
              throw Exception('Examen non trouvé');
            case 'STUDENT_NOT_FOUND':
              throw Exception('Étudiant non trouvé');
            case 'DUPLICATE_REGISTRATION':
              throw Exception('Étudiant déjà inscrit à cet examen');
            case 'EXAM_NOT_ACTIVE':
              throw Exception('L\'examen n\'est pas actif');
            default:
              throw Exception(message ?? 'Erreur d\'inscription');
          }
        }
      }
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // RETIRER UN ÉTUDIANT D'UN EXAMEN
  Future<void> removeStudentFromExam({
    required int examId,
    required int studentId,
  }) async {
    try {
      print('🗑️ Removing student $studentId from exam $examId');
      
      final response = await _dio.delete(
        '${ApiEndpoints.exams}/$examId/students/$studentId',
      );
      
      if (response.statusCode != 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == false) {
          throw Exception(responseData['message'] ?? 'Failed to remove student');
        }
      }
      
      print('✅ Student removed successfully');
    } on DioException catch (e) {
      print('❌ Dio error removing student: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
  
  // RÉCUPÉRER LES ÉTUDIANTS INSCRITS À UN EXAMEN
  Future<List<StudentModel>> getExamStudents(int examId) async {
    try {
      print('📋 Getting students for exam $examId');
      
      final response = await _dio.get(
        '${ApiEndpoints.exams}/$examId/students',
      );
      
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
            responseData['message'] ?? 'Failed to fetch exam students',
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
  
  // RECHERCHER DES ÉTUDIANTS POUR INSCRIPTION
  Future<List<StudentModel>> searchStudentsForExam({
    required String query,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/students/search/',
        queryParameters: {
          'q': query,
          'limit': limit,
        },
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
      print('❌ Error searching students: $e');
      return [];
    }
  }
  
  // VÉRIFIER SI UN ÉTUDIANT EST INSCRIT
  Future<bool> isStudentRegistered({
    required int examId,
    required int studentId,
  }) async {
    try {
      final students = await getExamStudents(examId);
      return students.any((student) => student.id == studentId);
    } catch (e) {
      print('❌ Error checking registration: $e');
      return false;
    }
  }
  
  // INSCRIPTION EN MASSE
  Future<List<ExamRegistration>> bulkRegisterStudents({
    required int examId,
    required List<int> studentIds,
    String? notes,
  }) async {
    try {
      print('📦 Bulk registering ${studentIds.length} students to exam $examId');
      
      final response = await _dio.post(
        '${ApiEndpoints.exams}/$examId/students/bulk',
        data: {
          'student_ids': studentIds,
          if (notes != null) 'notes': notes,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          final registrations = (responseData['data'] as List)
              .map((regJson) => ExamRegistration.fromJson(regJson))
              .toList();
          
          print('✅ Bulk registration successful');
          return registrations;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to bulk register students',
          );
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error bulk registering: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }
}