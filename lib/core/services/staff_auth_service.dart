import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _staffSubscription;
  Timer? _restPollTimer;

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance not available: $e');
      return null;
    }
  }

  final ValueNotifier<StaffUserModel?> currentStaffNotifier =
      ValueNotifier<StaffUserModel?>(null);

  StaffUserModel? get currentStaff => currentStaffNotifier.value;

  set currentStaff(StaffUserModel? staff) {
    currentStaffNotifier.value = staff;
  }

  /// Start real-time synchronization on active staff document in Firestore
  void _startRealtimeStaffListener(String staffDocId) {
    _staffSubscription?.cancel();
    _restPollTimer?.cancel();

    if (staffDocId.isEmpty) return;

    // 1. Native Firestore Realtime Snapshot Listener
    try {
      if (_firestore != null) {
        _staffSubscription = _firestore!
            .collection('Staff')
            .doc(staffDocId)
            .snapshots()
            .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final updatedStaff = StaffUserModel.fromFirestore(snapshot);
              debugPrint(
                  'Realtime Staff Update: isKioskMode=${updatedStaff.isKioskMode}, isActive=${updatedStaff.isActive}');
              currentStaff = updatedStaff;
            }
          },
          onError: (e) {
            debugPrint('Realtime staff listener error: $e');
            _startRestPollingFallback(staffDocId);
          },
        );
      } else {
        _startRestPollingFallback(staffDocId);
      }
    } catch (e) {
      debugPrint('Realtime listener init error: $e');
      _startRestPollingFallback(staffDocId);
    }
  }

  /// REST polling fallback (queries every 3 seconds if Firestore SDK snapshot is unavailable)
  void _startRestPollingFallback(String staffDocId) {
    _restPollTimer?.cancel();
    _restPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (currentStaff == null || currentStaff!.id != staffDocId) {
        _restPollTimer?.cancel();
        return;
      }
      try {
        final url =
            'https://firestore.googleapis.com/v1/projects/staff-checkin-b4972/databases/(default)/documents/Staff/$staffDocId';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final docMap = jsonDecode(response.body) as Map<String, dynamic>;
          final fields = docMap['fields'] as Map<String, dynamic>? ?? {};
          final parsed = _parseFirestoreFields(fields);
          final updated = StaffUserModel.fromMap(parsed, staffDocId);
          if (currentStaff?.isKioskMode != updated.isKioskMode ||
              currentStaff?.isActive != updated.isActive) {
            debugPrint(
                'REST Poll Realtime Update: isKioskMode=${updated.isKioskMode}');
            currentStaff = updated;
          }
        }
      } catch (_) {}
    });
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
      // 1. Primary Query via Firestore SDK with timeout (if SDK available)
      QuerySnapshot<Map<String, dynamic>>? snapshot;
      final firestore = _firestore;

      if (firestore != null) {
        try {
          snapshot = await firestore
              .collection('Staff')
              .where('pinCode', isEqualTo: trimmedPin)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 4));

          // Fallback 1: Check if pinCode was stored as number
          if (snapshot.docs.isEmpty) {
            final intPin = int.tryParse(trimmedPin);
            if (intPin != null) {
              snapshot = await firestore
                  .collection('Staff')
                  .where('pinCode', isEqualTo: intPin)
                  .limit(1)
                  .get()
                  .timeout(const Duration(seconds: 4));
            }
          }

          // Fallback 2: Check lowercase 'staff' collection name
          if (snapshot.docs.isEmpty) {
            snapshot = await firestore
                .collection('staff')
                .where('pinCode', isEqualTo: trimmedPin)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 4));
          }
        } catch (e) {
          debugPrint('Firestore SDK auth attempt error/timeout: $e');
          snapshot = null;
        }
      }

      // If document found via Firestore SDK
      if (snapshot != null && snapshot.docs.isNotEmpty) {
        final staffDoc = snapshot.docs.first;
        final staff = StaffUserModel.fromFirestore(staffDoc);

        if (!staff.isActive) {
          return StaffAuthResult(
            status: StaffAuthStatus.inactiveAccount,
            staff: staff,
            message:
                'Account for ${staff.fullName} (ID: ${staff.staffId}) is currently inactive. Please contact your manager or administrator.',
          );
        }

        currentStaff = staff;
        _startRealtimeStaffListener(staffDoc.id);
        return StaffAuthResult(
          status: StaffAuthStatus.success,
          staff: staff,
          message: 'Welcome, ${staff.fullName}!',
        );
      }

      // 2. High-speed REST fallback (crucial for Web & network edge cases)
      final restResult = await _authenticateWithPinRest(trimmedPin);
      if (restResult != null) {
        return restResult;
      }

      // Check if no staff record was found
      return const StaffAuthResult(
        status: StaffAuthStatus.invalidPin,
        message:
            'Invalid PIN. No staff found with this PIN. Please check and try again.',
      );
    } on FirebaseException catch (e) {
      debugPrint('Firestore PIN verification error: ${e.code} - ${e.message}');
      final restResult = await _authenticateWithPinRest(trimmedPin);
      if (restResult != null) return restResult;

      return StaffAuthResult(
        status: StaffAuthStatus.error,
        message: 'Firestore connection error: ${e.message ?? e.code}',
      );
    } catch (e) {
      debugPrint('General error during PIN verification: $e');
      final restResult = await _authenticateWithPinRest(trimmedPin);
      if (restResult != null) return restResult;

      return StaffAuthResult(
        status: StaffAuthStatus.error,
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  /// REST fallback to query Firestore Staff collection directly over HTTP
  Future<StaffAuthResult?> _authenticateWithPinRest(String trimmedPin) async {
    try {
      const url =
          'https://firestore.googleapis.com/v1/projects/staff-checkin-b4972/databases/(default)/documents/Staff';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('Firestore REST returned status: ${response.statusCode}');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final documents = body['documents'] as List<dynamic>?;
      if (documents == null || documents.isEmpty) {
        return null;
      }

      for (final docItem in documents) {
        final docMap = docItem as Map<String, dynamic>;
        final docName = docMap['name'] as String? ?? '';
        final docId = docName.split('/').last;
        final fields = docMap['fields'] as Map<String, dynamic>? ?? {};
        final parsedMap = _parseFirestoreFields(fields);

        final staff = StaffUserModel.fromMap(parsedMap, docId);
        final staffPin = staff.pinCode.trim();

        if (staffPin == trimmedPin) {
          if (!staff.isActive) {
            return StaffAuthResult(
              status: StaffAuthStatus.inactiveAccount,
              staff: staff,
              message:
                  'Account for ${staff.fullName} (ID: ${staff.staffId}) is currently inactive. Please contact your manager or administrator.',
            );
          }

          currentStaff = staff;
          _startRealtimeStaffListener(docId);
          return StaffAuthResult(
            status: StaffAuthStatus.success,
            staff: staff,
            message: 'Welcome, ${staff.fullName}!',
          );
        }
      }
    } catch (e) {
      debugPrint('REST PIN verification notice: $e');
    }
    return null;
  }

  Map<String, dynamic> _parseFirestoreFields(Map<String, dynamic> fields) {
    final Map<String, dynamic> result = {};
    fields.forEach((key, val) {
      final trimmedKey = key.trim();
      dynamic parsedVal;
      if (val is Map<String, dynamic>) {
        if (val.containsKey('stringValue')) {
          parsedVal = val['stringValue'];
        } else if (val.containsKey('booleanValue')) {
          parsedVal = val['booleanValue'];
        } else if (val.containsKey('integerValue')) {
          parsedVal =
              int.tryParse(val['integerValue'].toString()) ?? val['integerValue'];
        } else if (val.containsKey('doubleValue')) {
          parsedVal = (val['doubleValue'] as num).toDouble();
        } else if (val.containsKey('timestampValue')) {
          parsedVal = val['timestampValue'];
        }
      }
      result[key] = parsedVal;
      result[trimmedKey] = parsedVal;
    });
    return result;
  }

  void logout() {
    _staffSubscription?.cancel();
    _restPollTimer?.cancel();
    _staffSubscription = null;
    _restPollTimer = null;
    currentStaff = null;
  }
}
