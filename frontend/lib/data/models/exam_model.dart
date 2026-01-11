class Exam {
  final String id;
  final String name;
  final String course;
  final DateTime date;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final int totalStudents;
  final int presentStudents;
  final int absentStudents;
  final String? supervisorId;

  Exam({
    required this.id,
    required this.name,
    required this.course,
    required this.date,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.totalStudents,
    required this.presentStudents,
    required this.absentStudents,
    this.supervisorId,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      course: json['course'] ?? '',
      date: DateTime.parse(json['date']),
      room: json['room'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalStudents: json['totalStudents'] ?? 0,
      presentStudents: json['presentStudents'] ?? 0,
      absentStudents: json['absentStudents'] ?? 0,
      supervisorId: json['supervisorId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'course': course,
      'date': date.toIso8601String(),
      'room': room,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalStudents': totalStudents,
      'presentStudents': presentStudents,
      'absentStudents': absentStudents,
      'supervisorId': supervisorId,
    };
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}