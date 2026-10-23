import 'package:bhoardmate/models/owner.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/screens/owner_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('owner form validates and passes profile fields to save action', (
    tester,
  ) async {
    final auth = AuthProvider();
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    Owner? saved;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: OwnerProfileScreen(
            onSave: (owner) async {
              saved = owner;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.enterText(find.byType(TextFormField).last, 'abc');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(find.byType(TextFormField).first, 'New Owner');
    await tester.enterText(find.byType(TextFormField).last, '09171234567');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved!.name, 'New Owner');
    expect(saved!.contactNumber, '09171234567');
    expect(saved!.id, auth.owner.id);
    expect(saved!.email, auth.owner.email);
  });

  testWidgets('owner editing stays disabled without a save action', (
    tester,
  ) async {
    final auth = AuthProvider();
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: OwnerProfileScreen()),
      ),
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(find.text('Profile editing is not available yet.'), findsOneWidget);
  });
}
