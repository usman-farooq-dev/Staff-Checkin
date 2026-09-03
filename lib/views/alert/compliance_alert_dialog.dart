import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/scheduled_checkin_service.dart';
import '../../models/scheduled_checkin_model.dart';
import '../../widgets/custom_button.dart';

class ComplianceAlertScreen extends StatelessWidget {
  final ScheduledCheckInModel? check;
  final String title;
  final String scheduledTime;
  final String dueInfo;
  final bool canSnooze;
  final VoidCallback? onStartCheck;
  final VoidCallback? onRemindLater;

  const ComplianceAlertScreen({
    super.key,
    this.check,
    this.title = 'Hygiene Check',
    this.scheduledTime = '6:57 PM',
    this.dueInfo = 'Due 7 minutes',
    this.canSnooze = true,
    this.onStartCheck,
    this.onRemindLater,
  });

  static Future<void> show(
    BuildContext context, {
    ScheduledCheckInModel? check,
    String? storeId,
  }) {
    final displayTitle = check?.title ?? 'Hygiene Check';
    final displayScheduled = check?.formattedTime ?? '6:57 PM';
    final displayDueInfo = check?.overdueOrDueInfo ?? 'Due 7 minutes';
    final bool canSnooze = check != null
        ? check.canSnoozeForStore(storeId ?? '')
        : true;

    return showDialog(
      context: context,
      barrierDismissible: canSnooze,
      builder: (ctx) => Dialog.fullscreen(
        child: ComplianceAlertScreen(
          check: check,
          title: displayTitle,
          scheduledTime: displayScheduled,
          dueInfo: displayDueInfo,
          canSnooze: canSnooze,
          onStartCheck: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pushNamed(
              AppRoutes.checklist,
              arguments: check,
            );
          },
          onRemindLater: canSnooze
              ? () async {
                  Navigator.of(ctx).pop();
                  if (check != null) {
                    await ScheduledCheckInService.instance
                        .snoozeCheckFor15Minutes(
                      checkId: check.id,
                      storeId: storeId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.snooze_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Reminder snoozed for 15 minutes (Final).'),
                            ],
                          ),
                          backgroundColor: AppColors.darkCard,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: canSnooze,
        child: Scaffold(
          backgroundColor: AppColors.darkAlertBg,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),

                            // Bell icon container
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF2D483D),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  AppAssets.icNotificationWhite,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Subtitle
                            Text(
                              canSnooze
                                  ? 'Compliance check required'
                                  : 'Final Reminder • Action Required',
                              style: AppStyles.caption.copyWith(
                                color: canSnooze
                                    ? AppColors.textLightMuted
                                    : const Color(0xFFFFB74D),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Large Title
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                title,
                                style: AppStyles.heading1.copyWith(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Scheduled Time and Status Card Row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Scheduled time column
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        Text(
                                          'Scheduled time',
                                          style: AppStyles.caption.copyWith(
                                            color: AppColors.textLightMuted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            scheduledTime,
                                            style: AppStyles.heading2.copyWith(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Divider vertical line
                                  Container(
                                    height: 36,
                                    width: 1,
                                    color: Colors.white12,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),

                                  // Status column
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      children: [
                                        Text(
                                          'Status',
                                          style: AppStyles.caption.copyWith(
                                            color: AppColors.textLightMuted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            dueInfo,
                                            style: AppStyles.heading2.copyWith(
                                              color: Colors.white,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Description
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                canSnooze
                                    ? 'Please complete the required compliance tasks for this check.'
                                    : 'Snooze limit reached. You must complete this check-in now.',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textLightMuted,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const Spacer(flex: 3),

                            // Start Check Button (White background with dark bold text)
                            CustomButton(
                              text: 'START CHECK',
                              variant: ButtonVariant.light,
                              height: 50,
                              borderRadius: 8,
                              onPressed: onStartCheck ??
                                  () {
                                    Navigator.of(context).pushReplacementNamed(
                                      AppRoutes.checklist,
                                      arguments: check,
                                    );
                                  },
                            ),
                            const SizedBox(height: 14),

                            // Remind Me Later Button: ONLY SHOWN ONCE (Hidden if already snoozed before)
                            if (canSnooze)
                              TextButton(
                                onPressed: onRemindLater ??
                                    () {
                                      Navigator.of(context).pop();
                                    },
                                child: Text(
                                  'REMIND ME AGAIN IN 15 MINUTES',
                                  style: AppStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 20),

                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
