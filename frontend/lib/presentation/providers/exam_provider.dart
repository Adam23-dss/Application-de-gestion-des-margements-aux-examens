import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/repositories/exam_repository.dart';

class ExamProvider with ChangeNotifier {
  List<ExamModel> _exams = [];
  ExamModel? _selectedExam;
  bool _isLoading = false;
  String? _error;
  
  List<ExamModel> get exams => _exams;
  ExamModel? get selectedExam => _selectedExam;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  final ExamRepository _repository = ExamRepository();
  
  Future<void> loadExams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _repository.getExams();
      _exams = response.exams;
      _error = null;
      print('✅ Loaded ${_exams.length} exams');
    } catch (e) {
      _error = e.toString();
      _exams = [];
      print('❌ Error loading exams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> selectExam(int examId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _selectedExam = await _repository.getExamDetails(examId);
      print('✅ Exam details loaded: ${_selectedExam!.name}');
    } catch (e) {
      _error = e.toString();
      _selectedExam = null;
      print('❌ Error selecting exam: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<StudentModel>> getExamStudents(int examId) async {
    try {
      return await _repository.getExamStudents(examId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  Future<void> startExam(int examId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _repository.startExam(examId);
      print('✅ Exam $examId started');
      
      // Mettre à jour le statut local
      final index = _exams.indexWhere((exam) => exam.id == examId);
      if (index != -1) {
        _exams[index] = _exams[index].copyWith(status: 'in_progress');
      }
      
      if (_selectedExam?.id == examId) {
        _selectedExam = _selectedExam?.copyWith(status: 'in_progress');
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  Future<void> endExam(int examId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _repository.endExam(examId);
      print('✅ Exam $examId ended');
      
      // Mettre à jour le statut local
      final index = _exams.indexWhere((exam) => exam.id == examId);
      if (index != -1) {
        _exams[index] = _exams[index].copyWith(status: 'completed');
      }
      
      if (_selectedExam?.id == examId) {
        _selectedExam = _selectedExam?.copyWith(status: 'completed');
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  void clearSelection() {
    _selectedExam = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Filtres
  List<ExamModel> get todayExams => _exams.where((exam) => exam.isToday).toList();
  List<ExamModel> get upcomingExams => _exams.where((exam) => exam.isUpcoming).toList();
  List<ExamModel> get activeExams => _exams.where((exam) => exam.isActive).toList();
  List<ExamModel> get pastExams => _exams.where((exam) => exam.isPast).toList();
  
  List<ExamModel> get inProgressExams => _exams.where((exam) => exam.status == 'in_progress').toList();
  List<ExamModel> get scheduledExams => _exams.where((exam) => exam.status == 'scheduled').toList();
  List<ExamModel> get completedExams => _exams.where((exam) => exam.status == 'completed').toList();
}