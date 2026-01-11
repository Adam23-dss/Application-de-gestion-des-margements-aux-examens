import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/exam_model.dart';

class ExamRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<Exam>> getExams() async {
    try {
      final response = await _dio.get(ApiEndpoints.exams);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Exam.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load exams: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<Exam> getExamById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.exams}/$id');
      
      if (response.statusCode == 200) {
        return Exam.fromJson(response.data);
      } else {
        throw Exception('Failed to load exam: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }
}