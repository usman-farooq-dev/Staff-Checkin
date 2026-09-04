import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/views/auth/pin_screen.dart';

void main() {
  testWidgets('PinScreen renders correctly in tablet view', (WidgetTester tester) async {
    // Set tablet screen size (e.g. iPad 768x1024)
    tester.view.physicalSize = const Size(768 * 2, 1024 * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: PinScreen(),
      ),
    );

    expect(find.text('Staff Check-In'), findsOneWidget);
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('Your PIN links compliance evidence to you.'), findsOneWidget);
    expect(find.text('0 of 4 digits entered'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    // Verify digits exist
    for (int i = 0; i <= 9; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
  });

  testWidgets('PinScreen renders correctly in mobile view', (WidgetTester tester) async {
    // Set mobile screen size (375x812)
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: PinScreen(),
      ),
    );

    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });
}
