import 'dart:async';

import 'package:bhoardmate/models/room.dart';
import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/concern_provider.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:bhoardmate/screens/announcements_screen.dart';
import 'package:bhoardmate/screens/concerns_screen.dart';
import 'package:bhoardmate/screens/members_screen.dart';
import 'package:bhoardmate/screens/rooms_screen.dart';
import 'package:bhoardmate/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';
import 'fake_holiday_service.dart';

class RoomStreamFailure extends FakeDatabaseService {
  final roomUpdates = StreamController<List<Room>>.broadcast();

  @override
  Stream<List<Room>> roomsStream() => roomUpdates.stream;
}

Future<void> openValidationScreen(
  WidgetTester tester,
  FakeDatabaseService db,
  AuthProvider auth,
  Widget screen,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider(db: db)),
        ChangeNotifierProvider(create: (_) => ConcernProvider(db: db)),
        ChangeNotifierProvider(
          create: (_) => HolidayProvider(service: FakeHolidayService()),
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final screens = <String, Widget>{
    'No announcements yet': const AnnouncementsScreen(),
    'No concerns yet': const ConcernsScreen(),
    'No members yet': const MembersScreen(),
    'No rooms yet': const RoomsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} uses the shared empty state', (tester) async {
      final db = FakeDatabaseService();
      final auth = AuthProvider(db: db);
      await auth.loginOwner('owner@bhoardmate.app', 'admin123');
      db.rooms = [];
      db.announcements = [];
      db.concerns = [];
      await openValidationScreen(tester, db, auth, entry.value);
      expect(find.byType(EmptyState), findsWidgets);
      expect(find.text(entry.key), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    });
  }

  for (final screen in [const RoomsScreen(), const MembersScreen()]) {
    testWidgets(
      '${screen.runtimeType} shows a later provider error and retries',
      (tester) async {
        final db = RoomStreamFailure();
        final auth = AuthProvider(db: db);
        await auth.loginOwner('owner@bhoardmate.app', 'admin123');
        await openValidationScreen(tester, db, auth, screen);
        expect(find.text('Maria Santos'), findsOneWidget);
        db.roomUpdates.addError(Exception('Stream failed'));
        await tester.pumpAndSettle();
        expect(
          find.text('Something went wrong. Please try again.'),
          findsOneWidget,
        );
        expect(find.text('Maria Santos'), findsNothing);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.text('Maria Santos'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        auth.dispose();
        await db.roomUpdates.close();
      },
    );
  }

  testWidgets('missing own room does not show the boardmate directory on Me', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginBoarder('BH01-RM2', '2222');
    final ownRoom = db.rooms[1];
    db.rooms.removeWhere((room) => room.id == ownRoom.id);
    await openValidationScreen(
      tester,
      db,
      auth,
      const MembersScreen(showOwnProfile: true),
    );
    expect(find.text('Your room is no longer available.'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);
    db.rooms.add(ownRoom);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('announcement stream failure shows Retry and recovers', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openValidationScreen(tester, db, auth, const AnnouncementsScreen());
    db.failAnnouncementsStream();
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load announcements. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Pest control'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('concern stream failure shows Retry and recovers', (
    tester,
  ) async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginBoarder('BH01-RM2', '2222');
    await openValidationScreen(tester, db, auth, const ConcernsScreen());
    db.failConcernsStream();
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load concerns. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Leaking faucet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
