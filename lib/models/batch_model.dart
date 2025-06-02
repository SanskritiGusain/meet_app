class Batch {
  final String? id;
  final String batchName;
  final String batchLink;
  final String batchDate;
  final String startTime;
  final String endTime;
  final String createdOn;

  Batch({
    this.id,
    required this.batchName,
    required this.batchLink,
    required this.batchDate,
    required this.startTime,
    required this.endTime,
    required this.createdOn,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id']?.toString(),
      batchName: json['batchName'] ?? '',
      batchLink: json['batchLink'] ?? '',
      batchDate: json['batchDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      createdOn: json['createdAt'] ?? '',
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
      'createdAt': createdOn,
    };
  }
}