import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/models/scheduled_checkin_model.dart';
import 'package:staff_checkin/widgets/compliance_card.dart';

void main() {
  group('Missed Check & Overdue Banner Tests', () {
    test('ScheduledCheckInModel correctly handles missed status for store', () {
      final check = ScheduledCheckInModel(
        id: 'check_123',
        title: 'Hygiene Check',
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 35)),
        status: 'pending',
        storeStatus: {
          'store_islamabad': 'missed',
          'store_lahore': 'completed',
        },
      );

      // Verify store-specific status checks
      expect(check.isMissedForStore('store_islamabad'), isTrue);
      expect(check.isActionableForStore('store_islamabad'), isTrue);
      expect(check.isCompletedForStore('store_islamabad'), isFalse);

      expect(check.isMissedForStore('store_lahore'), isFalse);
      expect(check.isActionableForStore('store_lahore'), isFalse);
      expect(check.isCompletedForStore('store_lahore'), isTrue);

      // Verify overdue calculations
      expect(check.isOverdue, isTrue);
      expect(check.overdueOrDueInfo, contains('Overdue by'));
    });

    testWidgets('OverdueAlertBanner renders and triggers onStartNow', (WidgetTester tester) async {
      bool startNowPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverdueAlertBanner(
              overdueCount: 1,
              title: 'Hygiene Check',
              onStartNow: () {
                startNowPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('1 check overdue'), findsOneWidget);
      expect(find.text('Hygiene Check — escalated to your manager.'), findsOneWidget);
      expect(find.text('START NOW'), findsOneWidget);

      await tester.tap(find.text('START NOW'));
      await tester.pump();

      expect(startNowPressed, isTrue);
    });

    testWidgets('OverdueAlertBanner adapts properly in tablet constraints', (WidgetTester tester) async {
      // Tablet screen size (iPad: 834 x 1194)
      tester.view.physicalSize = const Size(834, 1194);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverdueAlertBanner(
              overdueCount: 2,
              title: 'Multiple Checks',
              onStartNow: () {},
            ),
          ),
        ),
      );

      expect(find.text('2 checks overdue'), findsOneWidget);
      expect(find.text('Multiple Checks — escalated to your manager.'), findsOneWidget);
      expect(find.text('START NOW'), findsOneWidget);
    });
  });
}
