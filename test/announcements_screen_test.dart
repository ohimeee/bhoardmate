import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:bhoardmate/models/holiday.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:bhoardmate/screens/announcements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';
import 'fake_holiday_service.dart';

// MainScreen loads the holidays in the app, so the test loads them here
Future<void> openScreen(
  WidgetTester tester,
  AuthProvider auth, {
  FakeDatabaseService? db,
  FakeHolidayService? holidayService,
}) async {
  // tall screen so the holiday card and the announcements are all built
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final holidays = HolidayProvider(
    service: holidayService ?? FakeHolidayService(),
  );
  await holidays.loadHolidays();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(
          create: (_) => AnnouncementProvider(db: db ?? FakeDatabaseService()),
        ),
        ChangeNotifierProvider.value(value: holidays),
      ],
      child: const MaterialApp(home: AnnouncementsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boarder reads newest announcements without owner actions', (
    tester,
  ) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginBoarder('BH01-RM2', '2222');
    await openScreen(tester, auth);
    expect(find.text('Pest control'), findsOneWidget);
    expect(find.text('New announcement'), findsNothing);
    expect(find.byTooltip('Edit announcement'), findsNothing);
    expect(find.byTooltip('Remove announcement'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Pest control')).dy,
      lessThan(tester.getTopLeft(find.text('Electricity rate increase')).dy),
    );
  });

  testWidgets('owner validates, creates, edits and confirms deletion', (
    tester,
  ) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openScreen(tester, auth);
    await tester.tap(find.text('New announcement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Message is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), ' Meeting ');
    await tester.enterText(find.byType(TextFormField).at(1), ' In the lobby. ');
    await tester.enterText(find.byType(TextFormField).at(2), '2026-02-30');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid date as YYYY-MM-DD'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), '2026-11-01');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('In the lobby.'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit announcement').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Updated meeting');
    await tester.enterText(find.byType(TextFormField).at(2), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Updated meeting'), findsOneWidget);
    expect(find.text('Event: 2026-11-01'), findsNothing);
    await tester.tap(find.byTooltip('Remove announcement').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Updated meeting'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove announcement').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Updated meeting'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logged out users cannot read announcements', (tester) async {
    await openScreen(tester, AuthProvider(db: FakeDatabaseService()));
    expect(
      find.text('Please log in again to view announcements.'),
      findsOneWidget,
    );
    expect(find.text('Pest control'), findsNothing);
  });

  // 5 holidays next year, so they are always upcoming
  List<Holiday> nextYearHolidays() {
    final year = DateTime.now().year + 1;
    return [
      Holiday(
        date: DateTime(year, 1, 1),
        localName: 'Bagong Taon',
        name: "New Year's Day",
      ),
      Holiday(
        date: DateTime(year, 4, 9),
        localName: 'Araw ng Kagitingan',
        name: 'Day of Valor',
      ),
      Holiday(
        date: DateTime(year, 5, 1),
        localName: 'Araw ng Paggawa',
        name: 'Labour Day',
      ),
      Holiday(
        date: DateTime(year, 6, 12),
        localName: 'Araw ng Kalayaan',
        name: 'Independence Day',
      ),
      Holiday(
        date: DateTime(year, 12, 25),
        localName: 'Araw ng Pasko',
        name: 'Christmas Day',
      ),
    ];
  }

  testWidgets('news shows the next 3 holidays, show all opens the rest', (
    tester,
  ) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginBoarder('BH01-RM2', '2222');
    final service = FakeHolidayService()..online = nextYearHolidays();
    await openScreen(tester, auth, holidayService: service);

    expect(find.text('Upcoming PH holidays'), findsOneWidget);
    expect(find.text("New Year's Day"), findsOneWidget);
    expect(find.text('Labour Day'), findsOneWidget);
    expect(find.text('Independence Day'), findsNothing);
    expect(find.text('Offline: showing the saved list.'), findsNothing);
    // announcements still below
    expect(find.text('Pest control'), findsOneWidget);

    await tester.tap(find.text('Show all (5)'));
    await tester.pumpAndSettle();
    expect(find.text('Christmas Day'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('offline shows the saved holidays with a note', (tester) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginBoarder('BH01-RM2', '2222');
    final service = FakeHolidayService()
      ..offline = true
      ..saved = nextYearHolidays();
    await openScreen(tester, auth, holidayService: service);

    expect(find.text('Offline: showing the saved list.'), findsOneWidget);
    expect(find.text("New Year's Day"), findsOneWidget);

    // internet back: Retry loads the API list and hides the note
    service.offline = false;
    service.online = nextYearHolidays();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Offline: showing the saved list.'), findsNothing);
    expect(find.text("New Year's Day"), findsOneWidget);
  });

  testWidgets('no internet and nothing saved shows an error with Retry', (
    tester,
  ) async {
    final db = FakeDatabaseService()..announcements = [];
    final auth = AuthProvider(db: db);
    await auth.loginBoarder('BH01-RM2', '2222');
    final service = FakeHolidayService()..offline = true;
    await openScreen(tester, auth, db: db, holidayService: service);

    expect(
      find.text('Could not load holidays. No internet connection.'),
      findsOneWidget,
    );
    // empty announcements still show their own empty state
    expect(find.text('No announcements yet'), findsOneWidget);

    service.offline = false;
    service.online = nextYearHolidays();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming PH holidays'), findsOneWidget);
    expect(find.text("New Year's Day"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh while offline switches to the saved holidays', (
    tester,
  ) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginBoarder('BH01-RM2', '2222');
    final service = FakeHolidayService()..online = nextYearHolidays();
    await openScreen(tester, auth, holidayService: service);
    expect(find.text('Offline: showing the saved list.'), findsNothing);

    // phone goes offline, the list from last time is on the phone
    service.offline = true;
    service.saved = nextYearHolidays();
    await tester.tap(find.byTooltip('Refresh announcements'));
    await tester.pumpAndSettle();
    expect(find.text('Offline: showing the saved list.'), findsOneWidget);
    expect(find.text("New Year's Day"), findsOneWidget);
  });
}
