// lib/presentation/providers/exam_provider.dart
import 'package:flutter/foundation.dart';
import 'package:frontend1/data/repositories/exam_repository.dart';
import 'package:frontend1/data/models/exam_model.dart';

class ExamProvider with ChangeNotifier {
  final ExamRepository _repository = ExamRepository();
  
  List<Exam> _exams = [];
  Exam? _selectedExam;
  List<Exam> _todayExams = [];
  List<Exam> _upcomingExams = [];
  List<Exam> _pastExams = [];
  bool _isLoading = false;
  String? _error;
  
  List<Exam> get exams => _exams;
  Exam? get selectedExam => _selectedExam;
  List<Exam> get todayExams => _todayExams;
  List<Exam> get upcomingExams => _upcomingExams;
  List<Exam> get pastExams => _pastExams;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchExams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _exams = await _repository.getExams();
      _categorizeExams();
    } catch (e) {
      _error = e.toString();
      print('Erreur ExamProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Exam?> getExamById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _selectedExam = await _repository.getExamById(id);
      return _selectedExam;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> createExam(Exam exam) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newExam = await _repository.createExam(exam);
      _exams.add(newExam);
      _categorizeExams();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateExam(String id, Exam exam) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedExam = await _repository.updateExam(id, exam);
      final index = _exams.indexWhere((e) => e.id == id);
      if (index != -1) {
        _exams[index] = updatedExam;
      }
      if (_selectedExam?.id == id) {
        _selectedExam = updatedExam;
      }
      _categorizeExams();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> deleteExam(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.deleteExam(id);
      _exams.removeWhere((exam) => exam.id == id);
      if (_selectedExam?.id == id) {
        _selectedExam = null;
      }
      _categorizeExams();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _categorizeExams() {
    final now = DateTime.now();
    _todayExams = _exams.where((exam) => exam.isToday).toList();
    _upcomingExams = _exams.where((exam) => exam.date.isAfter(now)).toList();
    _pastExams = _exams.where((exam) => exam.date.isBefore(now)).toList();
  }
  
  void selectExam(Exam exam) {
    _selectedExam = exam;
    notifyListeners();
  }
  
  void clearSelectedExam() {
    _selectedExam = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}