import 'package:flutter/material.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';

class ExamModel {
  final int id;
  final int? courseId;
  final String name;
  final String? description;
  final DateTime examDate;
  final String startTime;
  final String endTime;
  final int? roomId;
  final int? supervisorId;
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled'
  final int totalStudents;

  // Champs dérivés (peuvent être null si non inclus dans la réponse)
  final String? courseName;
  final String? roomName;
  final int? presentCount;

  ExamModel({
    required this.id,
    this.courseId,
    required this.name,
    this.description,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    this.roomId,
    this.supervisorId,
    required this.status,
    required this.totalStudents,
    this.courseName,
    this.roomName,
    this.presentCount,
  });

  // Méthode copyWith
  ExamModel copyWith({
    int? id,
    int? courseId,
    String? name,
    String? description,
    DateTime? examDate,
    String? startTime,
    String? endTime,
    int? roomId,
    int? supervisorId,
    String? status,
    int? totalStudents,
    String? courseName,
    String? roomName,
    int? presentCount,
  }) {
    return ExamModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      description: description ?? this.description,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomId: roomId ?? this.roomId,
      supervisorId: supervisorId ?? this.supervisorId,
      status: status ?? this.status,
      totalStudents: totalStudents ?? this.totalStudents,
      courseName: courseName ?? this.courseName,
      roomName: roomName ?? this.roomName,
      presentCount: presentCount ?? this.presentCount,
    );
  }

  // Factory method amélioré pour gérer les données partielles
  factory ExamModel.fromJson(Map<String, dynamic> json) {
    print('📄 Parsing exam JSON (keys: ${json.keys.toList()})');

    // 1. Parser l'ID
    final id = json['id'] ?? json['_id'] ?? 0;

    // 2. Parser la date - gérer différents formats
    DateTime examDate;
    try {
      if (json['exam_date'] is String) {
        examDate = DateTime.parse(json['exam_date']);
      } else if (json['exam_date'] is DateTime) {
        examDate = json['exam_date'];
      } else {
        examDate = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing exam_date: $e, using current date');
      examDate = DateTime.now();
    }

    // 3. Parser le nom (peut être manquant dans les réponses partielles)
    final name = json['name']?.toString() ?? 'Examen sans nom';

    // 4. Parser le statut (par défaut 'scheduled')
    final status = json['status']?.toString() ?? 'scheduled';

    // 5. Parser les champs optionnels qui peuvent être null dans les réponses partielles
    return ExamModel(
      id: id,
      courseId: json['course_id'],
      name: name,
      description: json['description']?.toString(),
      examDate: examDate,
      startTime: json['start_time']?.toString() ?? '09:00',
      endTime: json['end_time']?.toString() ?? '12:00',
      roomId: json['room_id'],
      supervisorId: json['supervisor_id'],
      status: status,
      totalStudents: (json['total_students'] ?? 0) as int,
      courseName:
          json['course_name']?.toString() ??
          json['course']?['name']?.toString(),
      roomName:
          json['room_name']?.toString() ?? json['room']?['name']?.toString(),
      presentCount: json['present_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'description': description,
      'exam_date': examDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'room_id': roomId,
      'supervisor_id': supervisorId,
      'status': status,
      'total_students': totalStudents,
      'course_name': courseName,
      'room_name': roomName,
      'present_count': presentCount,
    };
  }

  // Getters utiles
  double get attendancePercentage {
    if (presentCount == null || totalStudents == 0) return 0;
    return (presentCount! / totalStudents * 100);
  }

  String get formattedDate {
    final day = examDate.day.toString().padLeft(2, '0');
    final month = examDate.month.toString().padLeft(2, '0');
    final year = examDate.year;
    return '$day/$month/$year';
  }

  String get formattedTime {
    return '$startTime - $endTime';
  }

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return 'Programmé';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get isActive => status == 'scheduled' || status == 'in_progress';
  bool get isToday {
    final now = DateTime.now();
    return examDate.year == now.year &&
        examDate.month == now.month &&
        examDate.day == now.day;
  }

  bool get isUpcoming =>
      examDate.isAfter(DateTime.now()) && status != 'cancelled';
  bool get isPast => examDate.isBefore(DateTime.now()) && status != 'cancelled';
}

// Modèle pour la réponse paginée
class ExamResponse {
  final List<ExamModel> exams;
  final PaginationData pagination;

  ExamResponse({required this.exams, required this.pagination});

  factory ExamResponse.fromJson(Map<String, dynamic> json) {
    try {
      List<ExamModel> examsList = [];
      PaginationData pagination;

      // Essayer différentes structures
      if (json.containsKey('exams')) {
        // Structure {exams: [...], pagination: {...}}
        examsList = (json['exams'] as List? ?? [])
            .map((examJson) => ExamModel.fromJson(examJson))
            .toList();
        pagination = PaginationData.fromJson(json['pagination'] ?? {});
      } else if (json is List) {
        // Structure directement une liste
        examsList = (json as List)
            .map((examJson) => ExamModel.fromJson(examJson))
            .toList();
        pagination = PaginationData(
          currentPage: 1,
          totalPages: 1,
          totalItems: examsList.length,
          itemsPerPage: examsList.length,
        );
      } else {
        // Structure inconnue
        print('⚠️ Unknown JSON structure in ExamResponse.fromJson');
        examsList = [];
        pagination = PaginationData(
          currentPage: 1,
          totalPages: 1,
          totalItems: 0,
          itemsPerPage: 20,
        );
      }

      return ExamResponse(exams: examsList, pagination: pagination);
    } catch (e) {
      print('❌ Error in ExamResponse.fromJson: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
}
