class Holiday {
  final DateTime date;
  final String localName;
  final String name;

  const Holiday({
    required this.date,
    required this.localName,
    required this.name,
  });

  // Nager.Date: {"date": "2026-12-25", "localName": "...", "name": "..."}
  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: DateTime.parse(json['date'] as String),
      localName: json['localName'] as String,
      name: json['name'] as String,
    );
  }
}
