class ApiEndpoints {
  static const String baseUrl = 'https://application-de-gestion-des-margements.onrender.com';
  
  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String logout = '$baseUrl/api/auth/logout';
  static const String verifyToken = '$baseUrl/api/auth/verify-token';
  
  // Exam endpoints
  static const String exams = '$baseUrl/api/exams';
  static const String examDetails = '$baseUrl/api/exams';
  
  // Attendance endpoints
  static const String attendance = '$baseUrl/api/attendance';
  static const String validateAttendance = '$baseUrl/api/attendance/validate';
  
  // Student endpoints
  static const String students = '$baseUrl/api/students';
  

  // Dashboard endpoints
  static const String dashboardStats = '$baseUrl/api/dashboard/stats';
  static const String dashboardExams = '$baseUrl/api/dashboard/exams';
}