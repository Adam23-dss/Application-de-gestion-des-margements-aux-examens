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

  // Dans ExamProvider, ajoute :

  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _supervisors = [];

  List<Map<String, dynamic>> get rooms => _rooms;
  List<Map<String, dynamic>> get courses => _courses;
  List<Map<String, dynamic>> get supervisors => _supervisors;

  // Méthodes pour charger les données
  Future<void> loadRooms() async {
    try {
      _rooms = await _repository.getRooms();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading rooms in provider: $e');
    }
  }

  Future<void> loadCourses() async {
    try {
      _courses = await _repository.getCourses();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading courses in provider: $e');
    }
  }

  Future<void> loadSupervisors() async {
    try {
      _supervisors = await _repository.getSupervisors();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading supervisors in provider: $e');
    }
  }

  // Méthode pour tout charger
  Future<void> loadAllResources() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([loadRooms(), loadCourses(), loadSupervisors()]);
    } catch (e) {
      print('❌ Error loading all resources: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  // Methodes de CRUD pour les examens
  Future<void> createExam(Map<String, dynamic> examData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final createdExam = await _repository.createExam(examData);
      _exams.add(createdExam);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExam(int examId, Map<String, dynamic> examData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedExam = await _repository.updateExam(examId, examData);
      final index = _exams.indexWhere((exam) => exam.id == examId);
      if (index != -1) {
        _exams[index] = updatedExam;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExam(int examId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteExam(examId);
      _exams.removeWhere((exam) => exam.id == examId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ExamModel> getExamDetails(int examId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final examDetails = await _repository.getExamDetails(examId);
      _error = null;
      return examDetails;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dans ExamProvider, ajouter :

  Future<ExamModel> duplicateExam(
    int examId,
    Map<String, dynamic> overrides,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final duplicatedExam = await _repository.duplicateExam(examId, overrides);
      _exams.add(duplicatedExam);
      _error = null;
      return duplicatedExam;
    } catch (e) {
      _error = 'Erreur duplication: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> generateQRCodes(int examId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.generateExamQRCodes(examId);
      _error = null;
      return result;
    } catch (e) {
      _error = 'Erreur génération QR codes: $e';
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> exportAttendance(
    int examId,
    String format,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.exportAttendanceList(examId, format);
      _error = null;
      return result;
    } catch (e) {
      _error = 'Erreur export: $e';
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
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
  List<ExamModel> get todayExams =>
      _exams.where((exam) => exam.isToday).toList();
  List<ExamModel> get upcomingExams =>
      _exams.where((exam) => exam.isUpcoming).toList();
  List<ExamModel> get activeExams =>
      _exams.where((exam) => exam.isActive).toList();
  List<ExamModel> get pastExams => _exams.where((exam) => exam.isPast).toList();

  List<ExamModel> get inProgressExams =>
      _exams.where((exam) => exam.status == 'in_progress').toList();
  List<ExamModel> get scheduledExams =>
      _exams.where((exam) => exam.status == 'scheduled').toList();
  List<ExamModel> get completedExams =>
      _exams.where((exam) => exam.status == 'completed').toList();
}
