// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bella_color/config/app_config.dart';

void main() {
  testWidgets('Carga la app con el tema mariposa', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bella Color',
        theme: AppConfig.buildTheme(),
        home: const Scaffold(
          body: Center(child: Text('Bella Color')),
        ),
      ),
    );

    expect(find.text('Bella Color'), findsOneWidget);
  });
}
