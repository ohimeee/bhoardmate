class Concern {
  final int? id;
  final String roomId;
  final String title;
  final String description;
  final String status;
  final String createdAt;

  const Concern({
    this.id,
    required this.roomId,
    required this.title,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Concern.fromMap(Map<String, dynamic> map) {
    return Concern(
      id: map['id'] as int?,
      roomId: map['roomId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      status: map['status'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  Concern copyWith({int? id, String? status}) {
    return Concern(
      id: id ?? this.id,
      roomId: roomId,
      title: title,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
