import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/course_model.dart';
import 'package:frontend1/data/repositories/course_repository.dart';

class CourseProvider with ChangeNotifier {
  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingFilters = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Filtres
  String? _selectedUfr;
  String? _selectedDepartment;
  List<String> _ufrOptions = [];
  List<String> _departmentOptions = [];
  bool _isSearching = false;

  // statistiques
  Map<String, dynamic> _ufrStats = {};

  // Getters
  List<CourseModel> get courses => _courses;
  CourseModel? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingFilters => _isLoadingFilters;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get selectedUfr => _selectedUfr;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get ufrOptions => _ufrOptions;
  List<String> get departmentOptions => _departmentOptions;
  bool get isSearching => _isSearching;
  Map<String, dynamic> get ufrStats => _ufrStats;

  final CourseRepository _repository = CourseRepository();

  // Charger les cours
  Future<void> loadCourses({bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _courses.clear();
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    _isSearching = false;
    notifyListeners();

    try {
      final filters = {
        if (_selectedUfr != null) 'ufr': _selectedUfr,
        if (_selectedDepartment != null) 'department': _selectedDepartment,
      };

      final response = await _repository.getCourses(
        page: _currentPage,
        limit: 20,
        filters: filters,
      );

      if (reset) {
        _courses = response.courses;
      } else {
        _courses.addAll(response.courses);
      }

      _currentPage = response.pagination.currentPage;
      _totalPages = response.pagination.totalPages;
      _hasMore =
          response.pagination.currentPage < response.pagination.totalPages;

      // Mettre à jour les options de filtres
      // await _loadFilterOptions();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger plus de cours
  Future<void> loadMoreCourses() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      await loadCourses(reset: false);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Rechercher des cours
  Future<void> searchCourses(String query) async {
    if (query.isEmpty) {
      await loadCourses();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _repository.searchCourses(query);
      _courses = results;
      _hasMore = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _courses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CRÉER UN COURS
  Future<CourseModel> createCourse(Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newCourse = await _repository.createCourse(courseData);
      
      _courses.insert(0, newCourse);
      _error = null;
      
      // Recharger les options de filtres
      await loadFilterOptions();
      
      notifyListeners();
      return newCourse;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // METTRE À JOUR UN COURS
  Future<CourseModel> updateCourse(int id, Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedCourse = await _repository.updateCourse(id, courseData);
      
      // Mettre à jour dans la liste
      final index = _courses.indexWhere((course) => course.id == id);
      if (index != -1) {
        _courses[index] = updatedCourse;
      }
      
      // Mettre à jour le cours sélectionné
      if (_selectedCourse?.id == id) {
        _selectedCourse = updatedCourse;
      }
      
      _error = null;
      notifyListeners();
      return updatedCourse;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // SUPPRIMER UN COURS
  Future<void> deleteCourse(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.deleteCourse(id);
      
      // Retirer de la liste
      _courses.removeWhere((course) => course.id == id);
      
      // Désélectionner si c'était le cours sélectionné
      if (_selectedCourse?.id == id) {
        _selectedCourse = null;
      }
      
      // Recharger les options de filtres
      await loadFilterOptions();
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // OBTENIR UN COURS PAR ID
  Future<CourseModel?> getCourseById(int courseId) async {
    try {
      return await _repository.getCourseById(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // CHARGER LES OPTIONS DE FILTRES
  Future<void> loadFilterOptions() async {
    _isLoadingFilters = true;
    notifyListeners();
    
    try {
      final options = await _repository.getFilterOptions();
      _ufrOptions = options['ufr'] ?? [];
      _departmentOptions = options['departments'] ?? [];
    } catch (e) {
      print('❌ Error loading filter options: $e');
    } finally {
      _isLoadingFilters = false;
      notifyListeners();
    }
  }
  
  // CHARGER LES STATISTIQUES
  Future<void> loadUfrStats() async {
    try {
      _ufrStats = await _repository.getUfrStats();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading UFR stats: $e');
    }
  }
  
  // SÉLECTIONNER UN COURS
  void selectCourse(CourseModel? course) {
    _selectedCourse = course;
    notifyListeners();
  }
  
  // DÉFINIR LES FILTRES
  void setUfrFilter(String? ufr) {
    _selectedUfr = ufr;
    loadCourses();
  }
  
  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    loadCourses();
  }

   // EFFACER LES FILTRES
  void clearFilters() {
    _selectedUfr = null;
    _selectedDepartment = null;
    loadCourses();
  }
  
  // EFFACER LES ERREURS
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // RÉINITIALISER
  void reset() {
    _courses.clear();
    _selectedCourse = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isLoadingFilters = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _selectedUfr = null;
    _selectedDepartment = null;
    _ufrOptions.clear();
    _departmentOptions.clear();
    _isSearching = false;
    _ufrStats.clear();
    notifyListeners();
  }
}
