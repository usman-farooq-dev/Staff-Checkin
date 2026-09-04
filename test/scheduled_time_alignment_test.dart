import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/models/check_task_model.dart';
import 'package:staff_checkin/models/scheduled_checkin_model.dart';

void main() {
  group('Scheduled Check-In Time & Alert Alignment Tests', () {
    test('Timestamp 1788552600000 parses to 8:10 PM and September 4, 2026 without UTC text', () {
      final check = ScheduledCheckInModel(
        id: '29c8d9317c7e44f8b71e',
        title: 'dsafadsf',
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(1788552600000, isUtc: true),
        status: 'pending',
        storeStatus: {'test_store': 'pending'},
        tasks: const [
          CheckTaskModel(
            stepNumber: 1,
            title: 'Task 1',
            requirementType: RequirementType.photo,
            isCompleted: false,
          ),
          CheckTaskModel(
            stepNumber: 2,
            title: 'Task 2',
            requirementType: RequirementType.photo,
            isCompleted: false,
          ),
        ],
      );

      // 1. Time display must be clean 8:10 PM
      expect(check.formattedTime, '8:10 PM');
      expect(check.formattedDate, 'Sep 4, 2026');
      expect(check.formattedDateTime, 'Sep 4, 2026 • 8:10 PM');

      // 2. Absolutely NO "UTC" in any text string
      expect(check.formattedTime.contains('UTC'), isFalse);
      expect(check.formattedDate.contains('UTC'), isFalse);
      expect(check.formattedDateTime.contains('UTC'), isFalse);
      expect(check.heroSubtitle.contains('UTC'), isFalse);
      expect(check.taskInfoSubtitle.contains('UTC'), isFalse);

      // 3. Effective scheduled date time components
      final effective = check.effectiveScheduledDateTime;
      expect(effective.year, 2026);
      expect(effective.month, 9);
      expect(effective.day, 4);
      expect(effective.hour, 20); // 8 PM
      expect(effective.minute, 10);
    });

    test('overdueOrDueInfo produces correct minute diff matching clock without 5-hour offset', () {
      // Create check scheduled for 4 minutes from now (wall-clock)
      final now = DateTime.now();
      final targetDateTime = now.add(const Duration(minutes: 4));
      // Store in UTC representation
      final utcEquivalent = DateTime.utc(
        targetDateTime.year,
        targetDateTime.month,
        targetDateTime.day,
        targetDateTime.hour,
        targetDateTime.minute,
      );

      final check = ScheduledCheckInModel(
        id: 'check_4min',
        title: 'Upcoming Check',
        scheduledAt: utcEquivalent,
        status: 'pending',
        storeStatus: {'test_store': 'pending'},
        tasks: const [
          CheckTaskModel(
            stepNumber: 1,
            title: 'Task 1',
            requirementType: RequirementType.photo,
            isCompleted: false,
          ),
        ],
      );

      expect(check.isOverdue, isFalse);
      expect(check.overdueOrDueInfo.contains('hr'), isFalse);
      expect(check.overdueOrDueInfo.contains('5 hr'), isFalse);
      expect(check.overdueOrDueInfo, contains('Due in'));
    });

    test('shouldTriggerAlertForStore returns true once scheduled time is reached', () {
      final now = DateTime.now();
      // Scheduled 2 minutes ago
      final pastTarget = now.subtract(const Duration(minutes: 2));
      final pastUtc = DateTime.utc(
        pastTarget.year,
        pastTarget.month,
        pastTarget.day,
        pastTarget.hour,
        pastTarget.minute,
      );

      final check = ScheduledCheckInModel(
        id: 'check_past',
        title: 'Ready Check',
        scheduledAt: pastUtc,
        status: 'pending',
        storeStatus: {'test_store': 'pending'},
        tasks: const [],
      );

      expect(check.isOverdue, isTrue);
      expect(check.shouldTriggerAlertForStore('test_store'), isTrue);
    });
  });
}
