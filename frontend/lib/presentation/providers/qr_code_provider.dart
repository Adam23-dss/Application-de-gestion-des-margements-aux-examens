import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/qr_code_model.dart';
import 'package:frontend1/data/repositories/qr_code_repository.dart';

class QRCodeProvider with ChangeNotifier {
  final QRCodeRepository _repository = QRCodeRepository();
  
  bool _isGenerating = false;
  bool _isVerifying = false;
  QRCodeResponse? _generatedQRCode;
  Map<String, QRCodeResponse>? _bulkQRCodes;
  QRVerificationResult? _lastVerification;
  String? _error;
  List<Map<String, dynamic>> _qrHistory = [];
  Map<String, dynamic>? _qrHistoryPagination;

  bool get isGenerating => _isGenerating;
  bool get isVerifying => _isVerifying;
  QRCodeResponse? get generatedQRCode => _generatedQRCode;
  Map<String, QRCodeResponse>? get bulkQRCodes => _bulkQRCodes;
  QRVerificationResult? get lastVerification => _lastVerification;
  String? get error => _error;
  List<Map<String, dynamic>> get qrHistory => _qrHistory;
  Map<String, dynamic>? get qrHistoryPagination => _qrHistoryPagination;

  // Générer un QR code pour un étudiant
  Future<void> generateQRCodeForStudent({
    required int examId,
    required int studentId,
  }) async {
    _isGenerating = true;
    _error = null;
    _generatedQRCode = null;
    notifyListeners();

    try {
      print('🔄 [QRCodeProvider] Generating QR code for student $studentId');
      
      final qrResponse = await _repository.generateQRCodeForStudent(
        examId: examId,
        studentId: studentId,
      );
      
      _generatedQRCode = qrResponse;
      print('✅ [QRCodeProvider] QR code generated successfully');
    } catch (e) {
      _error = e.toString();
      print('❌ [QRCodeProvider] Error generating QR code: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Générer des QR codes en masse
  Future<void> generateBulkQRCodes({
    required int examId,
    required List<int> studentIds,
  }) async {
    _isGenerating = true;
    _error = null;
    _bulkQRCodes = null;
    notifyListeners();

    try {
      print('🔄 [QRCodeProvider] Generating bulk QR codes for ${studentIds.length} students');
      
      final qrCodes = await _repository.generateBulkQRCodes(
        examId: examId,
        studentIds: studentIds,
      );
      
      _bulkQRCodes = qrCodes;
      print('✅ [QRCodeProvider] Generated ${qrCodes.length} QR codes');
    } catch (e) {
      _error = e.toString();
      print('❌ [QRCodeProvider] Error generating bulk QR codes: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Vérifier un QR code
  Future<QRVerificationResult?> verifyQRCode({
    required int examId,
    required String qrString,
  }) async {
    _isVerifying = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 [QRCodeProvider] Verifying QR code');
      
      final verification = await _repository.verifyQRCode(
        examId: examId,
        qrString: qrString,
      );
      
      _lastVerification = verification;
      print('✅ [QRCodeProvider] QR code verified: ${verification.isValid}');
      
      return verification;
    } catch (e) {
      _error = e.toString();
      print('❌ [QRCodeProvider] Error verifying QR code: $e');
      return null;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  // Valider une présence via QR code
  Future<Map<String, dynamic>?> validateAttendanceFromQR({
    required int examId,
    required String qrString,
  }) async {
    _isVerifying = true;
    _error = null;
    notifyListeners();

    try {
      print('✅ [QRCodeProvider] Validating attendance from QR code');
      
      final result = await _repository.validateAttendanceFromQR(
        examId: examId,
        qrString: qrString,
      );
      
      print('✅ [QRCodeProvider] Attendance validated successfully');
      return result;
    } catch (e) {
      _error = e.toString();
      print('❌ [QRCodeProvider] Error validating attendance: $e');
      return null;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  // Charger l'historique des QR codes
  Future<void> loadQRCodeHistory({
    required int examId,
    int page = 1,
    int limit = 20,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final history = await _repository.getQRCodeHistory(
        examId: examId,
        page: page,
        limit: limit,
      );
      
      _qrHistory = (history['qr_codes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _qrHistoryPagination = history['pagination'] as Map<String, dynamic>?;
      
      print('✅ [QRCodeProvider] Loaded ${_qrHistory.length} QR codes from history');
    } catch (e) {
      _error = e.toString();
      print('❌ [QRCodeProvider] Error loading QR code history: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Réinitialiser
  void clearGeneratedQR() {
    _generatedQRCode = null;
    _bulkQRCodes = null;
    _error = null;
    notifyListeners();
  }

  void clearVerification() {
    _lastVerification = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAll() {
    _generatedQRCode = null;
    _bulkQRCodes = null;
    _lastVerification = null;
    _error = null;
    _qrHistory = [];
    _qrHistoryPagination = null;
    notifyListeners();
  }
}