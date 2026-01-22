import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:frontend1/core/constants/app_constants.dart';

class QRCodeData {
  final String version;
  final int studentId;
  final String studentCode;
  final String fullName;
  final String? email;
  final int examId;
  final String examName;
  final DateTime examDate;
  final String examTime;
  final int? courseId;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final String hash;

  QRCodeData({
    required this.version,
    required this.studentId,
    required this.studentCode,
    required this.fullName,
    this.email,
    required this.examId,
    required this.examName,
    required this.examDate,
    required this.examTime,
    this.courseId,
    required this.generatedAt,
    required this.expiresAt,
    required this.hash,
  });

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      version: json['version'] ?? '1.0',
      studentId: int.parse(json['student_id']?.toString() ?? '0'),
      studentCode: json['student_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      examId: int.parse(json['exam_id']?.toString() ?? '0'),
      examName: json['exam_name']?.toString() ?? '',
      examDate: DateTime.parse(json['exam_date']?.toString() ?? DateTime.now().toIso8601String()),
      examTime: json['exam_time']?.toString() ?? '',
      courseId: json['course_id'] != null ? int.parse(json['course_id'].toString()) : null,
      generatedAt: DateTime.parse(json['generated_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().add(Duration(minutes: 30)).toIso8601String()),
      hash: json['hash']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'student_id': studentId,
      'student_code': studentCode,
      'full_name': fullName,
      'email': email,
      'exam_id': examId,
      'exam_name': examName,
      'exam_date': examDate.toIso8601String(),
      'exam_time': examTime,
      'course_id': courseId,
      'generated_at': generatedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'hash': hash,
    };
  }

  String toQRString() {
    return jsonEncode(toJson());
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => _verifyHash();

  bool _verifyHash() {
    try {
      final secret = AppConstants.qrSecret;
      final hashInput = '$studentId:$examId:${generatedAt.toIso8601String()}:$secret';
      final calculatedHash = sha256.convert(utf8.encode(hashInput)).toString();
      return hash == calculatedHash;
    } catch (e) {
      return false;
    }
  }

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  @override
  String toString() {
    return 'QRCodeData(student: $fullName ($studentCode), exam: $examName, expires: ${expiresAt.toIso8601String()})';
  }
}

class QRCodeResponse {
  final QRCodeData qrData;
  final String qrString;
  final QRStudent student;
  final QRExam exam;
  final DateTime expiresAt;

  QRCodeResponse({
    required this.qrData,
    required this.qrString,
    required this.student,
    required this.exam,
    required this.expiresAt,
  });

  factory QRCodeResponse.fromJson(Map<String, dynamic> json) {
    return QRCodeResponse(
      qrData: QRCodeData.fromJson(json['qr_data'] ?? {}),
      qrString: json['qr_string']?.toString() ?? '',
      student: QRStudent.fromJson(json['student'] ?? {}),
      exam: QRExam.fromJson(json['exam'] ?? {}),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().add(Duration(minutes: 30)).toIso8601String()),
    );
  }
}

class QRStudent {
  final int id;
  final String code;
  final String name;

  QRStudent({
    required this.id,
    required this.code,
    required this.name,
  });

  factory QRStudent.fromJson(Map<String, dynamic> json) {
    return QRStudent(
      id: int.parse(json['id']?.toString() ?? '0'),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class QRExam {
  final int id;
  final String name;
  final DateTime date;

  QRExam({
    required this.id,
    required this.name,
    required this.date,
  });

  factory QRExam.fromJson(Map<String, dynamic> json) {
    return QRExam(
      id: int.parse(json['id']?.toString() ?? '0'),
      name: json['name']?.toString() ?? '',
      date: DateTime.parse(json['date']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

class QRVerificationResult {
  final bool isValid;
  final String? message;
  final String? error;
  final QRStudent? student;
  final QRCodeData? qrData;
  final bool canValidate;
  final bool alreadyAttended;
  final String? attendanceStatus;
  final DateTime? validationTime;

  QRVerificationResult({
    required this.isValid,
    this.message,
    this.error,
    this.student,
    this.qrData,
    required this.canValidate,
    required this.alreadyAttended,
    this.attendanceStatus,
    this.validationTime,
  });

  factory QRVerificationResult.fromJson(Map<String, dynamic> json) {
    return QRVerificationResult(
      isValid: json['is_valid'] ?? false,
      message: json['message']?.toString(),
      error: json['error']?.toString(),
      student: json['student'] != null ? QRStudent.fromJson(json['student']) : null,
      qrData: json['qr_data'] != null ? QRCodeData.fromJson(json['qr_data']) : null,
      canValidate: json['can_validate'] ?? false,
      alreadyAttended: json['already_attended'] ?? false,
      attendanceStatus: json['attendance_status']?.toString(),
      validationTime: json['validation_time'] != null 
          ? DateTime.parse(json['validation_time'])
          : null,
    );
  }
}