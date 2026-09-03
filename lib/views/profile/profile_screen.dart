import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../models/staff_user_model.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  DevicePermissionsState _permissions = const DevicePermissionsState(
    notificationGranted: false,
    cameraGranted: false,
    locationGranted: false,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await PermissionService.checkAllPermissions();
    if (mounted) {
      setState(() {
        _permissions = status;
      });
    }
  }

  Future<void> _handleReviewPermissions() async {
    final updated = await PermissionService.reviewAndRequestAllPermissions();
    if (mounted) {
      setState(() {
        _permissions = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StaffUserModel?>(
      valueListenable: StaffAuthService.instance.currentStaffNotifier,
      builder: (context, currentStaff, _) {
        final user = currentStaff ??
            const StaffUserModel(
              id: '1',
              fullName: 'Ahmed Khan',
              staffId: 'ST-100',
              storeName: 'Islamabad Store',
              shift: 'Morning',
              appVersion: '1.4.0 (312)',
            );

        final staffDisplayName =
            user.fullName.isNotEmpty ? user.fullName : 'Staff Member';
        final staffSubtitle =
            'Staff ID ${user.staffId.isNotEmpty ? user.staffId : "N/A"} • ${user.storeName.isNotEmpty ? user.storeName : "Islamabad Store"}';

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'Profile',
                    style: AppStyles.heading1.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Top Horizontal Divider Line
                const Divider(
                  color: AppColors.cardBorderSubtle,
                  thickness: 1.2,
                  height: 1.2,
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Staff Profile Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgWarm,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.cardBorder,
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  AppAssets.icProfileIcon,
                                  width: 26,
                                  height: 26,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staffDisplayName,
                                    style: AppStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    staffSubtitle,
                                    style: AppStyles.bodySmall.copyWith(
                                      color: const Color(0xFF5B6471),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section: Device access
                      Text(
                        'Device access',
                        style: AppStyles.caption.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgWarm,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildAccessRow(
                              iconAsset: AppAssets.icNotificationGray,
                              title: 'Notifications',
                              isAllowed: _permissions.notificationGranted,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                              thickness: 1,
                            ),
                            _buildAccessRow(
                              iconAsset: AppAssets.icCameraGray,
                              title: 'Camera permission',
                              isAllowed: _permissions.cameraGranted,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                              thickness: 1,
                            ),
                            _buildAccessRow(
                              iconAsset: AppAssets.icMarker,
                              title: 'Location permission',
                              isAllowed: _permissions.locationGranted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Permissions Action: If all granted, hide button & show green allowed status
                      if (_permissions.allGranted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8EF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFC6E7D2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF15803D),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'All device permissions allowed',
                                style: TextStyle(
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // REVIEW PERMISSIONS Button
                        CustomButton(
                          text: 'REVIEW PERMISSIONS',
                          width: 190,
                          height: 42,
                          borderRadius: 8,
                          onPressed: _handleReviewPermissions,
                        ),

                      const SizedBox(height: 20),

                      // Section: Uploads
                      Text(
                        'Uploads',
                        style: AppStyles.caption.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgWarm,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  AppAssets.icUpload,
                                  width: 18,
                                  height: 18,
                                  color: const Color(0xFF475569),
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Pending uploads',
                                  style: AppStyles.bodyLarge.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${user.pendingUploads}',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: const Color(0xFF5B6471),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset(
                                  AppAssets.icForward,
                                  width: 13,
                                  height: 13,
                                  color: const Color(0xFF64748B),
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section: Device
                      Text(
                        'Device',
                        style: AppStyles.caption.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgWarm,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDeviceInfoRow(
                              iconAsset: AppAssets.icLock,
                              label: 'Kiosk\nmode',
                              value: user.kioskMode,
                              valueColor: const Color(0xFF15803D),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                              thickness: 1,
                            ),
                            _buildDeviceInfoRow(
                              iconAsset: null,
                              label: 'Upload\ndestination',
                              value: user.uploadDestination,
                              valueColor: const Color(0xFF475569),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                              thickness: 1,
                            ),
                            _buildDeviceInfoRow(
                              iconAsset: null,
                              label: 'App version',
                              value: user.appVersion,
                              valueColor: const Color(0xFF5B6471),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SWITCH STAFF Button
                      Material(
                        color: AppColors.cardBgWarm,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            StaffAuthService.instance.logout();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.pin,
                              (route) => false,
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.cardBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppAssets.icLogout,
                                  width: 18,
                                  height: 18,
                                  color: AppColors.textPrimary,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SWITCH STAFF',
                                  style: AppStyles.buttonText.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessRow({
    required String iconAsset,
    required String title,
    required bool isAllowed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                iconAsset,
                width: 16,
                height: 16,
                color: const Color(0xFF475569),
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppStyles.bodyLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            isAllowed ? 'Allowed' : 'Blocked',
            style: AppStyles.bodyLarge.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isAllowed
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB9381E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow({
    String? iconAsset,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (iconAsset != null) ...[
                Image.asset(
                  iconAsset,
                  width: 16,
                  height: 16,
                  color: const Color(0xFF475569),
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
