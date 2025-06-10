import 'package:intl/intl.dart';

class Teacher {
  final String loginId;
  final String name;
  final String password;
  final String createdAt;

  Teacher({
    required this.loginId,
    required this.name,
    required this.password,
    required this.createdAt,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      loginId: json['loginId'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}