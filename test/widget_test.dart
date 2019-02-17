// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:issue_tracker/home_page.dart';

void main() {
  testWidgets(
    'Home Page test',
    (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MaterialApp(home: new HomePage());
          },
        ),
      );

      // Verify that our icons are present.
      expect(find.byIcon(Icons.report), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byIcon(Icons.assignment), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    },
  );
}
