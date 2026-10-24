import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/screens/announcements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_database_service.dart';

Future<void> openScreen(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
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
}
