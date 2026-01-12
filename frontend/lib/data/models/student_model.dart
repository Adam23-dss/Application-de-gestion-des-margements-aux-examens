class StudentModel {
  final int id;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String? email;
  final String ufr;
  final String department;
  final String? promotion;
  final bool isActive;
  
  StudentModel({
    required this.id,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.ufr,
    required this.department,
    this.promotion,
    required this.isActive,
  });
  
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? 0,
      studentCode: json['student_code']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString(),
      ufr: json['ufr']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      promotion: json['promotion']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_code': studentCode,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'ufr': ufr,
      'department': department,
      'promotion': promotion,
      'is_active': isActive,
    };
  }
  
  String get fullName => '$firstName $lastName';
  
  String get formattedInfo {
    return '$studentCode - $fullName ($department)';
  }
}