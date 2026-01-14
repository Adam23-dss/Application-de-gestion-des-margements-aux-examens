import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/core/utils/secure_storage.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/data/models/student_model.dart';

class ExamRepository {
  final Dio _dio = ApiClient.instance;

  // 🔐 Toutes les méthodes récupèrent automatiquement le token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await SecureStorage.instance.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

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
        options: Options(headers: await _getAuthHeaders()),
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
        await SecureStorage.instance.deleteAll();
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
        await SecureStorage.instance.deleteAll();
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

  // Les actions CRUD pour les examens
  Future<ExamModel> createExam(Map<String, dynamic> examData) async {
    try {
      print('📝 Creating exam with data: $examData');

      final response = await _dio.post(
        ApiEndpoints.exams,
        data: examData,
        options: Options(headers: await _getAuthHeaders()),
      );

      print('📡 Create exam response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          print('✅ Exam created successfully');

          final Map<String, dynamic> responseDataMap = responseData['data'];

          // Après création, récupérer les détails complets
          try {
            final createdExamId = responseDataMap['id'] ?? 0;
            if (createdExamId > 0) {
              final completeExam = await getExamDetails(createdExamId);
              print('✅ Complete exam details fetched after creation');
              return completeExam;
            } else {
              // Fallback: utiliser les données de la réponse
              return ExamModel.fromJson(responseDataMap);
            }
          } catch (e) {
            print('⚠️ Could not fetch complete exam details: $e');
            return ExamModel.fromJson(responseDataMap);
          }
        } else {
          throw Exception(responseData['message'] ?? 'Erreur création examen');
        }
      } else if (response.statusCode == 400) {
        final errorData = response.data;
        throw Exception(
          'Validation error: ${errorData['message'] ?? 'Données invalides'}',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé - Token invalide');
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée - Admin requis');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Create exam Dio error: ${e.message}');
      if (e.response != null) {
        print('❌ Response status: ${e.response!.statusCode}');
        print('❌ Response data: ${e.response!.data}');

        if (e.response!.statusCode == 400) {
          final errorData = e.response!.data;
          if (errorData['error'] == 'VALIDATION_ERROR') {
            final errors = errorData['errors'] as List? ?? [];
            final errorMessages = errors
                .map<String>((e) => '${e['field']}: ${e['message']}')
                .join(', ');
            throw Exception('Erreur validation: $errorMessages');
          }
        }
      }
      rethrow;
    } catch (e) {
      print('❌ Create exam error: $e');
      rethrow;
    }
  }

  // Méthode pour obtenir un examen complet en fusionnant les données partielles
  Future<ExamModel> _getCompleteExamWithPartialData(
    Map<String, dynamic> partialData,
  ) async {
    try {
      final examId = partialData['id'] ?? 0;
      if (examId == 0) {
        throw Exception('ID examen manquant dans les données partielles');
      }

      // Récupérer l'examen complet
      final completeExam = await getExamDetails(examId);

      // Fusionner les données partielles avec l'examen complet
      return completeExam.copyWith(
        name: partialData['name'] ?? completeExam.name,
        description: partialData['description'] ?? completeExam.description,
        examDate: partialData['exam_date'] != null
            ? DateTime.parse(partialData['exam_date'])
            : completeExam.examDate,
        startTime: partialData['start_time'] ?? completeExam.startTime,
        endTime: partialData['end_time'] ?? completeExam.endTime,
        status: partialData['status'] ?? completeExam.status,
        courseId: partialData['course_id'] ?? completeExam.courseId,
        roomId: partialData['room_id'] ?? completeExam.roomId,
        supervisorId: partialData['supervisor_id'] ?? completeExam.supervisorId,
        totalStudents:
            partialData['total_students'] ?? completeExam.totalStudents,
      );
    } catch (e) {
      print('❌ Error merging partial data: $e');
      // Fallback: créer un ExamModel avec les données partielles disponibles
      return ExamModel.fromJson(partialData);
    }
  }

  Future<ExamModel> updateExam(
    int examId,
    Map<String, dynamic> examData,
  ) async {
    try {
      print('✏️ Updating exam $examId with data: $examData');

      // Vérifier qu'il y a des données à mettre à jour
      if (examData.isEmpty) {
        throw Exception('Aucune donnée fournie pour la mise à jour');
      }

      // Nettoyer les données pour enlever les champs qui ne sont pas dans le schéma backend
      final cleanExamData = _cleanExamDataForBackend(examData);
      print('🧹 Cleaned exam data for backend: $cleanExamData');

      final response = await _dio.put(
        '${ApiEndpoints.exams}/$examId',
        data: cleanExamData,
        options: Options(headers: await _getAuthHeaders()),
      );

      print('📡 Update exam response status: ${response.statusCode}');

      // DEBUG: Voir la réponse complète
      print('📋 Update exam response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          print('✅ Exam updated successfully');

          // Récupérer les données partielles de la réponse
          final Map<String, dynamic> partialData = responseData['data'];
          print('📄 Partial data from update: $partialData');

          // Retourner l'examen mis à jour
          try {
            // Essayer de récupérer les détails complets
            return await _getCompleteExamWithPartialData(partialData);
          } catch (e) {
            print('⚠️ Could not get complete exam, using partial data: $e');
            return ExamModel.fromJson(partialData);
          }
        } else {
          throw Exception(
            responseData['message'] ?? 'Erreur modification examen',
          );
        }
      } else {
        // Gérer les erreurs HTTP
        final errorMessage = _handleUpdateError(response);
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('❌ Update exam Dio error: ${e.message}');

      if (e.response != null) {
        print('❌ Response status: ${e.response!.statusCode}');
        print('❌ Response data: ${e.response!.data}');
        print('❌ Response headers: ${e.response!.headers}');

        // Analyser l'erreur spécifique
        final errorMessage = _analyzeDioError(e);
        throw Exception(errorMessage);
      }

      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      print('❌ Update exam error: $e');
      print('❌ Stack trace: ${e.toString()}');
      rethrow;
    }
  }

  // Méthode pour nettoyer les données avant envoi
  Map<String, dynamic> _cleanExamDataForBackend(Map<String, dynamic> examData) {
    // Liste des champs acceptés par le backend
    const acceptedFields = [
      'course_id',
      'name',
      'description',
      'exam_date',
      'start_time',
      'end_time',
      'room_id',
      'supervisor_id',
      'status',
    ];

    final cleanData = <String, dynamic>{};

    for (final field in acceptedFields) {
      if (examData.containsKey(field) && examData[field] != null) {
        cleanData[field] = examData[field];
      }
    }

    return cleanData;
  }

  // Gestion des erreurs HTTP
  String _handleUpdateError(Response response) {
    switch (response.statusCode) {
      case 400:
        final errorData = response.data;
        if (errorData['error'] == 'VALIDATION_ERROR') {
          final errors = errorData['errors'] as List? ?? [];
          final errorMessages = errors
              .map<String>((e) => '${e['field']}: ${e['message']}')
              .join(', ');
          return 'Erreur validation: $errorMessages';
        }
        return errorData['message'] ?? 'Données invalides';
      case 401:
        return 'Non authentifié - Veuillez vous reconnecter';
      case 403:
        return 'Permission refusée - Admin requis';
      case 404:
        return 'Examen non trouvé';
      case 500:
        return 'Erreur serveur - Veuillez réessayer plus tard';
      default:
        return 'Erreur serveur (${response.statusCode})';
    }
  }

  // Analyse des erreurs Dio
  String _analyzeDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Timeout de connexion au serveur';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Timeout de réception de la réponse';
    } else if (e.type == DioExceptionType.sendTimeout) {
      return 'Timeout d\'envoi des données';
    } else if (e.type == DioExceptionType.badResponse) {
      if (e.response?.statusCode == 500) {
        return 'Erreur interne du serveur (500). Le backend a échoué.';
      }
      return 'Erreur HTTP ${e.response?.statusCode}';
    } else if (e.type == DioExceptionType.cancel) {
      return 'Requête annulée';
    } else if (e.type == DioExceptionType.unknown) {
      return 'Erreur réseau inconnue';
    }
    return 'Erreur: ${e.message}';
  }

  // 4. DELETE EXAM - CORRIGÉ (annulation, pas suppression)
  Future<Map<String, dynamic>> deleteExam(int examId) async {
    try {
      print('🗑️ Cancelling exam ID: $examId');

      final response = await _dio.delete(
        '${ApiEndpoints.exams}/$examId',
        options: Options(headers: await _getAuthHeaders()),
      );

      print('📡 Delete exam response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          print('✅ Exam cancelled successfully');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Examen annulé avec succès',
            'data': responseData['data'],
          };
        } else {
          throw Exception(
            responseData['message'] ?? 'Erreur annulation examen',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Examen non trouvé');
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée - Admin requis');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Delete exam Dio error: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response!.data}');
      }
      rethrow;
    } catch (e) {
      print('❌ Delete exam error: $e');
      rethrow;
    }
  }

  Future<ExamModel> getExamDetails(int examId) async {
    try {
      print('🔍 Fetching exam details for ID: $examId');

      final response = await _dio.get(
        '${ApiEndpoints.exams}/$examId',
        options: Options(headers: await _getAuthHeaders()),
      );

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
      } else if (response.statusCode == 404) {
        throw Exception('Examen non trouvé');
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

      final response = await _dio.get(
        '${ApiEndpoints.exams}/$examId/students',
        options: Options(headers: await _getAuthHeaders()),
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
            responseData['message'] ?? 'Failed to fetch students',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Examen non trouvé');
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching exam students: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<ExamModel> startExam(int examId) async {
    try {
      print('▶️ Starting exam ID: $examId');

      final response = await _dio.post(
        '${ApiEndpoints.exams}/$examId/start',
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] != true) {
          throw Exception(responseData['message'] ?? 'Failed to start exam');
        }
        print('✅ Exam started successfully');
        return ExamModel.fromJson(responseData['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Examen non trouvé');
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error starting exam: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<ExamModel> endExam(int examId) async {
    try {
      print('⏹️ Ending exam ID: $examId');

      final response = await _dio.post(
        '${ApiEndpoints.exams}/$examId/end',
        options: Options(headers: await _getAuthHeaders()),
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] != true) {
          throw Exception(responseData['message'] ?? 'Failed to end exam');
        }
        print('✅ Exam ended successfully');
        return ExamModel.fromJson(responseData['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Examen non trouvé');
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Dio error ending exam: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  // 8. DUPLICATE EXAM - CORRIGÉ selon permissions admin
  Future<ExamModel> duplicateExam(
    int examId,
    Map<String, dynamic> overrides,
  ) async {
    try {
      print('🔁 Duplicating exam ID: $examId');

      // 1. Récupérer l'examen existant
      final originalExam = await getExamDetails(examId);

      // 2. Préparer les données selon la validation backend
      final examData = {
        'course_id': originalExam.courseId,
        'name': overrides['name'] ?? '${originalExam.name} (Copie)',
        'description': originalExam.description,
        'exam_date':
            overrides['exam_date'] ??
            originalExam.examDate.toIso8601String().split('T')[0],
        'start_time': originalExam.startTime,
        'end_time': originalExam.endTime,
        'room_id': originalExam.roomId,
        'supervisor_id': originalExam.supervisorId,
        // Fusionner les overrides
        ...overrides,
      };

      // 3. Créer le nouvel examen (nécessite permission admin)
      return await createExam(examData);
    } on DioException catch (e) {
      print('❌ Duplicate exam Dio error: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response!.data}');
      }

      // Vérifier si c'est une erreur de permission
      if (e.response?.statusCode == 403) {
        throw Exception(
          'Permission refusée - Seul un admin peut dupliquer un examen',
        );
      }

      throw Exception('Erreur lors de la duplication: ${e.message}');
    } catch (e) {
      print('❌ Duplicate exam error: $e');
      throw Exception('Erreur lors de la duplication de l\'examen: $e');
    }
  }

  // 2. MÉTHODE : Générer les QR codes (via export PDF)
  Future<Map<String, dynamic>> generateExamQRCodes(int examId) async {
    // Cette fonction n'est pas implémentée dans le backend
    return {
      'success': false,
      'message': 'Cette fonctionnalité n\'est pas encore disponible',
      'suggestion': 'Utilisez l\'export PDF pour obtenir les codes QR',
    };
  }

  // 3. MÉTHODE : Exporter la liste des présences
  Future<Map<String, dynamic>> exportAttendanceList(
    int examId,
    String format,
  ) async {
    try {
      print('📤 Exporting attendance list for exam $examId in $format format');

      // Préparer les options
      final options = Options(
        responseType: format == 'pdf' ? ResponseType.bytes : ResponseType.json,
        headers: await _getAuthHeaders(),
      );

      final response = await _dio.get(
        '/exports/attendance/$examId/$format',
        options: options,
      );

      if (response.statusCode == 200) {
        print('✅ Export successful for format: $format');

        return {
          'success': true,
          'message': 'Export réussi',
          'data': response.data,
          'filename': 'presences_examen_$examId.$format',
          'contentType': format == 'pdf'
              ? 'application/pdf'
              : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'format': format,
        };
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée pour l\'export');
      } else if (response.statusCode == 404) {
        throw Exception('Export non disponible pour ce format');
      }

      throw Exception('Erreur export - ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Export attendance error: ${e.message}');

      return {
        'success': false,
        'message': 'Erreur export: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      print('❌ Export attendance error: $e');
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }

  // MÉTHODE UTILITAIRE : Obtenir les statistiques d'un examen (si non existante)
  Future<Map<String, dynamic>> getExamStatistics(int examId) async {
    try {
      print('📊 Getting statistics for exam ID: $examId');

      final response = await _dio.get(
        '${ApiEndpoints.exams}/$examId/statistics',
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch statistics',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Examen non trouvé');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Get exam statistics error: ${e.message}');

      // Fallback: retourner des statistiques basiques
      return {
        'total_students': 0,
        'present_count': 0,
        'absent_count': 0,
        'late_count': 0,
        'excused_count': 0,
        'attendance_rate': 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Get exam statistics error: $e');
      return {
        'total_students': 0,
        'present_count': 0,
        'absent_count': 0,
        'late_count': 0,
        'excused_count': 0,
        'attendance_rate': 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }

  // 10. ADD STUDENT TO EXAM - CORRIGÉ (admin only)
  Future<Map<String, dynamic>> addStudentToExam(
    int examId,
    int studentId,
  ) async {
    try {
      print('➕ Adding student $studentId to exam $examId');

      final response = await _dio.post(
        '${ApiEndpoints.exams}/$examId/students',
        data: {'student_id': studentId},
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': 'Étudiant ajouté avec succès',
            'data': responseData['data'],
          };
        }
      } else if (response.statusCode == 400) {
        throw Exception('Données invalides ou étudiant déjà inscrit');
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée - Admin requis');
      } else if (response.statusCode == 404) {
        throw Exception('Examen ou étudiant non trouvé');
      }

      throw Exception('Erreur ajout étudiant - ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Add student to exam error: ${e.message}');
      return {
        'success': false,
        'message': 'Erreur: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      print('❌ Add student to exam error: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // 11. REMOVE STUDENT FROM EXAM - CORRIGÉ (admin only)
  Future<Map<String, dynamic>> removeStudentFromExam(
    int examId,
    int studentId,
  ) async {
    try {
      print('➖ Removing student $studentId from exam $examId');

      final response = await _dio.delete(
        '${ApiEndpoints.exams}/$examId/students/$studentId',
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return {'success': true, 'message': 'Étudiant retiré avec succès'};
        }
      } else if (response.statusCode == 403) {
        throw Exception('Permission refusée - Admin requis');
      } else if (response.statusCode == 404) {
        throw Exception('Inscription non trouvée');
      }

      throw Exception('Erreur retrait étudiant - ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Remove student from exam error: ${e.message}');
      return {'success': false, 'message': 'Erreur: ${e.message}'};
    } catch (e) {
      print('❌ Remove student from exam error: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // 1. Récupérer les salles disponibles
  Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      print('🏫 Fetching rooms from API');

      final response = await _dio.get(
        '/rooms', // Route à créer dans le backend
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching rooms: $e');
      return [];
    }
  }

  // 2. Récupérer les cours disponibles
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      print('📚 Fetching courses from API');

      final response = await _dio.get(
        '/courses', // Route à créer dans le backend
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching courses: $e');
      return [];
    }
  }

  // 3. Récupérer les superviseurs disponibles
  Future<List<Map<String, dynamic>>> getSupervisors() async {
    try {
      print('👨‍🏫 Fetching supervisors from API');

      final response = await _dio.get(
        '/auth/users/role/supervisor', // Route à créer dans le backend
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching supervisors: $e');
      return [];
    }
  }
}
