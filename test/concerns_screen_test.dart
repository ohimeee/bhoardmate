import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/concern_provider.dart';
import 'package:bhoardmate/screens/concerns_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> openScreen(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ConcernProvider()),
      ],
      child: const MaterialApp(home: ConcernsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boarder validates and reports only for their room', (
    tester,
  ) async {
    final auth = AuthProvider();
    await auth.loginBoarder('BH01-RM2', '2222');
    await openScreen(tester, auth);
    expect(find.text('Leaking faucet'), findsOneWidget);
    expect(find.text('Broken hallway light'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.text('Report a concern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), ' Broken fan ');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      ' Fan will not turn on. ',
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Broken fan'), findsOneWidget);
    expect(find.text('Fan will not turn on.'), findsOneWidget);
    expect(find.text('Room: BH01-RM2'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner toggles status and confirms deletion', (tester) async {
    final auth = AuthProvider();
    await auth.loginOwner('owner', 'admin123');
    await openScreen(tester, auth);
    expect(find.text('Report a concern'), findsNothing);
    expect(find.byType(Checkbox), findsNWidgets(3));
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    await tester.tap(find.byTooltip('Remove concern').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Leaking faucet'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove concern').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Leaking faucet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty room shows empty state', (tester) async {
    final auth = AuthProvider();
    await auth.loginBoarder('BH01-RM4', '4444');
    await openScreen(tester, auth);
    expect(find.text('No concerns yet'), findsOneWidget);
  });

  testWidgets('logged out users cannot see concerns or report', (tester) async {
    await openScreen(tester, AuthProvider());
    expect(
      find.text('Please log in again to view your concerns.'),
      findsOneWidget,
    );
    expect(find.text('Leaking faucet'), findsNothing);
    expect(find.text('Report a concern'), findsNothing);
  });
}
