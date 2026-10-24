import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/announcement_provider.dart';
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
  testWidgets('app starts on the login placeholder', (tester) async {
    await openLogin(tester, AuthProvider(db: FakeDatabaseService()));
    expect(find.text('BHoardMate'), findsOneWidget);
    expect(find.text('Demo: log in as boarder (BH01-RM2)'), findsOneWidget);
  });

  testWidgets('saved Firebase login skips the login screen', (tester) async {
    final db = FakeDatabaseService();
    await db.signInBoarder('BH01-RM2', '2222');
    await openLogin(tester, AuthProvider(db: db));
    expect(find.text('Logged in as: BH01-RM2'), findsOneWidget);
  });

  testWidgets('a reset code logs the boarder out to the login screen', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    await openLogin(tester, AuthProvider(db: db));
    await tester.tap(find.text('Demo: log in as boarder (BH01-RM2)'));
    await tester.pumpAndSettle();
    expect(find.text('Logged in as: BH01-RM2'), findsOneWidget);
    db.revokeSession();
    await tester.pumpAndSettle();
    expect(find.text('Logged in as: BH01-RM2'), findsNothing);
    expect(
      find.text('Your access code was changed. Please log in again.'),
      findsOneWidget,
    );
  });

  testWidgets('owner logs in with email and password', (tester) async {
    await openLogin(tester, AuthProvider(db: FakeDatabaseService()));
    await tester.enterText(
      find.byType(TextField).at(0),
      'owner@bhoardmate.app',
    );
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('Log in as owner'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong email or password'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'admin123');
    await tester.tap(find.text('Log in as owner'));
    await tester.pumpAndSettle();
    expect(find.text('Logged in as: Owner'), findsOneWidget);
  });
}
