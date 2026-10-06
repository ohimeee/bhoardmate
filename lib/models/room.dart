class Room {
  final String id;
  final String accessCode;
  final double monthlyRent;
  final String? boarderName;
  final String? contactNumber;
  final int? age;
  final String? emergencyContactName;
  final String? emergencyContactNumber;

  const Room({
    required this.id,
    required this.accessCode,
    required this.monthlyRent,
    this.boarderName,
    this.contactNumber,
    this.age,
    this.emergencyContactName,
    this.emergencyContactNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accessCode': accessCode,
      'monthlyRent': monthlyRent,
      'boarderName': boarderName,
      'contactNumber': contactNumber,
      'age': age,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as String,
      accessCode: map['accessCode'] as String,
      monthlyRent: (map['monthlyRent'] as num).toDouble(),
      boarderName: map['boarderName'] as String?,
      contactNumber: map['contactNumber'] as String?,
      age: map['age'] as int?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactNumber: map['emergencyContactNumber'] as String?,
    );
  }

  // used by resetAccessCode (boarder fields go back to null)
  Room copyWith({String? accessCode}) {
    return Room(
      id: id,
      accessCode: accessCode ?? this.accessCode,
      monthlyRent: monthlyRent,
      boarderName: boarderName,
      contactNumber: contactNumber,
      age: age,
      emergencyContactName: emergencyContactName,
      emergencyContactNumber: emergencyContactNumber,
    );
  }
}
