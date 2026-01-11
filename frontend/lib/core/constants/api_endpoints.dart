import 'package:frontend1/core/constants/app_constants.dart';

class ApiEndpoints {
  static const String baseUrl = AppConstants.baseUrl;
  static const String wsUrl = AppConstants.wsUrl;
  
  // Authentication
  static const String login = '$baseUrl/api/auth/login';
  
  // Exams
  static const String exams = '$baseUrl/api/exams';

  // Students
  static const String students = '$baseUrl/api/students';
  
  // Attendance
  static const String validateAttendance = '$baseUrl/api/attendance/validate';
  
  // Stats
  static const String dashboardStats = '$baseUrl/api/stats/dashboard';
}