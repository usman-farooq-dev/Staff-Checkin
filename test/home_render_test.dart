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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Good Evening, Ahmed'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d{1,2}:\d{2}\s+(AM|PM)')), findsOneWidget);
    expect(find.text("Today's progress"), findsOneWidget);
    expect(find.text('Staff Training & Resources'), findsOneWidget);
    expect(find.text('ACCESS TRAINING'), findsOneWidget);
  });
}
