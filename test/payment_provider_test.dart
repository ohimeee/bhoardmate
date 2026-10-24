import 'package:bhoardmate/models/payment.dart';
import 'package:bhoardmate/providers/payment_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_database_service.dart';

void main() {
  test('boarder only gets their own room, newest month first', () async {
    final provider = PaymentProvider(db: FakeDatabaseService());
    await provider.loadPayments(roomId: 'BH01-RM2');
    expect(provider.payments.length, 2);
    expect(provider.payments.first.month, '2026-10');
    // only October is unpaid: 2500 + 800 + 200
    expect(provider.outstandingBalance, 3500);
  });

  test('owner adds, edits and deletes a bill', () async {
    final provider = PaymentProvider(db: FakeDatabaseService());
    await provider.loadPayments();
    expect(provider.payments.length, 4);
    await provider.addPayment(
      const Payment(
        roomId: 'BH01-RM1',
        month: '2026-11',
        roomRent: 2500,
        electricity: 900,
        water: 200,
        dueDate: '2026-11-10',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.payments.length, 5);
    expect(provider.payments.first.month, '2026-11');

    final bill = provider.payments.first;
    await provider.updatePayment(
      Payment(
        id: bill.id,
        roomId: bill.roomId,
        month: bill.month,
        roomRent: bill.roomRent,
        electricity: 950,
        water: bill.water,
        dueDate: bill.dueDate,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.payments.first.electricity, 950);

    await provider.deletePayment(bill.id!);
    await Future<void>.delayed(Duration.zero);
    expect(provider.payments.length, 4);
  });

  test('togglePaid sets and clears the paid date', () async {
    final provider = PaymentProvider(db: FakeDatabaseService());
    await provider.loadPayments();
    await provider.togglePaid('p2');
    await Future<void>.delayed(Duration.zero);
    var p2 = provider.payments.firstWhere((p) => p.id == 'p2');
    expect(p2.isPaid, isTrue);
    expect(p2.paidDate, isNotNull);

    await provider.togglePaid('p2');
    await Future<void>.delayed(Duration.zero);
    p2 = provider.payments.firstWhere((p) => p.id == 'p2');
    expect(p2.isPaid, isFalse);
    expect(p2.paidDate, isNull);

    provider.clear();
    expect(provider.payments, isEmpty);
    expect(provider.outstandingBalance, 0);
  });
}
