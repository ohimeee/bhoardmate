import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/concern_provider.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:bhoardmate/providers/payment_provider.dart';
import 'package:bhoardmate/screens/login_screen.dart';
import 'package:bhoardmate/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';
import 'fake_holiday_service.dart';

void main() {
  testWidgets('splash replaces itself with login', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(db: FakeDatabaseService()),
          ),
          ChangeNotifierProvider(
            create: (_) => PaymentProvider(db: FakeDatabaseService()),
          ),
          ChangeNotifierProvider(
            create: (_) => AnnouncementProvider(db: FakeDatabaseService()),
          ),
          ChangeNotifierProvider(
            create: (_) => ConcernProvider(db: FakeDatabaseService()),
          ),
          ChangeNotifierProvider(
            create: (_) => HolidayProvider(service: FakeHolidayService()),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
