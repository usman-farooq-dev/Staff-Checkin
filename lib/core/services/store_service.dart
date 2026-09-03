import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StoreService {
  StoreService._();
  static final StoreService instance = StoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Stores';

  final Map<String, String> _cityCache = {};

  /// Fetch store city from Firestore 'Stores' collection
  Future<String> getStoreCity(String storeId, {String fallbackCity = 'Islamabad'}) async {
    if (storeId.isEmpty) return fallbackCity;
    if (_cityCache.containsKey(storeId)) return _cityCache[storeId]!;

    try {
      final doc = await _firestore.collection(_collectionName).doc(storeId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final city = data['city'] as String? ??
            data['location'] as String? ??
            data['storeName'] as String? ??
            fallbackCity;
        _cityCache[storeId] = city;
        return city;
      }
    } catch (e) {
      debugPrint('Error fetching store city: $e');
    }

    return fallbackCity;
  }

  /// Realtime stream for store city
  Stream<String> streamStoreCity(String storeId, {String fallbackCity = 'Islamabad'}) {
    if (storeId.isEmpty) return Stream.value(fallbackCity);

    return _firestore.collection(_collectionName).doc(storeId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data() ?? {};
        final city = data['city'] as String? ??
            data['location'] as String? ??
            data['storeName'] as String? ??
            fallbackCity;
        _cityCache[storeId] = city;
        return city;
      }
      return fallbackCity;
    });
  }
}
