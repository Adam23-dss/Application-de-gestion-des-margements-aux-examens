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
    // Fonction pour convertir en int (gère String et int)
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.tryParse(value) ?? 0;
        } catch (e) {
          print('⚠️ Error parsing int from string: $value');
          return 0;
        }
      }
      if (value is double) return value.toInt();
      return 0;
    }

    return DashboardStats(
      totalUsers: parseInt(json['totalUsers']),
      totalStudents: parseInt(json['totalStudents']),
      todayExams: parseInt(json['todayExams']),
      activeExams: parseInt(json['activeExams']),
      todayPresent: parseInt(json['todayPresent']),
      monthlyExams: parseInt(json['monthlyExams']),
    );
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'totalUsers': totalUsers,
  //     'totalStudents': totalStudents,
  //     'todayExams': todayExams,
  //     'activeExams': activeExams,
  //     'todayPresent': todayPresent,
  //     'monthlyExams': monthlyExams,
  //   };
  // }
}

class DailyStats {
  final String date;
  final List<ExamStats> exams;
  final DailyTotals totals;
  DailyStats({required this.date, required this.exams, required this.totals});

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    // Conversion sûre pour la date
    String parseDate(dynamic value) {
      if (value == null) return DateTime.now().toIso8601String().split('T')[0];
      if (value is String) return value;
      return value.toString();
    }

    return DailyStats(
      date: parseDate(json['date']),
      totals: DailyTotals.fromJson(json['totals'] ?? {}),
      exams: (json['exams'] as List? ?? [])
          .map((examJson) => ExamStats.fromJson(examJson))
          .toList(),
    );
  }
}

class DailyTotals {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final double attendanceRate;

  DailyTotals({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.attendanceRate,
  });

  factory DailyTotals.fromJson(Map<String, dynamic> json) {
    // Fonction de conversion générique
    int parseInt(dynamic value) =>
        (value is int) ? value : (int.tryParse(value?.toString() ?? '0') ?? 0);
    double parseDouble(dynamic value) => (value is double)
        ? value
        : (double.tryParse(value?.toString() ?? '0.0') ?? 0.0);

    return DailyTotals(
      total: parseInt(json['total']),
      present: parseInt(json['present']),
      absent: parseInt(json['absent']),
      late: parseInt(json['late']),
      excused: parseInt(json['excused']),
      attendanceRate: parseDouble(json['attendance_rate']),
    );
  }
}

class ExamStats {
  final int id;
  final String examName;
  final String startTime;
  final String endTime;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendanceRate;

  ExamStats({
    required this.id,
    required this.examName,
    required this.startTime,
    required this.endTime,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendanceRate,
  });

  factory ExamStats.fromJson(Map<String, dynamic> json) {
    return ExamStats(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      examName: json['exam_name']?.toString() ?? 'Examen',
      totalStudents:
          int.tryParse(json['total_students']?.toString() ?? '0') ?? 0,
      presentCount: int.tryParse(json['present_count']?.toString() ?? '0') ?? 0,
      startTime: json['start_time']?.toString() ?? '09:00',
      endTime: json['end_time']?.toString() ?? '12:00',
      absentCount: int.tryParse(json['absent_count']?.toString() ?? '0') ?? 0,
      lateCount: int.tryParse(json['late_count']?.toString() ?? '0') ?? 0,
      excusedCount: int.tryParse(json['excused_count']?.toString() ?? '0') ?? 0,
      attendanceRate: (json['attendance_rate'] is double)
          ? json['attendance_rate']
          : (double.tryParse(json['attendance_rate']?.toString() ?? '0.0') ??
                0.0),
    );
  }
}
