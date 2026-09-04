import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/store_model.dart';
import 'permission_service.dart';

class LocationCheckResult {
  final bool isWithinGeofence;
  final double distanceMeters;
  final double? userLat;
  final double? userLng;
  final String? errorMessage;

  const LocationCheckResult({
    required this.isWithinGeofence,
    required this.distanceMeters,
    this.userLat,
    this.userLng,
    this.errorMessage,
  });
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const MethodChannel _channel =
      MethodChannel('com.staff.checkin/location');

  /// Maximum allowed distance from store in meters (2 km as specified by user: "within 1 km hona chiya agr within 2 km na ho to alert show kra do")
  static const double maxAllowedDistanceMeters = 2000.0;

  /// Whether to bypass geofence location verification (currently bypassed per user instruction)
  static bool bypassLocationCheck = true;

  /// Calculate Haversine distance between two coordinates in meters
  double calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000.0; // in meters
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Get current device latitude and longitude
  Future<Map<String, double>?> getCurrentCoordinates() async {
    // 1. Check and request location permission
    final hasPermission = await PermissionService.requestLocationPermission();
    if (!hasPermission) {
      debugPrint('Location permission not granted');
      return null;
    }

    // 2. Query platform channel if on Android
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod('getCurrentLocation');
        if (result is Map) {
          final lat = (result['lat'] as num?)?.toDouble();
          final lng = (result['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            return {'lat': lat, 'lng': lng};
          }
        }
      } catch (e) {
        debugPrint('Error getting location from platform channel: $e');
      }
    }

    return null;
  }

  /// Verify if user is within the store's 1-2 km geofence
  Future<LocationCheckResult> verifyStoreGeofence({
    required StoreModel? store,
    double maxDistanceMeters = maxAllowedDistanceMeters,
  }) async {
    // If bypass is active, or no store or no coordinates are set on the store, allow check-in
    if (bypassLocationCheck || store == null || !store.hasValidCoordinates) {
      return const LocationCheckResult(
        isWithinGeofence: true,
        distanceMeters: 0,
      );
    }

    // Ensure permission is granted
    final hasPermission = await PermissionService.requestLocationPermission();
    if (!hasPermission) {
      return const LocationCheckResult(
        isWithinGeofence: false,
        distanceMeters: -1,
        errorMessage:
            'Location permission is required to verify you are at your assigned store.',
      );
    }

    final coords = await getCurrentCoordinates();
    if (coords == null) {
      // In emulator or offline where GPS hasn't locked yet, allow grace or report
      debugPrint('GPS coordinates currently unavailable');
      return const LocationCheckResult(
        isWithinGeofence: true,
        distanceMeters: 0,
      );
    }

    final userLat = coords['lat']!;
    final userLng = coords['lng']!;
    final distance = calculateDistanceInMeters(
      userLat,
      userLng,
      store.lat,
      store.lng,
    );

    if (distance > maxDistanceMeters) {
      final kmDist = (distance / 1000).toStringAsFixed(1);
      return LocationCheckResult(
        isWithinGeofence: false,
        distanceMeters: distance,
        userLat: userLat,
        userLng: userLng,
        errorMessage:
            'You are outside your assigned store perimeter ($kmDist km away from ${store.name}). You must be at the store to perform this check.',
      );
    }

    return LocationCheckResult(
      isWithinGeofence: true,
      distanceMeters: distance,
      userLat: userLat,
      userLng: userLng,
    );
  }
}
