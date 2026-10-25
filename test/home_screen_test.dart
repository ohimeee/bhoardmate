import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/concern_provider.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:bhoardmate/providers/payment_provider.dart';
import 'package:bhoardmate/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';

// opens MainScreen (Home tab) like after login; MainScreen loads the data
Future<void> openHome(
  WidgetTester tester,
  AuthProvider auth,
  FakeDatabaseService db,
  PaymentProvider payments,
) async {
  // tall screen so every Home section is built
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: payments),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider(db: db)),
        ChangeNotifierProvider(create: (_) => ConcernProvider(db: db)),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
      ],
      child: const MaterialApp(home: MainScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

int currentTab(WidgetTester tester) {
  return tester
      .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
      .currentIndex;
}

void main() {
  testWidgets('boarder sees name, balance, due date and latest news', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginBoarder('BH01-RM2', '2222');
    await openHome(tester, auth, db, PaymentProvider(db: db));

    expect(find.text('Hi, Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Room BH01-RM2'), findsOneWidget);
    expect(find.text('Outstanding balance'), findsOneWidget);
    expect(find.text('₱ 3500.00'), findsOneWidget);
    expect(find.text('Next due: 2026-10-10'), findsOneWidget);
    // newest 2 of 3
    expect(find.text('Pest control'), findsOneWidget);
    expect(find.text('Electricity rate increase'), findsOneWidget);
    expect(find.text('Water interruption'), findsNothing);
    // owner only
    expect(find.text('Rent collected'), findsNothing);
    expect(find.text('Rooms'), findsNothing);

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(currentTab(tester), 2);
  });

  testWidgets('owner sees the rent collected per month', (tester) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    final payments = PaymentProvider(db: db);
    await openHome(tester, auth, db, payments);

    expect(find.text('Hi, Mrs. Estoesta'), findsOneWidget);
    expect(find.text('Unpaid total (all rooms)'), findsOneWidget);
    expect(find.text('Rooms'), findsOneWidget);
    // October: only RM1 paid, room rent only
    expect(find.text('Rent collected'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('₱ 2500.00'), findsOneWidget);
    expect(find.text('1 of 3 bills paid'), findsOneWidget);

    // paid on another phone -> the stream updates Home
    await payments.togglePaid('p2');
    await tester.pumpAndSettle();
    expect(find.text('₱ 5000.00'), findsOneWidget);
    expect(find.text('2 of 3 bills paid'), findsOneWidget);

    await tester.tap(find.text('October 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('September 2026').last);
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 bills paid'), findsOneWidget);
    expect(find.text('₱ 2500.00'), findsOneWidget);

    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();
    expect(currentTab(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows errors with Retry and empty news', (tester) async {
    final db = FakeDatabaseService();
    db.announcements = [];
    final auth = AuthProvider(db: db);
    await auth.loginBoarder('BH01-RM2', '2222');
    await openHome(tester, auth, db, PaymentProvider(db: db));

    expect(find.text('No announcements yet.'), findsOneWidget);

    db.failPaymentsStream();
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load payments. Please try again.'),
      findsOneWidget,
    );
    // old balance stays under the error
    expect(find.text('₱ 3500.00'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load payments. Please try again.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
