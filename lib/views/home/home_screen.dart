import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/scheduled_checkin_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../core/services/store_service.dart';
import '../../models/scheduled_checkin_model.dart';
import '../../models/staff_user_model.dart';
import '../../widgets/compliance_card.dart';
import '../../widgets/progress_bar_widget.dart';
import '../alert/compliance_alert_dialog.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTasks;

  const HomeScreen({super.key, this.onNavigateToTasks});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _currentTime;
  Timer? _clockTimer;
  bool _isNotificationGranted = true;

  // Track automatic popup alert state
  bool _isAlertShowing = false;
  String _lastTriggeredAlertKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTime = DateTime.now();

    // 1. Realtime clock ticking timer (updates every second)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // 2. Request Location Permission automatically on home load
    _requestLocationPermission();

    // 3. Check Notification Permission status
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      final isGranted = status.isGranted || status.isProvisional;
      if (mounted) {
        setState(() {
          _isNotificationGranted = isGranted;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestLocationPermission() async {
    try {
      await PermissionService.requestLocationPermission();
    } catch (_) {}
  }

  Future<void> _handleEnableNotifications() async {
    final granted = await PermissionService.requestNotificationPermission();
    if (mounted) {
      setState(() {
        _isNotificationGranted = granted;
      });

      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Notifications enabled successfully!'),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Automatically prompt fullscreen compliance alert when scheduled time arrives (ONLY if staff is logged in and active)
  void _checkAndTriggerScheduledAlert(
    List<ScheduledCheckInModel> pendingChecks,
    String storeId,
  ) {
    // 1. Staff MUST be actively authenticated
    final staff = StaffAuthService.instance.currentStaff;
    if (staff == null || !staff.isActive || storeId.isEmpty) {
      return;
    }

    if (_isAlertShowing || pendingChecks.isEmpty) return;

    for (final check in pendingChecks) {
      if (check.shouldTriggerAlertForStore(storeId)) {
        final alertKey = '${check.id}_${check.remindAt[storeId] ?? 0}';
        if (_lastTriggeredAlertKey == alertKey) return;

        _lastTriggeredAlertKey = alertKey;
        _isAlertShowing = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          // Re-verify login before popping up alert
          if (!StaffAuthService.instance.isLoggedIn) {
            _isAlertShowing = false;
            return;
          }

          await ComplianceAlertScreen.show(
            context,
            check: check,
            storeId: storeId,
          );
          if (mounted) {
            _isAlertShowing = false;
          }
        });
        break;
      }
    }
  }

  String _formatTodayDate(DateTime now) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, $monthName ${now.day}';
  }

  String _formatCurrentTime(DateTime now) {
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final now = _currentTime;

    return ValueListenableBuilder<StaffUserModel?>(
      valueListenable: StaffAuthService.instance.currentStaffNotifier,
      builder: (context, currentStaff, _) {
        final displayName = currentStaff?.fullName.split(' ').first ?? 'Staff';
        final storeId = currentStaff?.storeId ?? '';
        final defaultCity = currentStaff?.storeName.isNotEmpty == true
            ? currentStaff!.storeName
            : 'Islamabad';

        return SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTodayDate(now),
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Good Evening, $displayName',
                        style: AppStyles.heading1.copyWith(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Store City Label with Marker icon
                      StreamBuilder<String>(
                        stream: StoreService.instance.streamStoreCity(
                          storeId,
                          fallbackCity: defaultCity,
                        ),
                        initialData: defaultCity,
                        builder: (context, citySnapshot) {
                          final city = citySnapshot.data ?? defaultCity;

                          return Row(
                            children: [
                              Image.asset(
                                AppAssets.icMarker,
                                width: 14,
                                height: 14,
                                color: AppColors.textSecondary,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                city,
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Realtime Time Badge Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.timeBadgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.timeBadgeBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          _formatCurrentTime(now),
                          style: AppStyles.heading2.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: 19,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider 1 (Dashed ticket line)
                Image.asset(
                  AppAssets.icHorizontalDivider,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),

                // Next Check Dark Hero Card (Connected to Scheduled_CheckIn Firestore)
                StreamBuilder<List<ScheduledCheckInModel>>(
                  stream: ScheduledCheckInService.instance
                      .streamTodaysPendingChecks(storeId: storeId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      );
                    }

                    final pendingChecks = snapshot.data ?? [];

                    // Automatically trigger compliance alert dialog if scheduled time arrived or snooze passed
                    _checkAndTriggerScheduledAlert(pendingChecks, storeId);

                    if (pendingChecks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: NoPendingCheckCard(),
                      );
                    }

                    // First one in ascending order
                    final nextCheck = pendingChecks.first;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: DarkNextCheckCard(
                        time: nextCheck.formattedTime,
                        title: nextCheck.title,
                        subtitle: nextCheck.heroSubtitle,
                        onStartCheck: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.checklist,
                            arguments: nextCheck,
                          );
                        },
                      ),
                    );
                  },
                ),

                // Divider 2 (Dashed ticket line)
                Image.asset(
                  AppAssets.icHorizontalDivider,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),

                // Today's Progress Card (Dynamically computed from today's Scheduled_CheckIn collection)
                StreamBuilder<TodaysProgressModel>(
                  stream: ScheduledCheckInService.instance
                      .streamTodaysProgress(storeId: storeId),
                  builder: (context, snapshot) {
                    final progress = snapshot.data ??
                        const TodaysProgressModel(
                          totalScheduled: 0,
                          completedScheduled: 0,
                        );

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SegmentedProgressBar(
                        totalSegments: progress.totalScheduled,
                        completedSegments: progress.completedScheduled,
                        title: "Today's progress",
                      ),
                    );
                  },
                ),

                // Divider 3 & Notification Warning Card (ONLY shown if notifications are NOT granted)
                if (!_isNotificationGranted) ...[
                  Image.asset(
                    AppAssets.icHorizontalDivider,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: NotificationWarningCard(
                      onEnable: _handleEnableNotifications,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
