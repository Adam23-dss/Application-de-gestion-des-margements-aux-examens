import 'package:frontend1/core/constants/user_roles.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String token;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user']['_id'] ?? json['user']['id'] ?? '',
      name: json['user']['name'] ?? '',
      email: json['user']['email'] ?? '',
      role: json['user']['role'] ?? '',
      token: json['token'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      },
      'token': token,
    };
  }
  
  bool get isAdmin => role == UserRole.admin;
  bool get isSurveillant => role == UserRole.surveillant;
}