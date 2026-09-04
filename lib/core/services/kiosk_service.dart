import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'staff_auth_service.dart';

/// Service managing device-level Kiosk Mode (Lock Task Mode / Immersive Screen Pinning)
class KioskService with WidgetsBindingObserver {
  KioskService._();
  static final KioskService instance = KioskService._();

  static const MethodChannel _channel =
      MethodChannel('com.staff.checkin/kiosk');

  bool _isKioskActive = false;
  bool get isKioskActive => _isKioskActive;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    // Automatically synchronize kiosk state whenever staff user changes
    StaffAuthService.instance.currentStaffNotifier.addListener(_onStaffChanged);

    // Initial check: only lock if an active staff member has isKioskMode true
    final initialStaff = StaffAuthService.instance.currentStaff;
    final shouldBeKiosk = initialStaff != null && initialStaff.isKioskMode;
    if (shouldBeKiosk) {
      await startKiosk();
    } else {
      await stopKiosk();
    }
  }

  void _onStaffChanged() {
    final currentStaff = StaffAuthService.instance.currentStaff;
    // Lock ONLY when a staff member is logged in AND isKioskMode is true.
    // When staff is logged out (currentStaff == null), device is completely unlocked.
    final shouldBeKiosk = currentStaff != null && currentStaff.isKioskMode;

    if (shouldBeKiosk) {
      startKiosk();
    } else {
      stopKiosk();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isKioskActive) {
      // Re-enforce kiosk UI & lock task when app resumes
      _enforceKioskUi();
      _startPlatformLockTask();
    }
  }

  /// Lock device into Kiosk mode (start lock task, hide nav & status bars, block minimize)
  Future<void> startKiosk() async {
    _isKioskActive = true;
    await _enforceKioskUi();
    await _startPlatformLockTask();
  }

  /// Unlock device from Kiosk mode (stop lock task, restore system navigation)
  Future<void> stopKiosk() async {
    _isKioskActive = false;
    await _restoreNormalUi();
    await _stopPlatformLockTask();
  }

  Future<void> _startPlatformLockTask() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('startLockTask');
      } catch (e) {
        debugPrint('KioskService startLockTask notice: $e');
      }
    }
  }

  Future<void> _stopPlatformLockTask() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('stopLockTask');
      } catch (e) {
        debugPrint('KioskService stopLockTask notice: $e');
      }
    }
  }

  Future<void> _enforceKioskUi() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    } catch (e) {
      debugPrint('KioskService immersiveSticky error: $e');
    }
  }

  Future<void> _restoreNormalUi() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    } catch (e) {
      debugPrint('KioskService restore UI error: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StaffAuthService.instance.currentStaffNotifier
        .removeListener(_onStaffChanged);
  }
}
