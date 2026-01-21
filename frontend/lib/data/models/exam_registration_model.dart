// data/models/exam_registration_model.dart
class ExamRegistration {
  final int id;
  final int examId;
  final int studentId;
  final DateTime registrationDate;
  final bool isConfirmed;
  final String? notes;
  
  ExamRegistration({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.registrationDate,
    this.isConfirmed = true,
    this.notes,
  });
  
  factory ExamRegistration.fromJson(Map<String, dynamic> json) {
    return ExamRegistration(
      id: json['id'] ?? 0,
      examId: json['exam_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      registrationDate: json['registration_date'] != null 
          ? DateTime.parse(json['registration_date'].toString())
          : DateTime.now(),
      isConfirmed: json['is_confirmed'] ?? true,
      notes: json['notes']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'registration_date': registrationDate.toIso8601String(),
      'is_confirmed': isConfirmed,
      'notes': notes,
    };
  }
}

class ExamRegistrationRequest {
  final int examId;
  final int studentId;
  final String? notes;
  
  ExamRegistrationRequest({
    required this.examId,
    required this.studentId,
    this.notes,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'exam_id': examId,
      'student_id': studentId,
      if (notes != null) 'notes': notes,
    };
  }
}