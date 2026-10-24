import 'package:bhoardmate/models/room.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/screens/rooms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';

class EmptyRooms extends AuthProvider {
  EmptyRooms() : super(db: FakeDatabaseService());

  @override
  List<Room> get rooms => [];
}

class FailedRooms extends AuthProvider {
  FailedRooms() : super(db: FakeDatabaseService());

  @override
  Future<void> loadRooms() async => throw Exception('Offline');
}

Future<void> openRooms(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: auth,
      child: const MaterialApp(home: RoomsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'editing rent validates and preserves the code and all boarder fields',
    (tester) async {
      final auth = AuthProvider(db: FakeDatabaseService());
      await auth.loginOwner('owner@bhoardmate.app', 'admin123');
      final before = auth.rooms.first;
      await openRooms(tester, auth);
      await tester.tap(find.text('Edit rent').first);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '-1');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a positive monthly rent'), findsOneWidget);
      expect(auth.rooms.first.monthlyRent, before.monthlyRent);
      await tester.enterText(find.byType(TextFormField), '3200.50');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final after = auth.rooms.first;
      expect(after.monthlyRent, 3200.50);
      expect(
        after.toMap()..remove('monthlyRent'),
        before.toMap()..remove('monthlyRent'),
      );
      expect(after.id, before.id);
      expect(find.text('Monthly rent updated.'), findsOneWidget);
    },
  );
  testWidgets('opening Rooms does not animate the hidden announcement button', (
    tester,
  ) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: IndexedStack(
            index: 0,
            children: [
              Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const RoomsScreen(),
                        ),
                      ),
                      child: const Text('Open rooms'),
                    ),
                  ),
                ),
              ),
              Scaffold(
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () {},
                  label: const Text('New announcement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open rooms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('New announcement'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('Add room'), findsOneWidget);
  });
  testWidgets(
    'boarders and logged out users cannot see room codes or actions',
    (tester) async {
      final auth = AuthProvider(db: FakeDatabaseService());
      await openRooms(tester, auth);
      expect(find.text('Only the owner can manage rooms.'), findsOneWidget);
      expect(find.text('Add room'), findsNothing);
      await auth.loginBoarder('BH01-RM2', '2222');
      await tester.pumpAndSettle();
      expect(find.text('Reset code'), findsNothing);
      expect(find.textContaining('Code:'), findsNothing);
    },
  );
  testWidgets('owner validates and adds a room without duplicate IDs', (
    tester,
  ) async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await openRooms(tester, auth);
    await tester.tap(find.text('Add room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Access code is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'bh01-rm1');
    await tester.enterText(find.byType(TextFormField).at(1), '5555');
    await tester.enterText(find.byType(TextFormField).at(2), 'NaN');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Room ID already exists'), findsOneWidget);
    expect(find.text('Enter a positive monthly rent'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'bh01-rm5');
    await tester.enterText(find.byType(TextFormField).at(2), '3000');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(auth.rooms.last.id, 'BH01-RM5');
    expect(auth.rooms.last.monthlyRent, 3000);
    expect(auth.rooms.last.accessCode, '5555');
    expect(find.text('Room added.'), findsOneWidget);
  });
  testWidgets(
    'reset requires confirmation and clears boarder fields preserving room and rent',
    (tester) async {
      final auth = AuthProvider(db: FakeDatabaseService());
      await auth.loginOwner('owner@bhoardmate.app', 'admin123');
      final original = auth.rooms.first;
      await openRooms(tester, auth);
      await tester.tap(find.text('Reset code').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), original.accessCode);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a different access code'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '9876');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(auth.rooms.first.accessCode, original.accessCode);
      expect(auth.rooms.first.boarderName, original.boarderName);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      final updated = auth.rooms.first;
      expect(updated.accessCode, '9876');
      expect(updated.id, original.id);
      expect(updated.monthlyRent, original.monthlyRent);
      expect(updated.boarderName, isNull);
      expect(updated.contactNumber, isNull);
      expect(updated.age, isNull);
      expect(updated.emergencyContactName, isNull);
      expect(updated.emergencyContactNumber, isNull);
    },
  );
  testWidgets('owner sees empty state and load failures allow retry', (
    tester,
  ) async {
    final empty = EmptyRooms();
    await empty.loginOwner('owner@bhoardmate.app', 'admin123');
    await openRooms(tester, empty);
    expect(
      find.text('No rooms yet. Add a room to get started.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    final failed = FailedRooms();
    await failed.loginOwner('owner@bhoardmate.app', 'admin123');
    await openRooms(tester, failed);
    expect(
      find.text('Could not load rooms. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load rooms. Please try again.'),
      findsOneWidget,
    );
  });
}
