import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/core/constants/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify all image assets exist in bundle', () async {
    final List<String> assets = [
      AppAssets.icStaffCheckin,
      AppAssets.icBack,
      AppAssets.icForward,
      AppAssets.icCross,
      AppAssets.icComplete,
      AppAssets.icMissed,
      AppAssets.icWarning,
      AppAssets.icMarker,
      AppAssets.icLock,
      AppAssets.icLogout,
      AppAssets.icUpload,
      AppAssets.icProfileIcon,
      AppAssets.icHorizontalDivider,
      AppAssets.icCameraBrown,
      AppAssets.icCameraGray,
      AppAssets.icNotificationGray,
      AppAssets.icNotificationWhite,
      AppAssets.navHomeSelected,
      AppAssets.navHomeNon,
      AppAssets.navTaskSelected,
      AppAssets.navTaskNon,
      AppAssets.navHistorySelected,
      AppAssets.navHistoryNon,
      AppAssets.navProfileSelected,
      AppAssets.navProfileNon,
    ];

    for (final asset in assets) {
      final ByteData data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: '$asset is empty or missing');
    }
  });
}
