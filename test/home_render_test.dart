import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/views/main_nav_wrapper.dart';

void main() {
  testWidgets('MainNavWrapper and HomeScreen render test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavWrapper(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good Evening, Ahmed'), findsOneWidget);
    expect(find.text('6:57 PM'), findsOneWidget);
    expect(find.text("Today's progress"), findsOneWidget);
    expect(find.text('Notifications disabled'), findsOneWidget);
  });
}
