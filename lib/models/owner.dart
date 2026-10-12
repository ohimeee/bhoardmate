class Owner {
  final String id;
  final String name;
  final String email;
  final String contactNumber;

  const Owner({
    required this.id,
    required this.name,
    required this.email,
    required this.contactNumber,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'contactNumber': contactNumber};
  }

  factory Owner.fromMap(String id, Map<String, dynamic> map) {
    return Owner(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String,
      contactNumber: map['contactNumber'] as String,
    );
  }
}
