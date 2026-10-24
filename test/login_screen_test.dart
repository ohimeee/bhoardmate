import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/concern_provider.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:bhoardmate/providers/payment_provider.dart';
import 'package:bhoardmate/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';

Future<void> openLogin(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => ConcernProvider()),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
      ],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boarder form validates and shows a wrong code error', (
    tester,
  ) async {
    await openLogin(tester, AuthProvider(db: FakeDatabaseService()));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Room ID is required'), findsOneWidget);
    expect(find.text('Access code is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'room 2');
    await tester.enterText(find.byType(TextFormField).at(1), '9999');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Use a room ID like BH01-RM2'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'bh01-rm2');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong room ID or access code'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('owner switch logs in and opens Home', (tester) async {
    await openLogin(tester, AuthProvider(db: FakeDatabaseService()));
    await tester.tap(find.text('Owner? Log in as admin'));
    await tester.pumpAndSettle();
    expect(find.text('Owner login'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'owner');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'owner@bhoardmate.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Logged in as: Owner'), findsOneWidget);
  });

  testWidgets('saved Firebase login skips the login screen', (tester) async {
    final db = FakeDatabaseService();
    await db.signInBoarder('BH01-RM2', '2222');
    await openLogin(tester, AuthProvider(db: db));
    expect(find.text('Logged in as: BH01-RM2'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
  });
}
