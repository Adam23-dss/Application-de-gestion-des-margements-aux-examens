class ApiEndpoints {
   static const String baseUrl = 'https://application-de-gestion-des-margements.onrender.com';
  
  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String logout = '$baseUrl/api/auth/logout';
  static const String profile = '$baseUrl/api/auth/profile';
  static const String testAuth = '$baseUrl/api/auth/test-auth';
  
  // Exam endpoints
  static const String exams = '$baseUrl/api/exams';
  static String examDetails(int id) => '$exams/$id';
  static String examStudents(int id) => '$exams/$id/students';
  static String startExam(int id) => '$exams/$id/start';
  static String endExam(int id) => '$exams/$id/end';
  
  // Student endpoints
  static const String students = '$baseUrl/api/students';
  static String studentSearch = '$students/search';
  
  // Attendance endpoints
  static const String attendance = '$baseUrl/api/attendance';
  static const String validateAttendance = '$attendance/validate';
  static String examAttendance(int examId) => '$attendance/exam/$examId';
  static String attendanceStats(int examId) => '$attendance/stats/$examId';
  
  // Dashboard endpoints
  static const String dashboardStats = '$baseUrl/api/stats/dashboard';
  
  // Socket.io events
  static const String socketUrl = baseUrl;
}