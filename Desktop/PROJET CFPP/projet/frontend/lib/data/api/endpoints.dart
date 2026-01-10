class Endpoints {
  // Auth
  static const String login = "/api/auth/login";
  static const String refresh = "/api/auth/refresh";
  static const String profile = "/api/auth/profile";

  // Exams
  static const String exams = "/api/exams"; // GET
  static String examStudents(int examId) => "/api/exams/$examId/students";

  // Attendance
  static const String validateAttendance = "/api/attendance/validate";
  static String attendanceByExam(int examId) => "/api/attendance/exam/$examId";
}