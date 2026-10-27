import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:bhoardmate/providers/payment_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_database_service.dart';
import 'home_screen_test.dart' show currentTab, openHome;

// opens MainScreen as a boarder and records every SystemNavigator.pop
Future<List<String>> openMain(WidgetTester tester) async {
  final db = FakeDatabaseService();
  final auth = AuthProvider(db: db);
  await auth.loginBoarder('BH01-RM2', '2222');
  await openHome(tester, auth, db, PaymentProvider(db: db));

  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      calls.add(call.method);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

Future<void> pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

void main() {
  testWidgets('back on Pay tab goes to Home and keeps the app open', (
    tester,
  ) async {
    final calls = await openMain(tester);

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(currentTab(tester), 1);

    await pressBack(tester);
    await tester.pumpAndSettle();
    expect(currentTab(tester), 0);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(find.text('Press back again to exit'), findsNothing);
  });

  testWidgets('first back on Home shows the exit hint', (tester) async {
    final calls = await openMain(tester);

    await pressBack(tester);
    expect(find.text('Press back again to exit'), findsOneWidget);
    expect(calls, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('second back within 2 seconds exits the app', (tester) async {
    final calls = await openMain(tester);

    await pressBack(tester);
    await tester.pump(const Duration(seconds: 1));
    await pressBack(tester);
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('back after more than 2 seconds shows the hint again', (
    tester,
  ) async {
    final calls = await openMain(tester);

    await pressBack(tester);
    // DateTime.now is the real clock, so wait in real time too
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await pressBack(tester);
    expect(find.text('Press back again to exit'), findsOneWidget);
    expect(calls, isNot(contains('SystemNavigator.pop')));
  });
}
