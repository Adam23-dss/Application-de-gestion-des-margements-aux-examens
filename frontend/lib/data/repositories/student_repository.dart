import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/student_model.dart';

class StudentRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<Student>> getStudents() async {
    try {
      final response = await _dio.get(ApiEndpoints.students);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Student.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<Student> getStudentByCode(String code) async {
    try {
      final response = await _dio.get('${ApiEndpoints.students}/$code');
      
      if (response.statusCode == 200) {
        return Student.fromJson(response.data);
      } else {
        throw Exception('Student not found: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Étudiant non trouvé');
      }
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }
}