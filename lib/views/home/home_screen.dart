import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  // Track automatic popup alert state
  bool _isAlertShowing = false;
  bool _isCheckInProgress = false;
  String _lastTriggeredAlertKey = '';
  List<ScheduledCheckInModel> _lastPendingChecks = [];
  String _lastStoreId = '';

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
        if (_lastPendingChecks.isNotEmpty && _lastStoreId.isNotEmpty) {
          _checkAndTriggerScheduledAlert(_lastPendingChecks, _lastStoreId);
        }
      }
    });

    // 2. Request Location Permission automatically on home load
    _requestLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      await PermissionService.requestLocationPermission();
    } catch (_) {}
  }

  Future<void> _handleOpenTrainingLink() async {
    final uri = Uri.parse('https://www.google.com');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open training link: $e'),
            backgroundColor: AppColors.warningRedButton,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Automatically prompt fullscreen compliance alert when scheduled time arrives (ONLY on Home screen and when not actively checking in)
  void _checkAndTriggerScheduledAlert(
    List<ScheduledCheckInModel> pendingChecks,
    String storeId,
  ) {
    // 1. Staff MUST be actively authenticated
    final staff = StaffAuthService.instance.currentStaff;
    if (staff == null || !staff.isActive || storeId.isEmpty) {
      return;
    }

    // 2. Alert should ONLY trigger if on Home screen and NOT currently in a check flow
    if (!mounted || _isCheckInProgress || _isAlertShowing || pendingChecks.isEmpty) {
      return;
    }

    final isHomeVisible = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isHomeVisible) return;

    for (final check in pendingChecks) {
      if (check.shouldTriggerAlertForStore(storeId)) {
        final alertKey = '${check.id}_${check.remindAt[storeId] ?? 0}';
        if (_lastTriggeredAlertKey == alertKey) return;

        _lastTriggeredAlertKey = alertKey;
        _isAlertShowing = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          // Re-verify login and visibility before popping up alert
          if (!StaffAuthService.instance.isLoggedIn) {
            _isAlertShowing = false;
            return;
          }
          final currentRoute = ModalRoute.of(context)?.isCurrent ?? false;
          if (!currentRoute || _isCheckInProgress) {
            _isAlertShowing = false;
            return;
          }

          final action = await ComplianceAlertScreen.show(
            context,
            check: check,
            storeId: storeId,
          );

          if (!mounted) return;
          _isAlertShowing = false;

          if (action == 'start') {
            _isCheckInProgress = true;
            final completed = await Navigator.of(context).pushNamed(
              AppRoutes.checklist,
              arguments: check,
            );
            if (mounted) {
              _isCheckInProgress = false;
              // If user came back without completing / submitting, re-trigger alert dialog on Home
              if (completed != true) {
                _lastTriggeredAlertKey = '';
                _checkAndTriggerScheduledAlert(_lastPendingChecks, storeId);
              }
            }
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
        final displayName = currentStaff?.fullName.split(' ').first ?? 'Ahmed';
        final storeId = currentStaff?.storeId ?? '';
        final defaultCity = currentStaff?.storeName.isNotEmpty == true
            ? currentStaff!.storeName
            : 'Islamabad Store';

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600 ||
                  MediaQuery.sizeOf(context).shortestSide >= 600;
              final horizontalPadding = isTablet ? 24.0 : 16.0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header (Date, Greeting, Store on left; Time Badge on right matching iPad mockup)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isTablet ? 20 : 16,
                        horizontalPadding,
                        isTablet ? 16 : 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
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
                                    fontSize: isTablet ? 28 : 25,
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Realtime Time Badge Box (top right)
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
                                fontSize: isTablet ? 20 : 18,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Next Check & Overdue Banner Stream
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
                        _lastPendingChecks = pendingChecks;
                        _lastStoreId = storeId;

                        // Automatically trigger compliance alert dialog if scheduled time arrived or snooze passed
                        _checkAndTriggerScheduledAlert(pendingChecks, storeId);

                        // Identify overdue or missed checks
                        final overdueOrMissed = pendingChecks.where((c) =>
                            c.isOverdue || c.isMissedForStore(storeId)).toList();

                        Widget? bannerWidget;
                        if (overdueOrMissed.isNotEmpty) {
                          final topOverdue = overdueOrMissed.first;
                          bannerWidget = Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 8,
                            ),
                            child: OverdueAlertBanner(
                              overdueCount: overdueOrMissed.length,
                              title: topOverdue.title,
                              onStartNow: () async {
                                _isCheckInProgress = true;
                                await Navigator.of(context).pushNamed(
                                  AppRoutes.checklist,
                                  arguments: topOverdue,
                                );
                                if (mounted) {
                                  _isCheckInProgress = false;
                                }
                              },
                            ),
                          );
                        }

                        Widget cardWidget;
                        if (pendingChecks.isEmpty) {
                          cardWidget = Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 12,
                            ),
                            child: const NoPendingCheckCard(),
                          );
                        } else {
                          final nextCheck = pendingChecks.first;
                          cardWidget = Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 12,
                            ),
                            child: DarkNextCheckCard(
                              time: nextCheck.formattedTime,
                              title: nextCheck.title,
                              subtitle: nextCheck.heroSubtitle,
                              onStartCheck: () async {
                                _isCheckInProgress = true;
                                await Navigator.of(context).pushNamed(
                                  AppRoutes.checklist,
                                  arguments: nextCheck,
                                );
                                if (mounted) {
                                  _isCheckInProgress = false;
                                }
                              },
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bannerWidget != null) ...[
                              bannerWidget,
                              const SizedBox(height: 6),
                            ],

                            // Divider 1 (Dashed ticket line)
                            Image.asset(
                              AppAssets.icHorizontalDivider,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            ),

                            cardWidget,
                          ],
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
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 12,
                          ),
                          child: SegmentedProgressBar(
                            totalSegments: progress.totalScheduled,
                            completedSegments: progress.completedScheduled,
                            title: "Today's progress",
                          ),
                        );
                      },
                    ),

                    // Divider 3 & Training Resources Card (Always visible)
                    Image.asset(
                      AppAssets.icHorizontalDivider,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 12,
                      ),
                      child: TrainingResourcesCard(
                        onOpenTraining: _handleOpenTrainingLink,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
