// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:libyan_banking_hub/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LibyanBankingApp());

    // Verify that splash screen is shown or main title
    // Since the app starts with SPLASH view, we might want to check for something in SplashScreen
    // For now, just checking if the app pumps without error.
    expect(find.byType(LibyanBankingApp), findsOneWidget);
  });
}
