import 'package:bhoardmate/models/payment.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:bhoardmate/providers/payment_provider.dart';
import 'package:bhoardmate/screens/payments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';
import 'fake_holiday_service.dart';

// MainScreen loads the payments in the app, so the test loads them here
Future<void> openScreen(
  WidgetTester tester,
  AuthProvider auth, [
  FakeDatabaseService? db,
]) async {
  // tall screen so every bill card is built
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final payments = PaymentProvider(db: db ?? FakeDatabaseService());
  await payments.loadPayments(roomId: auth.isOwner ? null : auth.currentRoomId);
  final holidays = HolidayProvider(service: FakeHolidayService());
  await holidays.loadHolidays();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: payments),
        ChangeNotifierProvider.value(value: holidays),
      ],
      child: const MaterialApp(home: PaymentsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no rooms shows guidance instead of an unusable bill form', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    db.rooms = [];
    await auth.loadRooms();
    await openScreen(tester, auth, db);
    await tester.tap(find.text('Add bill'));
    await tester.pumpAndSettle();
    expect(find.text('No rooms available'), findsOneWidget);
    expect(find.text('Save bill'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a bill for a removed room does not crash or save', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openScreen(tester, auth, db);
    await tester.tap(find.byTooltip('Edit bill').first);
    await tester.pumpAndSettle();
    final removedId = db.payments.first.roomId;
    db.rooms.removeWhere((room) => room.id == removedId);
    await auth.loadRooms();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();
    expect(find.text('This room is no longer available'), findsOneWidget);
    expect(find.text('Bill saved.'), findsNothing);
  });

  testWidgets('finite bill amounts cannot overflow the total', (tester) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openScreen(tester, auth, db);
    await tester.tap(find.byTooltip('Edit bill').first);
    await tester.pumpAndSettle();
    final original = db.payments.first.roomRent;
    await tester.enterText(find.byType(TextFormField).at(1), '1e308');
    await tester.enterText(find.byType(TextFormField).at(2), '1e308');
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();
    expect(
      find.text('The bill total is too large. Check the amounts.'),
      findsOneWidget,
    );
    expect(db.payments.first.roomRent, original);
    expect(tester.takeException(), isNull);
  });
  testWidgets('boarder sees own bills, breakdown and the solver', (
    tester,
  ) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginBoarder('BH01-RM2', '2222');
    await openScreen(tester, auth);

    expect(find.text('Outstanding balance'), findsOneWidget);
    expect(find.text('₱ 3500.00'), findsNWidgets(2));
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Electricity'), findsNWidgets(2));
    expect(find.text('Add bill'), findsNothing);
    expect(find.text('Mark paid'), findsNothing);
    // October bill: due Saturday the 10th, shown as Monday the 12th
    expect(find.text('Due on 2026-10-12'), findsOneWidget);
    expect(find.text('Moved from 2026-10-10 (Saturday)'), findsOneWidget);
    expect(
      find.text('Next due: 2026-10-12\nMoved from 2026-10-10 (Saturday)'),
      findsOneWidget,
    );

    // 50 kWh x 12 / 2 boarders = 300
    await tester.tap(find.text('Electricity solver'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '50');
    await tester.enterText(find.byType(TextField).at(2), '2');
    await tester.pump();
    expect(find.text('Each boarder pays ₱ 300.00'), findsOneWidget);

    // "Infinity" parses as a double, and a huge kWh x rate overflows
    await tester.enterText(find.byType(TextField).at(0), 'Infinity');
    await tester.pump();
    expect(find.text('Enter kWh, rate and boarders'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '1e308');
    await tester.pump();
    expect(find.text('Enter kWh, rate and boarders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner marks paid, adds a bill and deletes it', (tester) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openScreen(tester, auth);

    expect(find.text('Unpaid total (all rooms)'), findsOneWidget);
    expect(find.text('BH01-RM2 - Juan Dela Cruz'), findsNWidgets(2));
    expect(find.text('Mark paid'), findsNWidgets(2));

    await tester.tap(find.text('Mark paid').first);
    await tester.pumpAndSettle();
    expect(find.text('Marked paid.'), findsOneWidget);
    expect(find.text('Mark paid'), findsOneWidget);

    // empty form shows the validators
    await tester.tap(find.text('Add bill'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '2026-13');
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();
    expect(find.text('Room is required'), findsOneWidget);
    expect(find.text('Use YYYY-MM, like 2026-10'), findsOneWidget);
    expect(find.text('Electricity is required'), findsOneWidget);

    // picking the room fills in the rent, solver fills electricity
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BH01-RM4 (vacant)').last);
    await tester.pumpAndSettle();
    expect(find.text('2500'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '2026-11');
    await tester.tap(find.text('Solve'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(4), '40');
    await tester.pump();
    await tester.tap(find.text('Use this amount'));
    await tester.pumpAndSettle();
    expect(find.text('480.00'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(3), '150');
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();

    expect(find.text('Bill added.'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove bill').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing keeps the cents and rejects NaN and Infinity', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    db.payments = [
      const Payment(
        id: 'p9',
        roomId: 'BH01-RM3',
        month: '2026-11',
        roomRent: 2500.5,
        electricity: 760.125,
        water: 150.75,
        dueDate: '2026-11-10',
      ),
    ];
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openScreen(tester, auth, db);

    await tester.tap(find.byTooltip('Edit bill'));
    await tester.pumpAndSettle();
    expect(find.text('2500.5'), findsOneWidget);
    expect(find.text('760.125'), findsOneWidget);
    expect(find.text('150.75'), findsOneWidget);

    // saving without changes keeps every amount
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();
    expect(find.text('Bill saved.'), findsOneWidget);
    expect(db.payments.first.roomRent, 2500.5);
    expect(db.payments.first.electricity, 760.125);
    expect(db.payments.first.water, 150.75);

    await tester.tap(find.byTooltip('Edit bill'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Infinity');
    await tester.enterText(find.byType(TextFormField).at(3), 'NaN');
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid amount'), findsNWidgets(2));
    expect(db.payments.first.water, 150.75);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed refresh shows the error above the old bills', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openScreen(tester, auth, db);

    db.failPaymentsStream();
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load payments. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('October 2026'), findsWidgets);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load payments. Please try again.'),
      findsNothing,
    );
    expect(find.text('October 2026'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'editing a bill dated outside the picker years opens the picker',
    (tester) async {
      // a bill saved before the picker was limited (e.g. 2 years ahead)
      final far = DateTime.now().year + 2;
      final db = FakeDatabaseService();
      db.payments = [
        Payment(
          id: 'p9',
          roomId: 'BH01-RM3',
          month: '$far-01',
          roomRent: 2500,
          electricity: 700,
          water: 150,
          dueDate: '$far-01-10',
        ),
      ];
      final auth = AuthProvider(db: FakeDatabaseService());
      await auth.loginOwner('owner@bhoardmate.app', 'admin123');
      await openScreen(tester, auth, db);

      await tester.tap(find.byTooltip('Edit bill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    },
  );
}
