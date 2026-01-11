class Student {
  final String id;
  final String code;
  final String firstName;
  final String lastName;
  final String email;
  final String program;
  final int year;
  final String? phone;

  Student({
    required this.id,
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.program,
    required this.year,
    this.phone,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      program: json['program'] ?? '',
      year: json['year'] ?? 0,
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'program': program,
      'year': year,
      'phone': phone,
    };
  }

  String get fullName => '$firstName $lastName';
}