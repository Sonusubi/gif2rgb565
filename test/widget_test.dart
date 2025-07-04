// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gif2rgb565/main.dart';

void main() {
  testWidgets('Renders main page and title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GifToRGB565App());

    // Verify that the main page is rendered.
    expect(find.byType(ConverterHomePage), findsOneWidget);

    // Verify that the title is correct.
    expect(find.text('🎨 GIF to RGB565 Converter'), findsOneWidget);
  });
}
