class Owner {
  final int id;
  final String name;
  final String username;
  final String password;
  final String contactNumber;

  const Owner({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.contactNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'contactNumber': contactNumber,
    };
  }

  factory Owner.fromMap(Map<String, dynamic> map) {
    return Owner(
      id: map['id'] as int,
      name: map['name'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      contactNumber: map['contactNumber'] as String,
    );
  }
}
