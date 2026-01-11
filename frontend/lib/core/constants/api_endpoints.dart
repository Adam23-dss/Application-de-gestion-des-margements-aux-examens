class ApiEndpoints {
  static const String baseUrl = 'http://localhost:5000';
  static const String wsUrl = 'ws://localhost:5000';
  
  // Authentication
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String profile = '$baseUrl/api/auth/profile';
  static const String refresh = '$baseUrl/api/auth/refresh';
  
  // Students
  static const String students = '$baseUrl/api/students';
  static String studentByCode(String code) => '$students/$code';
  
  // Exams
  static const String exams = '$baseUrl/api/exams';
  static String examStudents(String id) => '$exams/$id/students';
  
  // Attendance
  static const String attendance = '$baseUrl/api/attendance';
  static const String validateAttendance = '$attendance/validate';
  static String examAttendance(String id) => '$attendance/exam/$id';
  
  // Statistics
  static const String stats = '$baseUrl/api/stats';
  static String examStats(String id) => '$stats/exam/$id';
  static String dailyStats(String date) => '$stats/daily/$date';
  
  // Export
  static const String export = '$baseUrl/api/exports';
  static String exportPdf(String id) => '$export/attendance/$id/pdf';
  static String exportExcel(String id) => '$export/attendance/$id/excel';
}