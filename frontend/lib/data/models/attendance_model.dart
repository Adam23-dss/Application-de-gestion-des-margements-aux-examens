class Attendance {
  final String id;
  final String studentId;
  final String studentCode;
  final String studentName;
  final String examId;
  final String examName;
  final String status; // 'present', 'absent', 'late', 'excused'
  final String? comment;
  final DateTime validatedAt;
  final String validatedBy;

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.examId,
    required this.examName,
    required this.status,
    this.comment,
    required this.validatedAt,
    required this.validatedBy,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentCode: json['studentCode'] ?? '',
      studentName: json['studentName'] ?? '',
      examId: json['examId'] ?? '',
      examName: json['examName'] ?? '',
      status: json['status'] ?? 'absent',
      comment: json['comment'],
      validatedAt: DateTime.parse(json['validatedAt']),
      validatedBy: json['validatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentCode': studentCode,
      'studentName': studentName,
      'examId': examId,
      'examName': examName,
      'status': status,
      'comment': comment,
      'validatedAt': validatedAt.toIso8601String(),
      'validatedBy': validatedBy,
    };
  }
}