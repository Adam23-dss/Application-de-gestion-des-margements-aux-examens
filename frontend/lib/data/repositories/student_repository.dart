import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/data/models/student_model.dart';

class StudentRepository {
  final Dio _dio = ApiClient.instance;

  // Ajoute ces méthodes à ton StudentRepository existant

  // Créer un étudiant
  Future<StudentModel> createStudent(Map<String, dynamic> studentData) async {
    try {
      print('➕ Création étudiant avec data: $studentData');

      final response = await _dio.post(
        ApiEndpoints.students,
        data: studentData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return StudentModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Échec de la création');
        }
      }

      throw Exception('Statut HTTP non valide: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Dio error creating student: ${e.message}');

      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          final errorCode = errorData['error'];
          final message = errorData['message'] ?? 'Erreur de création';

          switch (errorCode) {
            case 'STUDENT_CODE_EXISTS':
              throw Exception('Ce code étudiant existe déjà');
            case 'EMAIL_EXISTS':
              throw Exception('Cet email est déjà utilisé');
            case 'VALIDATION_ERROR':
              throw Exception(message);
            default:
              throw Exception(message);
          }
        }
      }

      throw Exception('Erreur réseau: ${e.message}');
    }
  }

  // Récupérer un étudiant par ID
  Future<StudentModel> getStudentById(int id) async {
    try {
      print('👤 Récupération étudiant ID: $id');

      final response = await _dio.get('${ApiEndpoints.students}/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return StudentModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Étudiant non trouvé');
        }
      }

      throw Exception('Statut HTTP non valide: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Dio error fetching student $id: ${e.message}');
      throw Exception('Erreur réseau: ${e.message}');
    }
  }

  // Mettre à jour un étudiant
  Future<StudentModel> updateStudent(
    int id,
    Map<String, dynamic> studentData,
  ) async {
    try {
      print('✏️ Mise à jour étudiant $id avec data: $studentData');

      final response = await _dio.put(
        '${ApiEndpoints.students}/$id',
        data: studentData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return StudentModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Échec de la mise à jour');
        }
      }

      throw Exception('Statut HTTP non valide: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Dio error updating student: ${e.message}');
      throw Exception('Erreur réseau: ${e.message}');
    }
  }

  // Désactiver un étudiant (soft delete)
  Future<void> deleteStudent(int id) async {
    try {
      print('🗑️ Désactivation étudiant $id');

      final response = await _dio.delete('${ApiEndpoints.students}/$id');

      if (response.statusCode != 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == false) {
          throw Exception(responseData['message'] ?? 'Échec de la suppression');
        }
        throw Exception('Échec de la suppression');
      }
    } on DioException catch (e) {
      print('❌ Dio error deleting student: ${e.message}');
      throw Exception('Erreur réseau: ${e.message}');
    }
  }

  // Remplacer getStudentStats() par getUfrStats()
  Future<Map<String, dynamic>> getUfrStats() async {
    try {
      final response = await _dio.get('${ApiEndpoints.students}/stats/ufr');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          // Retourner les stats sous forme de Map
          final Map<String, dynamic> stats = {};
          final List<dynamic> ufrData = responseData['data'];

          for (var item in ufrData) {
            if (item is Map<String, dynamic>) {
              final ufr = item['ufr']?.toString();
              final count = item['student_count'] ?? 0;
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
      print('❌ Dio error getting UFR stats: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  // Méthode pour obtenir les statistiques de base (si nécessaire)
  Future<Map<String, dynamic>> getBasicStats() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.students,
        queryParameters: {
          'page': 1,
          'limit': 1, // Juste pour obtenir le total
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final pagination = responseData['data']['pagination'];
          final total = pagination['total'] ?? 0;

          return {
            'total': total,
            'active_count': total, // À adapter selon la réponse du backend
            'ufr_count': 0, // À adapter
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get stats');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error getting basic stats: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<StudentResponse> getStudents({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      print('📡 Fetching students from: ${ApiEndpoints.students}');
      
      final response = await _dio.get(
        ApiEndpoints.students,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (filters != null) ...filters,
        },
      );
      
      print('✅ Response status: ${response.statusCode}');
      print('📦 Full response: ${response.data}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          // CORRECTION ICI : les étudiants sont directement dans data (un tableau)
          List<dynamic> studentsData;
          
          if (responseData['data'] is List) {
            // Format actuel : data est une liste
            studentsData = responseData['data'] as List;
            print('🎯 Format: data is List (${studentsData.length} items)');
          } else if (responseData['data'] is Map && 
                     (responseData['data'] as Map)['students'] is List) {
            // Format alternatif : data.students
            studentsData = (responseData['data'] as Map)['students'] as List;
            print('🎯 Format: data.students (${studentsData.length} items)');
          } else if (responseData['students'] is List) {
            // Format alternatif : students directement
            studentsData = responseData['students'] as List;
            print('🎯 Format: students directly (${studentsData.length} items)');
          } else {
            print('❌ Format inconnu: ${responseData['data']?.runtimeType}');
            throw Exception('Format de réponse inattendu');
          }
          
          // Convertir les étudiants
          final students = studentsData
              .map((studentJson) {
                print('🎓 Processing student: $studentJson');
                try {
                  return StudentModel.fromJson(studentJson);
                } catch (e) {
                  print('❌ Error parsing student: $e');
                  rethrow;
                }
              })
              .toList();
          
          print('✅ Converted ${students.length} students');
          
          // Gérer la pagination
          Map<String, dynamic> paginationData;
          
          if (responseData['pagination'] != null) {
            // Pagination directe
            paginationData = responseData['pagination'] as Map<String, dynamic>;
          } else if (responseData['data'] is Map && 
                     (responseData['data'] as Map)['pagination'] != null) {
            // Pagination dans data
            paginationData = (responseData['data'] as Map)['pagination'] as Map<String, dynamic>;
          } else {
            // Pagination par défaut
            paginationData = {
              'page': page,
              'limit': limit,
              'total': students.length,
              'totalPages': 1,
            };
          }
          
          print('📊 Pagination: $paginationData');
          
          return StudentResponse(
            students: students,
            pagination: PaginationData.fromJson(paginationData),
          );
        } else {
          print('❌ API error: ${responseData['message']}');
          throw Exception(responseData['message'] ?? 'Failed to fetch students');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching students: ${e.message}');
      if (e.response != null) {
        print('❌ Response status: ${e.response!.statusCode}');
        print('❌ Response data: ${e.response!.data}');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.students}/search',
        queryParameters: {'q': query, 'limit': 10},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final students = (responseData['data']['students'] as List)
              .map((studentJson) => StudentModel.fromJson(studentJson))
              .toList();

          return students;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to search students',
          );
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
}

class StudentResponse {
  final List<StudentModel> students;
  final PaginationData pagination;

  StudentResponse({required this.students, required this.pagination});
}
