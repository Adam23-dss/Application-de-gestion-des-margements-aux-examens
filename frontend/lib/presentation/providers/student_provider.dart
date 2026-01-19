import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/repositories/student_repository.dart';

class StudentProvider with ChangeNotifier {
  List<StudentModel> _students = [];
  StudentModel? _selectedStudent;
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedUfr;
  String? _selectedDepartment;
  String? _selectedPromotion;

  // Statistiques
  // Statistiques
  Map<String, dynamic> _ufrStats = {};
  Map<String, dynamic> _basicStats = {
    'total': 0,
    'active_count': 0,
    'ufr_count': 0,
  };

  List<StudentModel> get students => _students;
  StudentModel? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get ufrStats => _ufrStats;
  Map<String, dynamic> get basicStats => _basicStats;

  // Setters
  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  String? get selectedUfr => _selectedUfr;
  set selectedUfr(String? value) {
    _selectedUfr = value;
    notifyListeners();
  }

  String? get selectedDepartment => _selectedDepartment;
  set selectedDepartment(String? value) {
    _selectedDepartment = value;
    notifyListeners();
  }

  String? get selectedPromotion => _selectedPromotion;
  set selectedPromotion(String? value) {
    _selectedPromotion = value;
    notifyListeners();
  }

  final StudentRepository _repository = StudentRepository();

  // Methode pour obtenir les étudiants filtrés
  List<StudentModel> get filteredStudents {
    var filtered = _students;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
            student.studentCode.toLowerCase().contains(query) ||
            student.email?.toLowerCase().contains(query) == true;
      }).toList();
    }

    if (_selectedUfr != null) {
      filtered = filtered
          .where((student) => student.ufr == _selectedUfr)
          .toList();
    }

    if (_selectedDepartment != null) {
      filtered = filtered
          .where((student) => student.department == _selectedDepartment)
          .toList();
    }

    if (_selectedPromotion != null) {
      filtered = filtered
          .where((student) => student.promotion == _selectedPromotion)
          .toList();
    }

    return filtered;
  }

  // Liste des UFRs uniques
  List<String> get uniqueUfrs {
    return _students
        .map((student) => student.ufr)
        .where((ufr) => ufr.isNotEmpty)
        .toSet()
        .toList();
  }

  // Liste des départements uniques pour UFR sélectionnée
  List<String> get uniqueDepartments {
    if (_selectedUfr == null) return [];

    return _students
        .where((student) => student.ufr == _selectedUfr)
        .map((student) => student.department)
        .where((dept) => dept.isNotEmpty)
        .toSet()
        .toList();
  }

  // Liste des promotions uniques
  List<String> get uniquePromotions {
    return _students
        .map((student) => student.promotion ?? '')
        .where((promo) => promo.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Tri décroissant
  }

  // Obtenir un étudiant par ID
  Future<StudentModel?> getStudentById(int id) async {
    try {
      return await _repository.getStudentById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // charger les étudiants
  Future<void> loadStudents({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.getStudents(
        page: page,
        limit: limit,
        filters: filters,
      );

      _students = response.students;
      _error = null;

      // Mettre à jour les stats basiques
      _updateBasicStats();
    } catch (e) {
      _error = e.toString();
      _students = [];
      print('❌ Error loading students: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour les statistiques basiques
  void _updateBasicStats() {
    final total = _students.length;
    final activeCount = _students.where((s) => s.isActive).length;
    final ufrCount = uniqueUfrs.length;

    _basicStats = {
      'total': total,
      'active_count': activeCount,
      'ufr_count': ufrCount,
    };
  }

  // Créer un étudiant
  Future<StudentModel> createStudent(Map<String, dynamic> studentData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newStudent = await _repository.createStudent(studentData);

      _students.insert(0, newStudent);
      _error = null;

      // Mettre à jour les stats
      _updateBasicStats();

      notifyListeners();
      return newStudent;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour un étudiant
  Future<StudentModel> updateStudent(
    int id,
    Map<String, dynamic> studentData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedStudent = await _repository.updateStudent(id, studentData);

      // Mettre à jour dans la liste
      final index = _students.indexWhere((student) => student.id == id);
      if (index != -1) {
        _students[index] = updatedStudent;
      }

      // Mettre à jour l'étudiant sélectionné
      if (_selectedStudent?.id == id) {
        _selectedStudent = updatedStudent;
      }

      _error = null;
      notifyListeners();
      return updatedStudent;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Désactiver un étudiant
  Future<void> deleteStudent(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteStudent(id);

      // Retirer de la liste
      _students.removeWhere((student) => student.id == id);

      // Désélectionner si c'était l'étudiant sélectionné
      if (_selectedStudent?.id == id) {
        _selectedStudent = null;
      }

      // Mettre à jour les stats
      _updateBasicStats();

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sélectionner un étudiant
  void selectStudent(StudentModel? student) {
    _selectedStudent = student;
    notifyListeners();
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    try {
      return await _repository.searchStudents(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<StudentModel?> getStudentByCode(String studentCode) async {
    try {
      return await _repository.getStudentByCode(studentCode);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Charger les statistiques UFR
  Future<void> loadUfrStats() async {
    _isLoadingStats = true;
    notifyListeners();
    
    try {
      _ufrStats = await _repository.getUfrStats();
    } catch (e) {
      print('❌ Error loading UFR stats: $e');
      _ufrStats = {};
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedUfr = null;
    _selectedDepartment = null;
    _selectedPromotion = null;
    notifyListeners();
  }

   // Réinitialiser complètement
  void reset() {
    _students.clear();
    _selectedStudent = null;
    _isLoading = false;
    _isLoadingStats = false;
    _error = null;
    _searchQuery = '';
    _selectedUfr = null;
    _selectedDepartment = null;
    _selectedPromotion = null;
    _ufrStats.clear();
    _basicStats = {
      'total': 0,
      'active_count': 0,
      'ufr_count': 0,
    };
    notifyListeners();
  }
}
