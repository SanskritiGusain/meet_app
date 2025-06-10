import 'package:intl/intl.dart';

// Student Model
class Student {
  final String? id;
  final String batchId;
  final String loginId;
  final String name;
  final String password;
  final String createdAt;
  final String updatedAt;

  Student({
    this.id,
    required this.batchId,
    required this.loginId,
    required this.name,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      batchId: json['batchId'] ?? '',
      loginId: json['loginId'] ?? '',
      name: json['name'] ?? 'Unknown Student',
      password: json['password'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String get formattedCreatedAt {
    try {
      final dateTime = DateTime.parse(createdAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }
}