import 'package:intl/intl.dart';

class Attendance {
  final String id;
  final String studentId;
  final String batchId;
  final String studentName;
  final String? loginId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.batchId,
    required this.studentName,
    this.loginId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      batchId: json['batchId'] ?? '',
      studentName: json['studentName'] ?? '',
      loginId: json['students']?['loginId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': studentId,
      'batchId': batchId,
      'studentName': studentName,
      'loginId': loginId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}