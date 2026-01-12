import 'package:flutter/material.dart';

class CourseModel {
  final int id;
  final String code;
  final String name;
  final String? ufr;
  final String? department;
  final int? credits;
  final String? description;
  
  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    this.ufr,
    this.department,
    this.credits,
    this.description,
  });
  
  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ufr: json['ufr']?.toString(),
      department: json['department']?.toString(),
      credits: json['credits'] as int?,
      description: json['description']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'ufr': ufr,
      'department': department,
      'credits': credits,
      'description': description,
    };
  }
  
  String get formattedInfo {
    return '$code - $name';
  }
}