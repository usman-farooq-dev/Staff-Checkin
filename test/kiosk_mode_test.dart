import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/models/staff_user_model.dart';
import 'package:staff_checkin/core/services/kiosk_service.dart';
import 'package:staff_checkin/core/services/staff_auth_service.dart';
import 'package:staff_checkin/views/main_nav_wrapper.dart';
import 'package:staff_checkin/views/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StaffUserModel isKioskMode Field Tests', () {
    test('Default constructor has isKioskMode set to true', () {
      const user = StaffUserModel(
        id: 'user_1',
        fullName: 'Test User',
        staffId: 'ST-01',
      );
      expect(user.isKioskMode, isTrue);
    });

    test('fromMap defaults to true when isKioskMode is missing or null', () {
      final userMissing = StaffUserModel.fromMap({
        'id': 'user_2',
        'fullName': 'No Kiosk Field',
      });
      expect(userMissing.isKioskMode, isTrue);

      final userNull = StaffUserModel.fromMap({
        'id': 'user_3',
        'fullName': 'Null Kiosk Field',
        'isKioskMode': null,
      });
      expect(userNull.isKioskMode, isTrue);
    });

    test('fromMap reads isKioskMode = false when explicitly set to false', () {
      final userFalse = StaffUserModel.fromMap({
        'id': 'user_4',
        'fullName': 'Normal User',
        'isKioskMode': false,
      });
      expect(userFalse.isKioskMode, isFalse);

      // Trailing space in key (e.g. from Firebase Console field "isKioskMode ")
      final userWithSpace = StaffUserModel.fromMap({
        'id': 'user_4_space',
        'fullName': 'Ahmad Khan',
        'isKioskMode ': false,
      });
      expect(userWithSpace.isKioskMode, isFalse);

      // String 'false'
      final userStringFalse = StaffUserModel.fromMap({
        'id': 'user_4_str',
        'fullName': 'String False User',
        'isKioskMode': 'false',
      });
      expect(userStringFalse.isKioskMode, isFalse);
    });

    test('toMap and copyWith preserve isKioskMode', () {
      final user = StaffUserModel.fromMap({
        'id': 'user_5',
        'fullName': 'Kiosk User',
        'isKioskMode': true,
      });
      expect(user.toMap()['isKioskMode'], isTrue);

      final updated = user.copyWith(isKioskMode: false);
      expect(updated.isKioskMode, isFalse);
      expect(updated.toMap()['isKioskMode'], isFalse);
    });
  });

  group('MainNavWrapper Kiosk Mode PopScope Tests', () {
    testWidgets('PopScope canPop is false when isKioskMode is true',
        (tester) async {
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: '1',
        fullName: 'Ahmed Khan',
        staffId: 'ST-100',
        isKioskMode: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavWrapper(),
        ),
      );
      await tester.pumpAndSettle();

      final popScopeFinder =
          find.byWidgetPredicate((widget) => widget is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScopeWidget = tester.widget(popScopeFinder) as PopScope;
      expect(popScopeWidget.canPop, isFalse);
    });

    testWidgets('PopScope canPop is true when isKioskMode is false',
        (tester) async {
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: '1',
        fullName: 'Ahmed Khan',
        staffId: 'ST-100',
        isKioskMode: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavWrapper(),
        ),
      );
      await tester.pumpAndSettle();

      final popScopeFinder =
          find.byWidgetPredicate((widget) => widget is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScopeWidget = tester.widget(popScopeFinder) as PopScope;
      expect(popScopeWidget.canPop, isTrue);
    });

    testWidgets('PopScope canPop dynamically updates in real-time when admin changes isKioskMode',
        (tester) async {
      // 1. Initially false (unlocked)
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: '1',
        fullName: 'Ahmed Khan',
        staffId: 'ST-100',
        isKioskMode: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavWrapper(),
        ),
      );
      await tester.pumpAndSettle();

      var popScopeWidget = tester.widget(find.byWidgetPredicate((w) => w is PopScope)) as PopScope;
      expect(popScopeWidget.canPop, isTrue);

      // 2. Admin toggles isKioskMode to true in Firestore (real-time stream update)
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: '1',
        fullName: 'Ahmed Khan',
        staffId: 'ST-100',
        isKioskMode: true,
      );
      await tester.pumpAndSettle();

      popScopeWidget = tester.widget(find.byWidgetPredicate((w) => w is PopScope)) as PopScope;
      expect(popScopeWidget.canPop, isFalse);

      // 3. Admin toggles isKioskMode back to false in Firestore
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: '1',
        fullName: 'Ahmed Khan',
        staffId: 'ST-100',
        isKioskMode: false,
      );
      await tester.pumpAndSettle();

      popScopeWidget = tester.widget(find.byWidgetPredicate((w) => w is PopScope)) as PopScope;
      expect(popScopeWidget.canPop, isTrue);
    });
  });

  group('ProfileScreen Kiosk Mode UI & Restrictions Tests', () {
    testWidgets(
        'ProfileScreen displays Kiosk Active banner and Active (Locked) status',
        (tester) async {
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: '1',
        fullName: 'Ahmed Khan',
        staffId: 'ST-100',
        isKioskMode: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Kiosk Mode Active banner is visible
      expect(find.text('Kiosk Mode Active'), findsOneWidget);
      expect(find.text('Active (Locked)'), findsOneWidget);

      // Verify lock icon on reminder tune row
      expect(find.text('Reminder tune'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    });

    testWidgets(
        'ProfileScreen blocks Reminder Tune and displays locked SnackBar when isKioskMode is true',
        (tester) async {
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: '1',
        fullName: 'Ahmed Khan',
        staffId: 'ST-100',
        isKioskMode: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Reminder Tune
      await tester.tap(find.text('Reminder tune'));
      await tester.pump();

      // Verify locked SnackBar message appeared
      expect(
        find.text(
          'Sound settings are managed by store administrator in Kiosk Mode.',
        ),
        findsOneWidget,
      );
    });
  });

  group('KioskService Device Level Lock Tests', () {
    test('startKiosk activates isKioskActive and stopKiosk deactivates it',
        () async {
      final kiosk = KioskService.instance;
      await kiosk.startKiosk();
      expect(kiosk.isKioskActive, isTrue);

      await kiosk.stopKiosk();
      expect(kiosk.isKioskActive, isFalse);
    });

    test('KioskService auto synchronizes with StaffAuthService user changes',
        () async {
      final kiosk = KioskService.instance;
      await kiosk.init();

      // Setting staff with isKioskMode == false should deactivate kiosk
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: 'test_1',
        fullName: 'Normal User',
        staffId: 'ST-NORMAL',
        isKioskMode: false,
      );
      expect(kiosk.isKioskActive, isFalse);

      // Setting staff with isKioskMode == true should activate kiosk
      StaffAuthService.instance.currentStaff = const StaffUserModel(
        id: 'test_2',
        fullName: 'Kiosk User',
        staffId: 'ST-KIOSK',
        isKioskMode: true,
      );
      expect(kiosk.isKioskActive, isTrue);

      // Logging out (currentStaff == null) should immediately deactivate and unlock kiosk
      StaffAuthService.instance.logout();
      expect(kiosk.isKioskActive, isFalse);
    });
  });
}
