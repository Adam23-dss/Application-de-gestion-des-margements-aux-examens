import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/course_model.dart';
import 'package:frontend1/data/repositories/course_repository.dart';

class CourseProvider with ChangeNotifier {
  List<CourseModel> _courses = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
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
  
  // Getters
  List<CourseModel> get courses => _courses;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get selectedUfr => _selectedUfr;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get ufrOptions => _ufrOptions;
  List<String> get departmentOptions => _departmentOptions;
  bool get isSearching => _isSearching;
  
  final CourseRepository _repository = CourseRepository();
  
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
      _hasMore = response.pagination.currentPage < response.pagination.totalPages;
      
      // Mettre à jour les options de filtres
      await _loadFilterOptions();
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
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
  
  Future<void> createCourse({
    required String code,
    required String name,
    required String ufr,
    required String department,
    int? credits,
    String? description,
  }) async {
    try {
      // Ici, tu devrais appeler l'API pour créer le cours
      // Pour l'instant, simuler la création
      final newCourse = CourseModel(
        id: DateTime.now().millisecondsSinceEpoch,
        code: code,
        name: name,
        ufr: ufr,
        department: department,
        credits: credits,
        description: description,
      );
      
      _courses.insert(0, newCourse);
      notifyListeners();
      
      // Charger les options de filtres mises à jour
      await _loadFilterOptions();
    } catch (e) {
      throw Exception('Erreur lors de la création: ${e.toString()}');
    }
  }
  
  Future<void> updateCourse({
    required int courseId,
    required String name,
    required String ufr,
    required String department,
    int? credits,
    String? description,
  }) async {
    try {
      final index = _courses.indexWhere((course) => course.id == courseId);
      if (index != -1) {
        final updatedCourse = CourseModel(
          id: courseId,
          code: _courses[index].code,
          name: name,
          ufr: ufr,
          department: department,
          credits: credits,
          description: description,
        );
        
        _courses[index] = updatedCourse;
        notifyListeners();
        
        // Charger les options de filtres mises à jour
        await _loadFilterOptions();
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }
  
  Future<void> deleteCourse(int courseId) async {
    try {
      _courses.removeWhere((course) => course.id == courseId);
      notifyListeners();
      
      // Charger les options de filtres mises à jour
      await _loadFilterOptions();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: ${e.toString()}');
    }
  }
  
  Future<void> _loadFilterOptions() async {
    try {
      // Simuler le chargement des options de filtres
      // En réalité, tu devrais appeler l'API
      final allUfrs = _courses.map((c) => c.ufr).whereType<String>().toSet().toList();
      final allDepartments = _courses.map((c) => c.department).whereType<String>().toSet().toList();
      
      _ufrOptions = allUfrs;
      _departmentOptions = allDepartments;
    } catch (e) {
      // Ignorer les erreurs de chargement des filtres
    }
  }
  
  void setUfrFilter(String? ufr) {
    _selectedUfr = ufr;
    loadCourses();
  }
  
  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    loadCourses();
  }
  
  void clearFilters() {
    _selectedUfr = null;
    _selectedDepartment = null;
    loadCourses();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}