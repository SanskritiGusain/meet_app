import 'package:intl/intl.dart';

class Demo {
  final String? id;
  final String title;
  final String link;
  final String startTime;
  final String endTime;
  final String demoDate;
  final DateTime createdAt;

  Demo({
    this.id,
    required this.title,
    required this.link,
    required this.startTime,
    required this.endTime,
    required this.demoDate,
    required this.createdAt,
  });

  // Alternative constructor for backward compatibility with createdOn string
  Demo.withCreatedOn({
    this.id,
    required this.title,
    required this.link,
    required this.startTime,
    required this.endTime,
    required this.demoDate,
    required String createdOn,
  }) : createdAt = DateTime.tryParse(createdOn) ?? DateTime.now();

  factory Demo.fromJson(Map<String, dynamic> json) {
    return Demo(
      id: json['id'] as String?,
      title: (json['title'] ?? 'Unnamed Demo') as String,
      link: json['link'] ?? '',
      startTime: json['startTime'] ?? '00:00',
      endTime: json['endTime'] ?? '23:59',
      demoDate: _formatDemoDate(json['demoDate'] ?? ''), // Format the date here
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // Static method to format demo date to dd/MM/yyyy format
  static String _formatDemoDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      DateTime parsedDate;
      
      // Check if it's already in dd/MM/yyyy format
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(dateString)) {
        return dateString; // Already in correct format
      }
      
      // Try parsing common date formats
      try {
        parsedDate = DateFormat('yyyy-MM-dd').parse(dateString);
      } catch (e) {
        try {
          parsedDate = DateFormat('dd MMM yyyy').parse(dateString);
        } catch (e) {
          try {
            parsedDate = DateFormat('MM/dd/yyyy').parse(dateString);
          } catch (e) {
            try {
              parsedDate = DateTime.parse(dateString);
            } catch (e) {
              // If all parsing fails, return original string
              return dateString;
            }
          }
        }
      }
      
      // Format to dd/MM/yyyy (e.g., "01/06/2025")
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      print('Date formatting failed: $e');
      return dateString; // Return original if formatting fails
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'link': link,
      'startTime': startTime,
      'endTime': endTime,
      'demoDate': demoDate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Getter for formatted creation date (dd/MM/yyyy format)
  String get createdOn {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  // Getter for formatted creation date with time (dd/MM/yyyy hh:mm a format)
  String get createdOnWithTime {
    return DateFormat('dd/MM/yyyy hh:mm a').format(createdAt);
  }

  // Getter for display name (fallback logic)
  String get displayName {
    return title.isNotEmpty ? title : 'Unnamed Demo';
  }

  // Getter for formatted demo date (ensures consistent format)
  String get formattedDemoDate {
    return _formatDemoDate(demoDate);
  }

  // Method to create a copy with updated fields
  Demo copyWith({
    String? id,
    String? title,
    String? link,
    String? startTime,
    String? endTime,
    String? demoDate,
    DateTime? createdAt,
  }) {
    return Demo(
      id: id ?? this.id,
      title: title ?? this.title,
      link: link ?? this.link,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      demoDate: demoDate ?? this.demoDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Demo(id: $id, title: $title, demoDate: $demoDate, startTime: $startTime, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Demo &&
        other.id == id &&
        other.title == title &&
        other.link == link &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.demoDate == demoDate &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      link,
      startTime,
      endTime,
      demoDate,
      createdAt,
    );
  }
}