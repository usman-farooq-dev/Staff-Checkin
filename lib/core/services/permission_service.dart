import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class DevicePermissionsState {
  final bool notificationGranted;
  final bool cameraGranted;
  final bool locationGranted;

  const DevicePermissionsState({
    required this.notificationGranted,
    required this.cameraGranted,
    required this.locationGranted,
  });

  bool get allGranted =>
      notificationGranted && cameraGranted && locationGranted;
}

class PermissionService {
  PermissionService._();

  /// Check all 3 device permission statuses (Notification, Camera, Location)
  static Future<DevicePermissionsState> checkAllPermissions() async {
    bool notif = false;
    bool cam = false;
    bool loc = false;

    try {
      final notifStatus = await Permission.notification.status;
      notif = notifStatus.isGranted || notifStatus.isProvisional;
    } catch (_) {}

    try {
      final camStatus = await Permission.camera.status;
      cam = camStatus.isGranted || camStatus.isLimited;
    } catch (_) {}

    try {
      final locStatus = await Permission.location.status;
      loc = locStatus.isGranted || locStatus.isLimited;
    } catch (_) {}

    return DevicePermissionsState(
      notificationGranted: notif,
      cameraGranted: cam,
      locationGranted: loc,
    );
  }

  /// Request Notification permission directly, or open system settings if permanently denied / not granted
  static Future<bool> requestNotificationPermission() async {
    try {
      final notifStatus = await Permission.notification.status;
      if (notifStatus.isGranted || notifStatus.isProvisional) {
        return true;
      }

      final requested = await Permission.notification.request();
      if (requested.isGranted || requested.isProvisional) {
        return true;
      }

      // If denied or permanently denied, open app settings so user can toggle notification directly
      await openAppSettings();
      final finalStatus = await Permission.notification.status;
      return finalStatus.isGranted || finalStatus.isProvisional;
    } catch (e) {
      debugPrint('Notification permission request notice: $e');
      await openAppSettings();
      return false;
    }
  }

  /// Request Camera and Microphone
  static Future<bool> checkAndRequestCameraPermission([dynamic context]) async {
    try {
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isGranted || cameraStatus.isLimited) {
        return true;
      }

      final requestedStatus = await Permission.camera.request();
      Permission.microphone.request();

      if (requestedStatus.isPermanentlyDenied) {
        await openAppSettings();
      }

      return requestedStatus.isGranted ||
          requestedStatus.isLimited ||
          requestedStatus.isProvisional;
    } catch (e) {
      debugPrint('Camera permission request notice: $e');
      return true;
    }
  }

  /// Request Location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }
      final requested = await Permission.location.request();
      if (requested.isPermanentlyDenied) {
        await openAppSettings();
      }
      return requested.isGranted || requested.isLimited;
    } catch (e) {
      debugPrint('Location permission request notice: $e');
      return false;
    }
  }

  /// Request all missing permissions, or open system settings if permanently denied / not granted
  static Future<DevicePermissionsState> reviewAndRequestAllPermissions() async {
    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted && !notifStatus.isProvisional) {
        await Permission.notification.request();
      }

      final camStatus = await Permission.camera.status;
      if (!camStatus.isGranted && !camStatus.isLimited) {
        await Permission.camera.request();
        Permission.microphone.request();
      }

      final locStatus = await Permission.location.status;
      if (!locStatus.isGranted && !locStatus.isLimited) {
        await Permission.location.request();
      }

      final current = await checkAllPermissions();
      if (!current.allGranted) {
        // If still not all granted, take user directly to settings page
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('Error reviewing permissions: $e');
      await openAppSettings();
    }

    return await checkAllPermissions();
  }
}
