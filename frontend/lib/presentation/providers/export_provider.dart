// presentation/providers/export_provider.dart
import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/export_model.dart';
import 'package:frontend1/data/repositories/export_repository.dart';

class ExportProvider with ChangeNotifier {
  final ExportRepository _repository = ExportRepository();
  
  // ÉTATS
  bool _isExporting = false;
  String? _exportError;
  ExportData? _lastExport;
  double _exportProgress = 0;
  
  // GETTERS
  bool get isExporting => _isExporting;
  String? get exportError => _exportError;
  ExportData? get lastExport => _lastExport;
  double get exportProgress => _exportProgress;
  
  // EXPORTER PRÉSENCES EN PDF
  Future<ExportData> exportAttendancePDF(int examId) async {
    _resetExportState();
    _isExporting = true;
    notifyListeners();
    
    try {
      // Simuler la progression pour l'UX
      _exportProgress = 0.3;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      _exportProgress = 0.6;
      notifyListeners();
      
      final exportData = await _repository.exportAttendancePDF(examId);
      
      _exportProgress = 1.0;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      _lastExport = exportData;
      _exportError = null;
      
      return exportData;
    } catch (e) {
      _exportError = e.toString();
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
  
  // EXPORTER PRÉSENCES EN EXCEL
  Future<ExportData> exportAttendanceExcel(int examId) async {
    _resetExportState();
    _isExporting = true;
    notifyListeners();
    
    try {
      _exportProgress = 0.3;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      _exportProgress = 0.6;
      notifyListeners();
      
      final exportData = await _repository.exportAttendanceExcel(examId);
      
      _exportProgress = 1.0;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      _lastExport = exportData;
      _exportError = null;
      
      return exportData;
    } catch (e) {
      _exportError = e.toString();
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
  
  // EXPORTER LISTE ÉTUDIANTS EN PDF
  Future<ExportData> exportStudentsPDF() async {
    _resetExportState();
    _isExporting = true;
    notifyListeners();
    
    try {
      _exportProgress = 0.2;
      notifyListeners();
      
      final exportData = await _repository.exportStudentsPDF();
      
      _exportProgress = 1.0;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      _lastExport = exportData;
      _exportError = null;
      
      return exportData;
    } catch (e) {
      _exportError = e.toString();
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
  
  // EXPORTER LISTE ÉTUDIANTS EN EXCEL
  Future<ExportData> exportStudentsExcel() async {
    _resetExportState();
    _isExporting = true;
    notifyListeners();
    
    try {
      _exportProgress = 0.2;
      notifyListeners();
      
      final exportData = await _repository.exportStudentsExcel();
      
      _exportProgress = 1.0;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      _lastExport = exportData;
      _exportError = null;
      
      return exportData;
    } catch (e) {
      _exportError = e.toString();
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
  
  // RÉINITIALISER L'ÉTAT
  void _resetExportState() {
    _isExporting = false;
    _exportError = null;
    _exportProgress = 0;
    notifyListeners();
  }
  
  // EFFACER L'ERREUR
  void clearError() {
    _exportError = null;
    notifyListeners();
  }
  
  // RÉINITIALISER COMPLÈTEMENT
  void reset() {
    _isExporting = false;
    _exportError = null;
    _lastExport = null;
    _exportProgress = 0;
    notifyListeners();
  }
}