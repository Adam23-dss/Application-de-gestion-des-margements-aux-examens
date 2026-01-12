import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/repositories/student_repository.dart';

class StudentProvider with ChangeNotifier {
  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedUfr;
  String? _selectedDepartment;
  
  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
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
  
  final StudentRepository _repository = StudentRepository();
  
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
      filtered = filtered.where((student) => student.ufr == _selectedUfr).toList();
    }
    
    if (_selectedDepartment != null) {
      filtered = filtered.where((student) => student.department == _selectedDepartment).toList();
    }
    
    return filtered;
  }
  
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
    } catch (e) {
      _error = e.toString();
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  
  Future<Map<String, dynamic>> getUfrStats() async {
    try {
      return await _repository.getUfrStats();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
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
    notifyListeners();
  }
}