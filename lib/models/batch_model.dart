import 'package:intl/intl.dart';

class Batch {
  final String? id;
  final String batchName;
  final String? batchLink;
  final String? batchDate;
  final String startTime;
  final String endTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? name; // URL-friendly name

  Batch({
    this.id,
    required this.batchName,
    this.batchLink,
    this.batchDate,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.updatedAt,
    this.name,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String?,
      // Handle both 'batchName' and 'title' fields
      batchName: (json['batchName'] ?? json['title'] ?? 'Unnamed Batch') as String,
      // Handle both 'batchLink' and 'link' fields
      batchLink: json['batchLink'] ?? json['link'],
      batchDate: json['batchDate'] as String?,
      startTime: json['startTime'] ?? '00:00',
      endTime: json['endTime'] ?? '23:59',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'batchName': batchName,
      'batchLink': batchLink,
      'batchDate': batchDate,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
    };
  }

  // Helper method to get formatted creation date in IST
  String get createdOn {
    // Convert UTC to IST (UTC+5:30)
    final istDate = createdAt.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM yyyy - hh:mm a').format(istDate);
  }

  // Helper method to check if batch has a valid meeting link
  bool get hasValidLink {
    return batchLink != null && batchLink!.isNotEmpty;
  }

  // Helper method to get display name (prefer batchName over title)
  String get displayName {
    return batchName.isNotEmpty ? batchName : (name ?? 'Unnamed Batch');
  }
}