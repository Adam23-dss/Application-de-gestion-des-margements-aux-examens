class DashboardStats {
  final int totalUsers;
  final int totalStudents;
  final int todayExams;
  final int activeExams;
  final int todayPresent;
  final int monthlyExams;

  DashboardStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.todayExams,
    required this.activeExams,
    required this.todayPresent,
    required this.monthlyExams,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalStudents: json['totalStudents'] ?? 0,
      todayExams: json['todayExams'] ?? 0,
      activeExams: json['activeExams'] ?? 0,
      todayPresent: json['todayPresent'] ?? 0,
      monthlyExams: json['monthlyExams'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalStudents': totalStudents,
      'todayExams': todayExams,
      'activeExams': activeExams,
      'todayPresent': todayPresent,
      'monthlyExams': monthlyExams,
    };
  }
}

class DailyStats {
  final String date;
  final List<ExamDailyStat> exams;
  final DailyTotals totals;
  final String attendanceRate;

  DailyStats({
    required this.date,
    required this.exams,
    required this.totals,
    required this.attendanceRate,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    final exams = (json['exams'] as List? ?? [])
        .map((e) => ExamDailyStat.fromJson(e))
        .toList();

    final totals = DailyTotals.fromJson(json['totals'] ?? {});

    return DailyStats(
      date: json['date']?.toString() ?? '',
      exams: exams,
      totals: totals,
      attendanceRate: json['attendanceRate']?.toString() ?? '0.0',
    );
  }
}

class ExamDailyStat {
  final int id;
  final String examName;
  final String examDate;
  final String startTime;
  final String endTime;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;

  ExamDailyStat({
    required this.id,
    required this.examName,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
  });

  factory ExamDailyStat.fromJson(Map<String, dynamic> json) {
    return ExamDailyStat(
      id: json['id'] ?? 0,
      examName: json['exam_name']?.toString() ?? '',
      examDate: json['exam_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      totalStudents: json['total_students'] ?? 0,
      presentCount: json['present_count'] ?? 0,
      absentCount: json['absent_count'] ?? 0,
      lateCount: json['late_count'] ?? 0,
      excusedCount: json['excused_count'] ?? 0,
    );
  }
}

class DailyTotals {
  final int totalStudents;
  final int present;
  final int absent;
  final int late;
  final int excused;

  DailyTotals({
    required this.totalStudents,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  factory DailyTotals.fromJson(Map<String, dynamic> json) {
    return DailyTotals(
      totalStudents: json['totalStudents'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      late: json['late'] ?? 0,
      excused: json['excused'] ?? 0,
    );
  }
}
