class Payment {
  final int? id;
  final String roomId;
  final String month;
  final double roomRent;
  final double electricity;
  final double water;
  final String dueDate;
  final bool isPaid;
  final String? paidDate;

  const Payment({
    this.id,
    required this.roomId,
    required this.month,
    required this.roomRent,
    required this.electricity,
    required this.water,
    required this.dueDate,
    this.isPaid = false,
    this.paidDate,
  });

  double get total => roomRent + electricity + water;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'month': month,
      'roomRent': roomRent,
      'electricity': electricity,
      'water': water,
      'dueDate': dueDate,
      'isPaid': isPaid ? 1 : 0,
      'paidDate': paidDate,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      roomId: map['roomId'] as String,
      month: map['month'] as String,
      roomRent: (map['roomRent'] as num).toDouble(),
      electricity: (map['electricity'] as num).toDouble(),
      water: (map['water'] as num).toDouble(),
      dueDate: map['dueDate'] as String,
      isPaid: map['isPaid'] == 1,
      paidDate: map['paidDate'] as String?,
    );
  }

  // paidDate is set to null when marking unpaid, so it needs its own flag
  Payment copyWith({int? id, bool? isPaid, String? paidDate}) {
    return Payment(
      id: id ?? this.id,
      roomId: roomId,
      month: month,
      roomRent: roomRent,
      electricity: electricity,
      water: water,
      dueDate: dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: (isPaid ?? this.isPaid) ? (paidDate ?? this.paidDate) : null,
    );
  }
}
