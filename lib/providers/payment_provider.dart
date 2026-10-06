import 'package:flutter/foundation.dart';

import '../models/payment.dart';

// sample data for now, DatabaseService comes in #3
class PaymentProvider extends ChangeNotifier {
  final List<Payment> _all = [
    const Payment(
      id: 1,
      roomId: 'BH01-RM1',
      month: '2026-10',
      roomRent: 2500,
      electricity: 850,
      water: 200,
      dueDate: '2026-10-10',
      isPaid: true,
      paidDate: '2026-10-05',
    ),
    const Payment(
      id: 2,
      roomId: 'BH01-RM2',
      month: '2026-10',
      roomRent: 2500,
      electricity: 800,
      water: 200,
      dueDate: '2026-10-10',
    ),
    const Payment(
      id: 3,
      roomId: 'BH01-RM3',
      month: '2026-10',
      roomRent: 2500,
      electricity: 760,
      water: 180,
      dueDate: '2026-10-10',
    ),
    const Payment(
      id: 4,
      roomId: 'BH01-RM2',
      month: '2026-09',
      roomRent: 2500,
      electricity: 780,
      water: 200,
      dueDate: '2026-09-10',
      isPaid: true,
      paidDate: '2026-09-08',
    ),
  ];

  String? _roomId;
  List<Payment> _payments = [];
  final bool _isLoading = false;
  String? _errorMessage;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // sum of unpaid totals in the loaded list
  double get outstandingBalance {
    double sum = 0;
    for (final p in _payments) {
      if (!p.isPaid) sum += p.total;
    }
    return sum;
  }

  int _nextId() {
    int max = 0;
    for (final p in _all) {
      if (p.id != null && p.id! > max) max = p.id!;
    }
    return max + 1;
  }

  void _refresh() {
    _payments = _all
        .where((p) => _roomId == null || p.roomId == _roomId)
        .toList();
    notifyListeners();
  }

  Future<void> loadPayments({String? roomId}) async {
    _roomId = roomId;
    _errorMessage = null;
    _refresh();
  }

  Future<void> addPayment(Payment payment) async {
    _all.add(payment.copyWith(id: _nextId()));
    _refresh();
  }

  Future<void> updatePayment(Payment payment) async {
    final index = _all.indexWhere((p) => p.id == payment.id);
    if (index == -1) {
      _errorMessage = 'Payment not found';
      notifyListeners();
      return;
    }
    _all[index] = payment;
    _refresh();
  }

  Future<void> togglePaid(int id) async {
    final index = _all.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final p = _all[index];
    _all[index] = p.copyWith(
      isPaid: !p.isPaid,
      paidDate: DateTime.now().toIso8601String().substring(0, 10),
    );
    _refresh();
  }

  Future<void> deletePayment(int id) async {
    _all.removeWhere((p) => p.id == id);
    _refresh();
  }
}
