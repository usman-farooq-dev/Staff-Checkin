import 'package:cloud_firestore/cloud_firestore.dart';

enum PermissionState { granted, blocked, denied }

class StaffUserModel {
  final String id;
  final String fullName;
  final String staffId;
  final String storeId;
  final String storeName;
  final String designation;
  final String shift;
  final String phone;
  final String imageUrl;
  final String pinCode;
  final bool isActive;
  final dynamic createdAt;

  final PermissionState notificationPermission;
  final PermissionState cameraPermission;
  final PermissionState locationPermission;
  final int pendingUploads;
  final String kioskMode;
  final bool isKioskMode;
  final String uploadDestination;
  final String appVersion;

  const StaffUserModel({
    required this.id,
    required this.fullName,
    required this.staffId,
    this.storeId = '',
    this.storeName = 'Islamabad Store',
    this.designation = 'Staff',
    this.shift = 'Morning',
    this.phone = '',
    this.imageUrl = '',
    this.pinCode = '',
    this.isActive = true,
    this.createdAt,
    this.notificationPermission = PermissionState.blocked,
    this.cameraPermission = PermissionState.blocked,
    this.locationPermission = PermissionState.blocked,
    this.pendingUploads = 0,
    this.kioskMode = 'Managed by store admin',
    this.isKioskMode = true,
    this.uploadDestination = 'Company Cloud Storage',
    this.appVersion = '1.4.0 (85)',
  });

  // Getter for backward compatibility with 'name'
  String get name => fullName;

  factory StaffUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return StaffUserModel.fromMap(data, doc.id);
  }

  static bool _parseKioskMode(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final cleanKey = entry.key.trim().toLowerCase().replaceAll('_', '');
      if (cleanKey == 'iskioskmode' ||
          cleanKey == 'kioskmode' ||
          cleanKey == 'iskiosk') {
        final val = entry.value;
        if (val is bool) return val;
        if (val is num) return val != 0;
        if (val is String) {
          final lower = val.trim().toLowerCase();
          if (lower == 'false' ||
              lower == '0' ||
              lower == 'disabled' ||
              lower == 'off' ||
              lower == 'no') {
            return false;
          }
          if (lower == 'true' ||
              lower == '1' ||
              lower == 'enabled' ||
              lower == 'on' ||
              lower == 'yes') {
            return true;
          }
        }
      }
    }
    // Default is true if missing or null in DB
    return true;
  }

  factory StaffUserModel.fromMap(Map<String, dynamic> data, [String id = '']) {
    return StaffUserModel(
      id: id.isNotEmpty ? id : (data['id'] as String? ?? ''),
      fullName: data['fullName'] as String? ?? data['name'] as String? ?? 'Staff Member',
      staffId: data['staffId'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? 'Islamabad Store',
      designation: data['designation'] as String? ?? 'Staff',
      shift: data['shift'] as String? ?? 'Morning',
      phone: data['phone'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      pinCode: data['pinCode']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: data['createdAt'],
      pendingUploads: (data['pendingUploads'] as num?)?.toInt() ?? 0,
      kioskMode: data['kioskMode'] as String? ?? 'Managed by store admin',
      isKioskMode: _parseKioskMode(data),
      uploadDestination: data['uploadDestination'] as String? ?? 'Company Cloud Storage',
      appVersion: data['appVersion'] as String? ?? '1.4.0 (85)',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'staffId': staffId,
      'storeId': storeId,
      'storeName': storeName,
      'designation': designation,
      'shift': shift,
      'phone': phone,
      'imageUrl': imageUrl,
      'pinCode': pinCode,
      'isActive': isActive,
      'isKioskMode': isKioskMode,
      'createdAt': createdAt,
    };
  }

  StaffUserModel copyWith({
    String? id,
    String? fullName,
    String? staffId,
    String? storeId,
    String? storeName,
    String? designation,
    String? shift,
    String? phone,
    String? imageUrl,
    String? pinCode,
    bool? isActive,
    dynamic createdAt,
    PermissionState? notificationPermission,
    PermissionState? cameraPermission,
    PermissionState? locationPermission,
    int? pendingUploads,
    String? kioskMode,
    bool? isKioskMode,
    String? uploadDestination,
    String? appVersion,
  }) {
    return StaffUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      staffId: staffId ?? this.staffId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      designation: designation ?? this.designation,
      shift: shift ?? this.shift,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      pinCode: pinCode ?? this.pinCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      notificationPermission: notificationPermission ?? this.notificationPermission,
      cameraPermission: cameraPermission ?? this.cameraPermission,
      locationPermission: locationPermission ?? this.locationPermission,
      pendingUploads: pendingUploads ?? this.pendingUploads,
      kioskMode: kioskMode ?? this.kioskMode,
      isKioskMode: isKioskMode ?? this.isKioskMode,
      uploadDestination: uploadDestination ?? this.uploadDestination,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
