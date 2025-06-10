import 'package:intl/intl.dart';

class Guest {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String createdOnWithTime;
  final DateTime createdAt;

  Guest({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.createdOnWithTime,
    required this.createdAt,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'].toString())
        : DateTime.now();
    
    // Convert UTC to IST (UTC + 5:30)
    DateTime istDate = parsedDate.add(const Duration(hours: 5, minutes: 30));
    
    // Format the IST date as "28 Jun 2025 - 02:14 PM"
    String formattedDate = DateFormat('dd MMM yyyy - hh:mm a').format(istDate);
    
    return Guest(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Guest',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      createdOnWithTime: json['createdOnWithTime']?.toString() ?? formattedDate,
      createdAt: istDate, // Store IST date instead of UTC
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'createdOnWithTime': createdOnWithTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}