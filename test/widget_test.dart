import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bhoardmate/main.dart';

void main() {
  testWidgets('app starts on the login placeholder', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(const BhoardMateApp());

    expect(find.text('BhoardMate'), findsOneWidget);
    expect(find.text('Demo: log in as owner'), findsOneWidget);
  });
}
