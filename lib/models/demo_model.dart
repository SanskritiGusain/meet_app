class Demo {
  final String? id;
  final String title;
  final String link;
  final String startTime;
  final String endTime;
  final String demoDate;
  final String createdOn;

  Demo({
    this.id,
    required this.title,
    required this.link,
    required this.startTime,
    required this.endTime,
    required this.demoDate,
    required this.createdOn,
  });

  factory Demo.fromJson(Map<String, dynamic> json) {
    return Demo(
      id: json['id'],
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      demoDate: json['demoDate'] ?? '',
      createdOn: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'link': link,
      'startTime': startTime,
      'endTime': endTime,
      'demoDate': demoDate,
      'createdAt': createdOn,
    };
  }
}
