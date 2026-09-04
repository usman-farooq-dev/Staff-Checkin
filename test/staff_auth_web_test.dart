import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/core/services/staff_auth_service.dart';

void main() {
  test('StaffAuthService validates empty and short pins', () async {
    final result1 = await StaffAuthService.instance.authenticateWithPin('');
    expect(result1.status, StaffAuthStatus.invalidPin);

    final result2 = await StaffAuthService.instance.authenticateWithPin('12');
    expect(result2.status, StaffAuthStatus.invalidPin);
  });

  test('StaffAuthService can verify live PIN 1234 via REST fallback', () async {
    final result = await StaffAuthService.instance.authenticateWithPin('1234');
    expect(result.status, StaffAuthStatus.success);
    expect(result.staff, isNotNull);
    expect(result.staff!.fullName, 'Ahmad Khan');
    expect(result.staff!.staffId, 'ST-100');
    expect(result.staff!.isActive, isTrue);
    // Verified against live Firestore where isKioskMode is correctly parsed as bool
    expect(result.staff!.isKioskMode, isA<bool>());

    // Clean up active listener / poll timer
    StaffAuthService.instance.logout();
  });

  test('StaffAuthService handles non-existent PIN properly without hanging', () async {
    final result = await StaffAuthService.instance.authenticateWithPin('9999');
    expect(result.status, StaffAuthStatus.invalidPin);
    expect(result.message, contains('Invalid PIN'));
  });
}
