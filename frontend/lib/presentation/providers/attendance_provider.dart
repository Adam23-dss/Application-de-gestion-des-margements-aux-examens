// lib/presentation/providers/attendance_provider.dart
import 'package:flutter/foundation.dart';
import 'package:frontend1/data/repositories/attendance_repository.dart';
import 'package:frontend1/data/models/attendance_model.dart';
// import 'package:frontend1/data/services/socket_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();
  final SocketService _socketService = SocketService();
  
  List<Attendance> _attendances = [];
  List<Attendance> _recentValidations = [];
  bool _isLoading = false;
  String? _error;
  
  List<Attendance> get attendances => _attendances;
  List<Attendance> get recentValidations => _recentValidations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void connectToSocket(String? token) {
    _socketService.connect(token: token);
    _socketService.addListener(_handleSocketMessage);
  }
  
  void disconnectSocket() {
    _socketService.disconnect();
    _socketService.removeListener(_handleSocketMessage);
  }
  
  void _handleSocketMessage(dynamic message) {
    if (message is Map<String, dynamic> && message['event'] == 'attendance-updated') {
      final attendance = Attendance.fromJson(message['data']);
      _updateAttendanceList(attendance);
      _addRecentValidation(attendance);
      notifyListeners();
    }
  }
  
  Future<void> validateAttendance({
    required String studentCode,
    required String examId,
    required String status,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final attendance = await _repository.validateAttendance(
        studentCode: studentCode,
        examId: examId,
        status: status,
        comment: comment,
      );
      
      _addRecentValidation(attendance);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<Attendance>> getExamAttendance(String examId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _attendances = await _repository.getExamAttendance(examId);
      return _attendances;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Attendance?> getAttendanceById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      return await _repository.getAttendanceById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateAttendanceStatus(String id, String status, String? comment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final attendance = await _repository.updateAttendanceStatus(id, status, comment);
      _updateAttendanceList(attendance);
      _addRecentValidation(attendance);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<Attendance>> getStudentAttendance(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      return await _repository.getStudentAttendance(studentId);
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _updateAttendanceList(Attendance attendance) {
    final index = _attendances.indexWhere((a) => a.id == attendance.id);
    if (index != -1) {
      _attendances[index] = attendance;
    } else {
      _attendances.add(attendance);
    }
  }
  
  void _addRecentValidation(Attendance attendance) {
    _recentValidations.insert(0, attendance);
    if (_recentValidations.length > 10) {
      _recentValidations.removeLast();
    }
  }
  
  void clearRecentValidations() {
    _recentValidations.clear();
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}