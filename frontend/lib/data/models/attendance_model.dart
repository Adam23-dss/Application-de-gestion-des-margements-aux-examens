import 'package:flutter/material.dart';

class AttendanceModel {
  final int id;
  final int examId;
  final int studentId;
  final int? supervisorId;
  final String status; // 'present', 'absent', 'late', 'excused'
  final DateTime? validationTime;
  final String? validationMethod; // 'manual', 'qr_code', 'nfc'
  final String? notes;
  
  // Champs dérivés
  final String? studentName;
  final String? studentCode;
  
  AttendanceModel({
    required this.id,
    required this.examId,
    required this.studentId,
    this.supervisorId,
    required this.status,
    this.validationTime,
    this.validationMethod,
    this.notes,
    this.studentName,
    this.studentCode,
  });
  
  // Méthode copyWith
  AttendanceModel copyWith({
    int? id,
    int? examId,
    int? studentId,
    int? supervisorId,
    String? status,
    DateTime? validationTime,
    String? validationMethod,
    String? notes,
    String? studentName,
    String? studentCode,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      supervisorId: supervisorId ?? this.supervisorId,
      status: status ?? this.status,
      validationTime: validationTime ?? this.validationTime,
      validationMethod: validationMethod ?? this.validationMethod,
      notes: notes ?? this.notes,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
    );
  }
  
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    DateTime? validationTime;
    if (json['validation_time'] != null) {
      if (json['validation_time'] is String) {
        validationTime = DateTime.parse(json['validation_time']);
      } else if (json['validation_time'] is DateTime) {
        validationTime = json['validation_time'];
      }
    }
    
    return AttendanceModel(
      id: json['id'] ?? 0,
      examId: json['exam_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      supervisorId: json['supervisor_id'],
      status: json['status']?.toString() ?? 'absent',
      validationTime: validationTime,
      validationMethod: json['validation_method']?.toString(),
      notes: json['notes']?.toString(),
      studentName: json['student_name']?.toString(),
      studentCode: json['student_code']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'supervisor_id': supervisorId,
      'status': status,
      'validation_time': validationTime?.toIso8601String(),
      'validation_method': validationMethod,
      'notes': notes,
    };
  }
  
  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Présent';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'En retard';
      case 'excused':
        return 'Excusé';
      default:
        return status;
    }
  }
  
  Color get statusColor {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData get statusIcon {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.medical_services;
      default:
        return Icons.help;
    }
  }
}