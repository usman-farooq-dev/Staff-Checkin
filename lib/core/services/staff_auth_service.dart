import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/staff_user_model.dart';

enum StaffAuthStatus {
  success,
  invalidPin,
  inactiveAccount,
  error,
}

class StaffAuthResult {
  final StaffAuthStatus status;
  final StaffUserModel? staff;
  final String message;

  const StaffAuthResult({
    required this.status,
    this.staff,
    required this.message,
  });
}

class StaffAuthService {
  StaffAuthService._();
  static final StaffAuthService instance = StaffAuthService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<StaffUserModel?> currentStaffNotifier =
      ValueNotifier<StaffUserModel?>(null);

  StaffUserModel? get currentStaff => currentStaffNotifier.value;

  set currentStaff(StaffUserModel? staff) {
    currentStaffNotifier.value = staff;
  }

  /// Check if a staff member is actively authenticated
  bool get isLoggedIn =>
      currentStaff != null && currentStaff!.isActive;

  /// Verifies entered PIN against Firestore 'Staff' collection directly.
  /// Checks if PIN matches and whether the staff member's isActive is true.
  Future<StaffAuthResult> authenticateWithPin(String pin) async {
    final trimmedPin = pin.trim();
    if (trimmedPin.isEmpty || trimmedPin.length < 4) {
      return const StaffAuthResult(
        status: StaffAuthStatus.invalidPin,
        message: 'Please enter a valid 4-digit PIN.',
      );
    }

    try {
      // 1. Primary Query: Collection 'Staff' with string pinCode
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('Staff')
          .where('pinCode', isEqualTo: trimmedPin)
          .limit(1)
          .get();

      // Fallback 1: Check if pinCode was stored as number
      if (snapshot.docs.isEmpty) {
        final intPin = int.tryParse(trimmedPin);
        if (intPin != null) {
          snapshot = await _firestore
              .collection('Staff')
              .where('pinCode', isEqualTo: intPin)
              .limit(1)
              .get();
        }
      }

      // Fallback 2: Check lowercase 'staff' collection name
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('staff')
            .where('pinCode', isEqualTo: trimmedPin)
            .limit(1)
            .get();
      }

      // Check if no staff record was found
      if (snapshot.docs.isEmpty) {
        return const StaffAuthResult(
          status: StaffAuthStatus.invalidPin,
          message:
              'Invalid PIN. No staff found with this PIN. Please check and try again.',
        );
      }

      // Staff record found
      final staffDoc = snapshot.docs.first;
      final staff = StaffUserModel.fromFirestore(staffDoc);

      // 2. Check if the staff account is active
      if (!staff.isActive) {
        return StaffAuthResult(
          status: StaffAuthStatus.inactiveAccount,
          staff: staff,
          message:
              'Account for ${staff.fullName} (ID: ${staff.staffId}) is currently inactive. Please contact your manager or administrator.',
        );
      }

      // 3. Successful authentication
      currentStaff = staff;
      return StaffAuthResult(
        status: StaffAuthStatus.success,
        staff: staff,
        message: 'Welcome, ${staff.fullName}!',
      );
    } on FirebaseException catch (e) {
      debugPrint('Firestore PIN verification error: ${e.code} - ${e.message}');
      return StaffAuthResult(
        status: StaffAuthStatus.error,
        message: 'Firestore connection error: ${e.message ?? e.code}',
      );
    } catch (e) {
      debugPrint('General error during PIN verification: $e');
      return StaffAuthResult(
        status: StaffAuthStatus.error,
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  void logout() {
    currentStaff = null;
  }
}
