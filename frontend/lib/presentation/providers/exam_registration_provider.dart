// presentation/providers/exam_registration_provider.dart
import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/exam_registration_model.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/repositories/exam_registration_repository.dart';

class ExamRegistrationProvider with ChangeNotifier {
  final ExamRegistrationRepository _repository = ExamRegistrationRepository();
  
  // ÉTATS
  List<StudentModel> _examStudents = [];
  List<StudentModel> _availableStudents = [];
  bool _isLoading = false;
  bool _isLoadingStudents = false;
  bool _isRegistering = false;
  String? _error;
  String _searchQuery = '';
  
  // GETTERS
  List<StudentModel> get examStudents => _examStudents;
  List<StudentModel> get availableStudents => _availableStudents;
  bool get isLoading => _isLoading;
  bool get isLoadingStudents => _isLoadingStudents;
  bool get isRegistering => _isRegistering;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  
  set searchQuery(String value) {
    _searchQuery = value;
    if (value.length >= 2) {
      _searchAvailableStudents(value);
    } else {
      _availableStudents.clear();
    }
    notifyListeners();
  }
  
  // CHARGER LES ÉTUDIANTS D'UN EXAMEN
  Future<void> loadExamStudents(int examId) async {
    _isLoadingStudents = true;
    _error = null;
    notifyListeners();
    
    try {
      _examStudents = await _repository.getExamStudents(examId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _examStudents = [];
    } finally {
      _isLoadingStudents = false;
      notifyListeners();
    }
  }
  
  // RECHERCHER DES ÉTUDIANTS DISPONIBLES
  Future<void> _searchAvailableStudents(String query) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _availableStudents = await _repository.searchStudentsForExam(
        query: query,
        limit: 10,
      );
    } catch (e) {
      _availableStudents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // AJOUTER UN ÉTUDIANT À UN EXAMEN
  Future<ExamRegistration> addStudentToExam({
    required int examId,
    required int studentId,
    String? notes,
  }) async {
    _isRegistering = true;
    _error = null;
    notifyListeners();
    
    try {
      final registration = await _repository.addStudentToExam(
        examId: examId,
        studentId: studentId,
        notes: notes,
      );
      
      // Ajouter l'étudiant à la liste locale
      final student = _availableStudents.firstWhere(
        (s) => s.id == studentId,
        orElse: () => StudentModel(
          id: studentId,
          studentCode: '',
          firstName: 'Étudiant',
          lastName: 'Ajouté',
          email: null,
          ufr: 'Inconnue',
          department: 'Inconnu',
          promotion: null,
          isActive: true,
        ),
      );
      
      _examStudents.add(student);
      
      // Retirer des étudiants disponibles
      _availableStudents.removeWhere((s) => s.id == studentId);
      
      _error = null;
      return registration;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }
  
  // RETIRER UN ÉTUDIANT D'UN EXAMEN
  Future<void> removeStudentFromExam({
    required int examId,
    required int studentId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.removeStudentFromExam(
        examId: examId,
        studentId: studentId,
      );
      
      // Retirer de la liste locale
      _examStudents.removeWhere((student) => student.id == studentId);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // VÉRIFIER SI UN ÉTUDIANT EST INSCRIT
  Future<bool> isStudentRegistered({
    required int examId,
    required int studentId,
  }) async {
    try {
      return await _repository.isStudentRegistered(
        examId: examId,
        studentId: studentId,
      );
    } catch (e) {
      return false;
    }
  }
  
  // INSCRIPTION EN MASSE
  Future<List<ExamRegistration>> bulkRegisterStudents({
    required int examId,
    required List<int> studentIds,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final registrations = await _repository.bulkRegisterStudents(
        examId: examId,
        studentIds: studentIds,
        notes: notes,
      );
      
      // Mettre à jour les listes locales
      await loadExamStudents(examId);
      
      _error = null;
      return registrations;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // EFFACER LES ERREURS
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // RÉINITIALISER
  void reset() {
    _examStudents.clear();
    _availableStudents.clear();
    _isLoading = false;
    _isLoadingStudents = false;
    _isRegistering = false;
    _error = null;
    _searchQuery = '';
    notifyListeners();
  }
  
  // FILTRER LES ÉTUDIANTS
  List<StudentModel> getFilteredAvailableStudents() {
    if (_searchQuery.isEmpty) {
      return _availableStudents;
    }
    
    final query = _searchQuery.toLowerCase();
    return _availableStudents.where((student) {
      return student.fullName.toLowerCase().contains(query) ||
             student.studentCode.toLowerCase().contains(query) ||
             student.department?.toLowerCase().contains(query) == true ||
             student.ufr?.toLowerCase().contains(query) == true;
    }).toList();
  }
}