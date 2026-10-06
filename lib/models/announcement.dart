class Announcement {
  final int? id;
  final String title;
  final String message;
  final String? eventDate;
  final String createdAt;

  const Announcement({
    this.id,
    required this.title,
    required this.message,
    this.eventDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'eventDate': eventDate,
      'createdAt': createdAt,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      eventDate: map['eventDate'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }
}
