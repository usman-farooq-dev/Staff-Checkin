import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/models/scheduled_checkin_model.dart';
import 'package:staff_checkin/views/alert/compliance_alert_dialog.dart';

void main() {
  group('Compliance Alert Responsive Tests', () {
    testWidgets('Mobile view renders existing fullscreen alert without change', (WidgetTester tester) async {
      // Mobile phone screen size (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ComplianceAlertScreen(
            title: 'Hygiene Check',
            scheduledTime: '6:57 PM',
            dueInfo: 'Due 7 minutes',
            canSnooze: true,
          ),
        ),
      );

      // Mobile elements
      expect(find.text('Compliance check required'), findsOneWidget);
      expect(find.text('Hygiene Check'), findsOneWidget);
      expect(find.text('6:57 PM'), findsOneWidget);
      expect(find.text('Due 7 minutes'), findsOneWidget);
      expect(find.text('START CHECK'), findsOneWidget);
      expect(find.text('REMIND ME AGAIN IN 15 MINUTES'), findsOneWidget);
    });

    testWidgets('Tablet view renders dialog modal matching mockup 03', (WidgetTester tester) async {
      // iPad screen size (834 x 1194)
      tester.view.physicalSize = const Size(834, 1194);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool startPressed = false;
      bool snoozePressed = false;

      final check = ScheduledCheckInModel(
        id: 'chk_123',
        title: 'Hygiene Check',
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'pending',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplianceAlertScreen(
            check: check,
            title: 'Hygiene Check',
            scheduledTime: '4:37 PM',
            canSnooze: true,
            onStartCheck: () {
              startPressed = true;
            },
            onRemindLater: () {
              snoozePressed = true;
            },
          ),
        ),
      );

      // Mockup 03 elements on tablet
      expect(find.text('Compliance Check Overdue'), findsOneWidget);
      expect(find.text('Hygiene Check'), findsOneWidget);
      expect(find.text('Scheduled time'), findsOneWidget);
      expect(find.text('4:37 PM'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(
        find.text('This check is now overdue and has been reported to your manager. Please complete it now.'),
        findsOneWidget,
      );
      expect(find.text('START CHECK'), findsOneWidget);
      expect(find.text('REMIND ME AGAIN IN 15 MINUTES'), findsOneWidget);

      // Tap START CHECK
      await tester.tap(find.text('START CHECK'));
      await tester.pump();
      expect(startPressed, isTrue);

      // Tap REMIND ME AGAIN IN 15 MINUTES
      await tester.tap(find.text('REMIND ME AGAIN IN 15 MINUTES'));
      await tester.pump();
      expect(snoozePressed, isTrue);
    });

    testWidgets('Alert dialog is non-cancelable (canPop is false) and hides snooze when canSnooze is false', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final check = ScheduledCheckInModel(
        id: 'chk_123',
        title: 'Hygiene Check',
        scheduledAt: DateTime.now().toUtc(),
        status: 'pending',
        snoozeCount: {'store_1': 1},
      );

      // Verify canSnoozeForStore returns false when already snoozed once
      expect(check.canSnoozeForStore('store_1'), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: ComplianceAlertScreen(
            check: check,
            title: 'Hygiene Check',
            scheduledTime: check.formattedTime,
            canSnooze: false,
          ),
        ),
      );

      // Verify Snooze button is NOT shown
      expect(find.text('REMIND ME AGAIN IN 15 MINUTES'), findsNothing);
      expect(find.text('START CHECK'), findsOneWidget);
      expect(find.text('Final Reminder • Action Required'), findsOneWidget);

      // Verify PopScope canPop is false (cannot be dismissed by back button)
      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScopeWidget = tester.widget(popScopeFinder) as PopScope;
      expect(popScopeWidget.canPop, isFalse);
    });

    test('ScheduledCheckInModel parses and maintains scheduledAt in UTC', () {
      final model = ScheduledCheckInModel.fromMap({
        'title': 'Evening Check',
        'scheduledAt': '2026-09-04T14:30:00.000Z',
      }, 'chk_utc');

      expect(model.scheduledAt.isUtc, isTrue);
      // Clean time display without 'UTC' suffix
      expect(model.formattedTime, isNot(contains('UTC')));
      expect(model.formattedTime, contains('PM'));
    });
  });
}
