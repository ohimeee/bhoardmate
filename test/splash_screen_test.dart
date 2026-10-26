import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/concern_provider.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:bhoardmate/providers/payment_provider.dart';
import 'package:bhoardmate/screens/login_screen.dart';
import 'package:bhoardmate/screens/splash_screen.dart';
import 'package:bhoardmate/widgets/bhoardmate_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';
import 'fake_holiday_service.dart';

void main() {
  for (final size in [const Size(411, 914), const Size(360, 640)]) {
    testWidgets('splash keeps its wordmark on login at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewInsets);
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
      expect(find.byIcon(Icons.house_rounded), findsNothing);
      expect(find.text('BHoardMate'), findsNothing);
      final wordmark = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is BHoardMateSplashPainter,
      );
      expect(wordmark, findsOneWidget);
      expect(tester.getTopLeft(wordmark), Offset.zero);
      expect(tester.getSize(wordmark), size);
      final painter =
          tester.widget<CustomPaint>(wordmark).painter!
              as BHoardMateSplashPainter;
      expect(painter.progress.value, 1.0);
      final header = find.text('Log in with your room ID and access code');
      expect(
        tester.getTopLeft(header).dy,
        greaterThan(SplashTimeline.loginWordmarkRect(size).bottom),
      );
      await tester.ensureVisible(find.text('Owner? Log in as admin'));
      await tester.tap(find.text('Owner? Log in as admin'));
      await tester.pumpAndSettle();
      expect(find.text('Owner login'), findsOneWidget);
      await tester.showKeyboard(find.byType(TextFormField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(wordmark), Offset.zero);
      expect(tester.getSize(wordmark), size);
      await tester.ensureVisible(find.text('Log in'));
      expect(tester.takeException(), isNull);
    });
  }
}
