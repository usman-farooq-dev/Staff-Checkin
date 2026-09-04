import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_checkin/core/services/reminder_sound_service.dart';
import 'package:staff_checkin/core/services/staff_auth_service.dart';
import 'package:staff_checkin/models/staff_user_model.dart';
import 'package:staff_checkin/views/profile/profile_screen.dart';
import 'package:staff_checkin/views/profile/reminder_tune_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StaffAuthService.instance.currentStaff = const StaffUserModel(
      id: 'test_staff',
      fullName: 'Test Staff',
      staffId: 'ST-01',
      isKioskMode: false,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  group('ReminderSoundService Tests', () {
    test('Available tunes has 5 distinct tunes with chime as default', () {
      final tunes = ReminderSoundService.availableTunes;
      expect(tunes.length, equals(5));

      final defaultTune = tunes.firstWhere((t) => t.isDefault);
      expect(defaultTune.id, equals('chime'));
      expect(defaultTune.title, contains('Chime'));
      expect(defaultTune.assetName, equals('sounds/chime.wav'));

      expect(tunes.any((t) => t.id == 'digital_bell'), isTrue);
      expect(tunes.any((t) => t.id == 'pulse_alert'), isTrue);
      expect(tunes.any((t) => t.id == 'gentle_chime'), isTrue);
      expect(tunes.any((t) => t.id == 'buzzer_alert'), isTrue);
    });

    test('Can select tune and updates selectedTuneIdNotifier', () async {
      final service = ReminderSoundService.instance;
      await service.init();

      expect(service.selectedTuneId, equals('chime'));

      await service.selectTune('digital_bell');
      expect(service.selectedTuneId, equals('digital_bell'));
      expect(service.selectedTune.title, equals('Digital Bell'));

      // Re-set back to default
      await service.selectTune('chime');
      expect(service.selectedTuneId, equals('chime'));
    });
  });

  group('ReminderTuneScreen Widget Tests', () {
    testWidgets('Renders all 5 reminder tunes and allows selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReminderTuneScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Reminder Tunes'), findsOneWidget);
      expect(find.text('Compliance Alert Tune'), findsOneWidget);
      expect(find.text('AVAILABLE TUNES'), findsOneWidget);

      expect(find.text('Chime (Default)'), findsOneWidget);
      expect(find.text('Digital Bell'), findsOneWidget);
      expect(find.text('Pulse Alert'), findsOneWidget);
      expect(find.text('Gentle Chime'), findsOneWidget);
      expect(find.text('Buzzer Alert'), findsOneWidget);

      // Select Digital Bell
      await tester.tap(find.text('Digital Bell'));
      await tester.pump();

      expect(ReminderSoundService.instance.selectedTuneId, equals('digital_bell'));
    });

    testWidgets('Renders properly on tablet constraints',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(834, 1194);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ReminderTuneScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Reminder Tunes'), findsOneWidget);
      expect(find.text('Chime (Default)'), findsOneWidget);
      expect(find.text('Digital Bell'), findsOneWidget);
    });
  });

  group('ProfileScreen Sound & Alerts Integration', () {
    testWidgets('ProfileScreen renders Sound & alerts with Reminder tune row',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Sound & alerts'), findsOneWidget);
      expect(find.text('Reminder tune'), findsOneWidget);
    });
  });
}
