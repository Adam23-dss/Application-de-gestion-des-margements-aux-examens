// lib/core/constants/api_endpoints.dart
class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://application-de-gestion-des-margements.onrender.com/api';
  
  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String profile = '$baseUrl/auth/profile';
  static const String testAuth = '$baseUrl/auth/test-auth';

  // Users
  static const String users = '$baseUrl/auth/users';
  static String userDetails(int id) => '$users/$id';
  static String userRole(String role) => '$users/role/$role';
  static const String createUser = '$baseUrl/auth/register';
  static String updateUser(int id) => '$users/$id';
  static String deleteUser(int id) => '$users/$id/delete';
  static String changePassword(int id) => '$users/$id/change-password';
  
  // Exams
  static const String exams = '$baseUrl/exams';
  static String examDetails(int id) => '$exams/$id';
  static String examStudents(int id) => '$exams/$id/students';
  static String startExam(int id) => '$exams/$id/start';
  static String endExam(int id) => '$exams/$id/end';
  
  // Attendance
  static const String attendance = '$baseUrl/attendance';
  static const String validateAttendance = '$attendance/validate';
  static String examAttendance(int examId) => '$attendance/exam/$examId';
  static String attendanceStats(int examId) => '$attendance/stats/$examId';
  
  // Students
  static const String students = '$baseUrl/students';
  static const String searchStudents = '$students/search';
  
  // Courses
  static const String courses = '$baseUrl/courses';
  static String courseDetails(int id) => '$courses/$id';
  static const String searchCourses = '$courses/search';
  
  // Rooms
  static const String rooms = '$baseUrl/rooms';
  static const String availableRooms = '$rooms/available';
  
  // Stats - IMPORTANT: Corrigé ici !
  static const String stats = '$baseUrl/stats';
  static const String dashboardStats = '$stats/dashboard';
  static String dailyStats(String date) => '$stats/daily/$date';
  static String examStats(int examId) => '$stats/exam/$examId';
  
  // Exports
  static const String exports = '$baseUrl/exports';
  static String exportAttendancePDF(int id) => '$exports/attendance/$id/pdf';
  static String exportAttendanceExcel(int id) => '$exports/attendance/$id/excel';

  // QR Codes (intégrés dans les routes exam)
  static String generateQRCode(int examId) => '$baseUrl/exams/$examId/generate-qr';
  static String generateBulkQRCodes(int examId) => '$baseUrl/exams/$examId/generate-bulk-qr';
  static String verifyQRCode(int examId) => '$baseUrl/exams/$examId/verify-qr';
  static String validateFromQRCode(int examId) => '$baseUrl/exams/$examId/validate-qr';
  static String qrCodeHistory(int examId) => '$baseUrl/exams/$examId/qr-history';
  static String activeQRCodes(int examId) => '$baseUrl/exams/$examId/active-qr-codes';
  
}

class PaginationData {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  
  PaginationData({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });
  
  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 20,
    );
  }
}