import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/screens/members_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('own-profile mode opens the signed-in boarder profile', (
    tester,
  ) async {
    final auth = AuthProvider();
    await auth.loginBoarder('BH01-RM2', '2222');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: MembersScreen(showOwnProfile: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);
  });
  testWidgets('owner opens room details without profile editing', (
    tester,
  ) async {
    final auth = AuthProvider();
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: MembersScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vacant room'), findsOneWidget);
    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();
    expect(find.text('Room ID'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
    expect(find.text('Monthly rent'), findsOneWidget);
    expect(find.text('\u20B1 2500.00'), findsOneWidget);
    expect(find.text('Landlord'), findsNothing);
  });

  testWidgets('boarder can view a fellow boardmate but cannot edit them', (
    tester,
  ) async {
    final auth = AuthProvider();
    await auth.loginBoarder('BH01-RM2', '2222');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: MembersScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vacant room'), findsNothing);
    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(auth.rooms[0].boarderName, 'Maria Santos');
  });

  testWidgets('boarder validates and saves their own profile', (tester) async {
    final auth = AuthProvider();
    await auth.loginBoarder('BH01-RM2', '2222');
    final original = auth.rooms[1];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: MembersScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsOneWidget);
    await tester.tap(find.text('BH01-RM2 (You)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Use digits only'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated Boarder');
    await tester.enterText(find.byType(TextFormField).at(1), '09171234567');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Updated Boarder'), findsOneWidget);
    expect(auth.rooms[1].accessCode, original.accessCode);
    expect(auth.rooms[1].monthlyRent, original.monthlyRent);
    expect(auth.rooms[0].boarderName, 'Maria Santos');
  });
}
