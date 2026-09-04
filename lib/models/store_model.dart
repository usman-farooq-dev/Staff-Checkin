import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String country;
  final double lat;
  final double lng;
  final bool isActive;

  const StoreModel({
    required this.id,
    required this.name,
    this.address = '',
    this.city = '',
    this.country = '',
    this.lat = 0.0,
    this.lng = 0.0,
    this.isActive = true,
  });

  factory StoreModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return StoreModel.fromMap(doc.data() ?? {}, doc.id);
  }

  factory StoreModel.fromMap(Map<String, dynamic> data, String id) {
    return StoreModel(
      id: id,
      name: data['name'] as String? ?? data['storeName'] as String? ?? 'Store',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      country: data['country'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'country': country,
      'lat': lat,
      'lng': lng,
      'isActive': isActive,
    };
  }

  bool get hasValidCoordinates => lat != 0.0 && lng != 0.0;
}
