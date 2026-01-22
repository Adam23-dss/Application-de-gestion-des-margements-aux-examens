import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:frontend1/data/api/api_client.dart';
import 'package:frontend1/data/models/qr_code_model.dart';

class QRCodeRepository {
  final Dio _dio = ApiClient.instance;

  // Générer un QR code pour un étudiant dans un examen
  Future<QRCodeResponse> generateQRCodeForStudent({
    required int examId,
    required int studentId,
  }) async {
    try {
      print('🔐 [QRCodeRepository] Generating QR code for exam $examId, student $studentId');
      
      final response = await _dio.post(
        ApiEndpoints.generateQRCode(examId),
        data: {
          'student_id': studentId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final qrResponse = QRCodeResponse.fromJson(data['data']);
          
          print('✅ [QRCodeRepository] QR code generated successfully');
          print('📱 Student: ${qrResponse.student.name} (${qrResponse.student.code})');
          print('📱 Exam: ${qrResponse.exam.name}');
          print('📱 Expires at: ${qrResponse.expiresAt}');
          
          return qrResponse;
        } else {
          throw Exception('Failed to generate QR code: ${data['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [QRCodeRepository] Dio error: ${e.message}');
      print('📋 Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        throw Exception('Étudiant non inscrit à cet examen');
      }
      
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ [QRCodeRepository] General error: $e');
      rethrow;
    }
  }

  // Générer des QR codes en masse pour un examen
  Future<Map<String, QRCodeResponse>> generateBulkQRCodes({
    required int examId,
    required List<int> studentIds,
  }) async {
    try {
      print('🔐 [QRCodeRepository] Generating bulk QR codes for exam $examId');
      print('👥 Students: ${studentIds.length}');
      
      final response = await _dio.post(
        ApiEndpoints.generateBulkQRCodes(examId),
        data: {
          'student_ids': studentIds,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final results = <String, QRCodeResponse>{};
          final qrCodesData = data['data']['qr_codes'] as Map<String, dynamic>;
          
          for (final entry in qrCodesData.entries) {
            final studentId = entry.key;
            final qrData = entry.value as Map<String, dynamic>;
            results[studentId] = QRCodeResponse.fromJson(qrData);
          }
          
          print('✅ [QRCodeRepository] Generated ${results.length} QR codes');
          print('⚠️ Errors: ${data['data']['errors']?.length ?? 0}');
          
          return results;
        } else {
          throw Exception('Failed to generate bulk QR codes: ${data['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [QRCodeRepository] Dio error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ [QRCodeRepository] General error: $e');
      rethrow;
    }
  }

  // Vérifier un QR code scanné
  Future<QRVerificationResult> verifyQRCode({
    required int examId,
    required String qrString,
  }) async {
    try {
      print('🔍 [QRCodeRepository] Verifying QR code for exam $examId');
      
      final response = await _dio.post(
        ApiEndpoints.verifyQRCode(examId),
        data: {'qr_data': qrString},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final verification = QRVerificationResult.fromJson(data['data']);
          print('✅ [QRCodeRepository] QR code verified: ${verification.isValid}');
          return verification;
        } else {
          throw Exception('Invalid QR code: ${data['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [QRCodeRepository] Dio error: ${e.message}');
      print('📋 Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['success'] == false) {
          return QRVerificationResult(
            isValid: false,
            error: errorData['message'],
            canValidate: false,
            alreadyAttended: false,
          );
        }
      }
      
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ [QRCodeRepository] General error: $e');
      rethrow;
    }
  }

  // Valider une présence via QR code
  Future<Map<String, dynamic>> validateAttendanceFromQR({
    required int examId,
    required String qrString,
  }) async {
    try {
      print('✅ [QRCodeRepository] Validating attendance from QR code');
      
      final response = await _dio.post(
        ApiEndpoints.validateFromQRCode(examId),
        data: {'qr_data': qrString},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('✅ [QRCodeRepository] Attendance validated successfully');
          return data['data'] ?? {};
        } else {
          throw Exception('Failed to validate attendance: ${data['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [QRCodeRepository] Dio error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ [QRCodeRepository] General error: $e');
      rethrow;
    }
  }

  // Obtenir l'historique des QR codes
  Future<Map<String, dynamic>> getQRCodeHistory({
    required int examId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.qrCodeHistory(examId),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [QRCodeRepository] Dio error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ [QRCodeRepository] General error: $e');
      rethrow;
    }
  }
}