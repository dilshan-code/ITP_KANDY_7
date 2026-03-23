// Basic widget test for the ClickBuy app.
// This test verifies that the app launches without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App should launch without errors', (WidgetTester tester) async {
    // Build the ClickBuyApp and trigger a frame.
    await tester.pumpWidget(const ClickBuyApp());
    await tester.pump();

    // Verify the app renders successfully (no crash).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
