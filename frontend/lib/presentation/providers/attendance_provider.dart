import 'package:flutter/foundation.dart';
import 'package:frontend1/data/models/attendance_model.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/repositories/attendance_repository.dart';

class AttendanceProvider with ChangeNotifier {
  List<AttendanceModel> _attendanceRecords = [];
  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  Map<String, dynamic>? _stats;
  
  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<StudentModel> get students => _students;
  List<StudentModel> get filteredStudents => _getFilteredStudents();
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  
  String get searchQuery => _searchQuery;
  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }
  
  String get selectedStatus => _selectedStatus;
  set selectedStatus(String value) {
    _selectedStatus = value;
    notifyListeners();
  }
  
  final AttendanceRepository _repository = AttendanceRepository();
  
  // Statistiques calculées
  int get totalCount => _attendanceRecords.length;
  int get presentCount => _attendanceRecords.where((a) => a.status == 'present').length;
  int get absentCount => _attendanceRecords.where((a) => a.status == 'absent').length;
  int get lateCount => _attendanceRecords.where((a) => a.status == 'late').length;
  int get excusedCount => _attendanceRecords.where((a) => a.status == 'excused').length;
  
  double get attendancePercentage {
    if (totalCount == 0) return 0;
    return (presentCount / totalCount * 100);
  }
  
  Future<void> loadExamAttendance(int examId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Charger les enregistrements de présence
      _attendanceRecords = await _repository.getExamAttendance(examId);
      
      // Charger les statistiques
      _stats = await _repository.getAttendanceStats(examId);
      
      // Extraire les étudiants des enregistrements de présence
      _students = _attendanceRecords.map((attendance) {
        return StudentModel(
          id: attendance.studentId,
          studentCode: attendance.studentCode ?? 'INCONNU',
          firstName: attendance.studentName?.split(' ').first ?? 'Étudiant',
          lastName: attendance.studentName?.split(' ').last ?? '',
          email: null,
          ufr: 'Inconnue',
          department: 'Inconnu',
          promotion: null,
          isActive: true,
        );
      }).toList();
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _attendanceRecords = [];
      _students = [];
      _stats = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<AttendanceModel> validateAttendance({
    required int examId,
    required String studentCode,
    String status = 'present',
    String validationMethod = 'manual',
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final attendance = await _repository.validateAttendance(
        examId: examId,
        studentCode: studentCode,
        status: status,
        validationMethod: validationMethod,
      );
      
      // Mettre à jour la liste locale
      final index = _attendanceRecords.indexWhere(
        (a) => a.studentId == attendance.studentId,
      );
      
      if (index != -1) {
        _attendanceRecords[index] = attendance;
      } else {
        _attendanceRecords.add(attendance);
      }
      
      // Mettre à jour les statistiques
      await _refreshStats(examId);
      
      notifyListeners();
      return attendance;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  Future<void> _refreshStats(int examId) async {
    try {
      _stats = await _repository.getAttendanceStats(examId);
    } catch (e) {
      print('Error refreshing stats: $e');
    }
  }
  
  Future<List<StudentModel>> searchStudent(String query) async {
    try {
      return await _repository.searchStudent(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void resetFilters() {
    _searchQuery = '';
    _selectedStatus = 'all';
    notifyListeners();
  }
  
  // Filtrage des étudiants
  List<StudentModel> _getFilteredStudents() {
    var filtered = _students;
    
    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
               student.studentCode.toLowerCase().contains(query);
      }).toList();
    }
    
    // Filtre par statut
    if (_selectedStatus != 'all') {
      filtered = filtered.where((student) {
        final attendance = _attendanceRecords.firstWhere(
          (a) => a.studentId == student.id,
          orElse: () => AttendanceModel(
            id: 0,
            examId: 0,
            studentId: student.id,
            status: 'absent',
            studentName: student.fullName,
            studentCode: student.studentCode,
          ),
        );
        return attendance.status == _selectedStatus;
      }).toList();
    }
    
    return filtered;
  }
}