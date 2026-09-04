import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/store_model.dart';
import 'staff_auth_service.dart';

class StoreService {
  StoreService._() {
    // Automatically load store details whenever current logged in staff changes
    StaffAuthService.instance.currentStaffNotifier.addListener(_onStaffChanged);
    _onStaffChanged();
  }
  static final StoreService instance = StoreService._();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static const String _collectionName = 'Stores';

  final Map<String, StoreModel> _storeCache = {};
  final ValueNotifier<StoreModel?> currentStoreNotifier =
      ValueNotifier<StoreModel?>(null);

  StoreModel? get currentStore => currentStoreNotifier.value;

  void _onStaffChanged() {
    final staff = StaffAuthService.instance.currentStaff;
    if (staff == null || staff.storeId.isEmpty) {
      currentStoreNotifier.value = null;
    } else {
      getStoreDetails(staff.storeId).then((store) {
        currentStoreNotifier.value = store;
      });
    }
  }

  /// Fetch full store details (including name, address, city, lat, lng)
  Future<StoreModel?> getStoreDetails(String storeId) async {
    if (storeId.isEmpty) return null;
    if (_storeCache.containsKey(storeId)) return _storeCache[storeId];

    // 1. Try Firestore SDK
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final doc =
            await firestore.collection(_collectionName).doc(storeId).get();
        if (doc.exists && doc.data() != null) {
          final store = StoreModel.fromFirestore(doc);
          _storeCache[storeId] = store;
          return store;
        }
      } catch (e) {
        debugPrint('StoreService Firestore get error: $e');
      }
    }

    // 2. High-speed REST fallback (works on Web & offline SDK edge cases)
    try {
      final url =
          'https://firestore.googleapis.com/v1/projects/staff-checkin-b4972/databases/(default)/documents/Stores/$storeId';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final fields = body['fields'] as Map<String, dynamic>? ?? {};
        final parsedMap = _parseFirestoreFields(fields);
        final store = StoreModel.fromMap(parsedMap, storeId);
        _storeCache[storeId] = store;
        return store;
      }
    } catch (e) {
      debugPrint('StoreService REST get notice: $e');
    }

    return null;
  }

  /// Fetch store city from Firestore 'Stores' collection
  Future<String> getStoreCity(String storeId,
      {String fallbackCity = 'Islamabad'}) async {
    if (storeId.isEmpty) return fallbackCity;
    final store = await getStoreDetails(storeId);
    if (store != null && store.city.isNotEmpty) {
      return store.city;
    }
    return fallbackCity;
  }

  /// Realtime stream for store city
  Stream<String> streamStoreCity(String storeId,
      {String fallbackCity = 'Islamabad'}) {
    if (storeId.isEmpty) return Stream.value(fallbackCity);

    final firestore = _firestore;
    if (firestore == null) return Stream.value(fallbackCity);

    return firestore
        .collection(_collectionName)
        .doc(storeId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data() ?? {};
        final city = data['city'] as String? ??
            data['location'] as String? ??
            data['storeName'] as String? ??
            fallbackCity;
        return city;
      }
      return fallbackCity;
    });
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
        }
      }
      result[key] = parsedVal;
      result[trimmedKey] = parsedVal;
    });
    return result;
  }
}
