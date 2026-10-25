class Payment {
  final String? id;
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

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // '2026-10' -> 'October 2026' (Home + Payments)
  static String monthName(String month) {
    final parts = month.split('-');
    final index = int.tryParse(parts.length == 2 ? parts[1] : '');
    if (index == null || index < 1 || index > 12) return month;
    return '${_months[index - 1]} ${parts[0]}';
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'month': month,
      'roomRent': roomRent,
      'electricity': electricity,
      'water': water,
      'dueDate': dueDate,
      'isPaid': isPaid,
      'paidDate': paidDate,
    };
  }

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      roomId: map['roomId'] as String,
      month: map['month'] as String,
      roomRent: (map['roomRent'] as num).toDouble(),
      electricity: (map['electricity'] as num).toDouble(),
      water: (map['water'] as num).toDouble(),
      dueDate: map['dueDate'] as String,
      isPaid: map['isPaid'] as bool,
      paidDate: map['paidDate'] as String?,
    );
  }

  // paidDate is set to null when marking unpaid, so it needs its own flag
  Payment copyWith({String? id, bool? isPaid, String? paidDate}) {
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
