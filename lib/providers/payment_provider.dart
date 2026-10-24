import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../services/database_service.dart';

// monthly bills from Firestore, newest month first
class PaymentProvider extends ChangeNotifier {
  final DatabaseService _db;

  // the tests pass a fake service so they don't need Firebase
  PaymentProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Payment>>? _sub;

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

  // newest month first, then by room. sorted here like concerns
  // so Firestore doesn't need an extra index
  void _setPayments(List<Payment> list) {
    _payments = list
      ..sort((a, b) {
        final byMonth = b.month.compareTo(a.month);
        if (byMonth != 0) return byMonth;
        return a.roomId.compareTo(b.roomId);
      });
    notifyListeners();
  }

  // owner: roomId null = every room.
  // boarder: only their room, the rules reject anything else
  Future<void> loadPayments({String? roomId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _setPayments(await _db.getPayments(roomId: roomId));
      _sub?.cancel();
      _sub = _db
          .paymentsStream(roomId: roomId)
          .listen(
            _setPayments,
            onError: (e) {
              _errorMessage = 'Could not load payments. Please try again.';
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = 'Could not load payments. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // the stream updates the list, these only write to Firestore
  Future<void> addPayment(Payment payment) async {
    try {
      await _db.insertPayment(payment);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not add the bill. Please try again.';
    }
    notifyListeners();
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      await _db.updatePayment(payment);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not save the bill. Please try again.';
    }
    notifyListeners();
  }

  // owner only: paid gets today's date, unpaid clears it
  Future<void> togglePaid(String id) async {
    final matches = _payments.where((p) => p.id == id);
    if (matches.isEmpty) return;
    final payment = matches.first;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      await _db.updatePayment(
        payment.copyWith(isPaid: !payment.isPaid, paidDate: today),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not save the change. Please try again.';
    }
    notifyListeners();
  }

  Future<void> deletePayment(String id) async {
    try {
      await _db.deletePayment(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not remove the bill. Please try again.';
    }
    notifyListeners();
  }

  // logout: stop listening and forget the old user's data
  void clear() {
    _sub?.cancel();
    _sub = null;
    _payments = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
