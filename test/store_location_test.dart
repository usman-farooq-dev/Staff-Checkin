import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/core/services/location_service.dart';
import 'package:staff_checkin/models/store_model.dart';

void main() {
  group('StoreModel Tests', () {
    test('StoreModel parses coordinates and properties correctly', () {
      final store = StoreModel.fromMap({
        'name': 'Islamabad I8 Markaz Branch',
        'address': 'I-8 Markaz',
        'city': 'Islamabad',
        'lat': 33.6684,
        'lng': 73.0758,
        'isActive': true,
      }, '14kXk65BydERfs7eFCk4');

      expect(store.id, '14kXk65BydERfs7eFCk4');
      expect(store.name, 'Islamabad I8 Markaz Branch');
      expect(store.lat, 33.6684);
      expect(store.lng, 73.0758);
      expect(store.hasValidCoordinates, isTrue);
    });

    test('StoreModel defaults coordinates to 0.0 when missing', () {
      final store = StoreModel.fromMap({
        'name': 'Store without coords',
      }, 'no_coords');

      expect(store.hasValidCoordinates, isFalse);
    });
  });

  group('LocationService Distance & Geofence Tests', () {
    test('calculateDistanceInMeters calculates exact distance within meters', () {
      final locService = LocationService.instance;

      // Distance between Islamabad I-8 (33.6684, 73.0758) and nearby point (~500m away)
      // 0.0045 degrees lat is approximately 500 meters
      final dist500m = locService.calculateDistanceInMeters(
        33.6684,
        73.0758,
        33.6729,
        73.0758,
      );
      expect(dist500m, greaterThan(450));
      expect(dist500m, lessThan(550));

      // Same coordinates should have 0 distance
      final dist0 = locService.calculateDistanceInMeters(
        33.6684,
        73.0758,
        33.6684,
        73.0758,
      );
      expect(dist0, 0.0);

      // Far distance: Islamabad (33.6684, 73.0758) to Karachi (24.8138, 67.0336) is ~1140 km
      final distFar = locService.calculateDistanceInMeters(
        33.6684,
        73.0758,
        24.8138,
        67.0336,
      );
      expect(distFar, greaterThan(1100000)); // > 1,100 km
    });

    test('verifyStoreGeofence allows check when store has no coordinates', () async {
      final locService = LocationService.instance;
      const storeWithoutCoords = StoreModel(
        id: '1',
        name: 'No Coords Store',
      );

      final result = await locService.verifyStoreGeofence(store: storeWithoutCoords);
      expect(result.isWithinGeofence, isTrue);
    });
  });
}
