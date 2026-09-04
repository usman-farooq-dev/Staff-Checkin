import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/reminder_sound_service.dart';
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
    final bool isOverdue = check?.isOverdue ?? true;
    final bool canSnooze = check != null
        ? check.canSnoozeForStore(storeId ?? '')
        : true;

    final mediaSize = MediaQuery.sizeOf(context);
    final isTablet = mediaSize.shortestSide >= 600 || mediaSize.width >= 600;

    // Start playing reminder tune
    ReminderSoundService.instance.playAlertTune();

    Future<void> handleStartCheck(BuildContext ctx) async {
      ReminderSoundService.instance.stop();
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      if (!context.mounted) return;
      final completed = await Navigator.of(context).pushNamed(
        AppRoutes.checklist,
        arguments: check,
      );

      // If user came back without completing / uploading, re-open alert dialog
      if (completed != true && context.mounted) {
        ComplianceAlertScreen.show(
          context,
          check: check,
          storeId: storeId,
        );
      }
    }

    Future<void> handleRemindLater(BuildContext ctx) async {
      ReminderSoundService.instance.stop();
      Navigator.of(ctx).pop();
      if (check != null) {
        await ScheduledCheckInService.instance.snoozeCheckFor15Minutes(
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

    Future<void> dialogFuture;

    if (isTablet) {
      dialogFuture = showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: TabletComplianceAlertDialog(
              check: check,
              title: displayTitle,
              scheduledTime: displayScheduled,
              isOverdue: isOverdue,
              canSnooze: canSnooze,
              onStartCheck: () => handleStartCheck(ctx),
              onRemindLater: canSnooze ? () => handleRemindLater(ctx) : null,
            ),
          ),
        ),
      );
    } else {
      // Mobile: Fullscreen alert dialog (non-cancelable until check-in started)
      dialogFuture = showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Dialog.fullscreen(
            child: ComplianceAlertScreen(
              check: check,
              title: displayTitle,
              scheduledTime: displayScheduled,
              dueInfo: displayDueInfo,
              canSnooze: canSnooze,
              onStartCheck: () => handleStartCheck(ctx),
              onRemindLater: canSnooze ? () => handleRemindLater(ctx) : null,
            ),
          ),
        ),
      );
    }

    return dialogFuture.whenComplete(() {
      ReminderSoundService.instance.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isTablet = mediaSize.shortestSide >= 600 || mediaSize.width >= 600;

    if (isTablet) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.65),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: TabletComplianceAlertDialog(
                  check: check,
                  title: title,
                  scheduledTime: scheduledTime,
                  isOverdue: check?.isOverdue ?? true,
                  canSnooze: canSnooze,
                  onStartCheck: onStartCheck,
                  onRemindLater: onRemindLater,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
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

/// Tablet-specific Compliance Alert Modal Dialog matching Mockup 03
class TabletComplianceAlertDialog extends StatelessWidget {
  final ScheduledCheckInModel? check;
  final String title;
  final String scheduledTime;
  final bool isOverdue;
  final bool canSnooze;
  final VoidCallback? onStartCheck;
  final VoidCallback? onRemindLater;

  const TabletComplianceAlertDialog({
    super.key,
    this.check,
    this.title = 'Hygiene Check',
    this.scheduledTime = '4:37 PM',
    this.isOverdue = true,
    this.canSnooze = true,
    this.onStartCheck,
    this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF162520),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon Box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF24362E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    AppAssets.icWarning,
                    width: 32,
                    height: 32,
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Subtitle
              Text(
                isOverdue
                    ? 'Compliance Check Overdue'
                    : 'Compliance Check Due',
                style: AppStyles.caption.copyWith(
                  color: const Color(0xFF98ACA2),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Large Title
              Text(
                title,
                style: AppStyles.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Scheduled Time & Status row
              Row(
                children: [
                  // Scheduled time column
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Scheduled time',
                          style: AppStyles.caption.copyWith(
                            color: const Color(0xFF98ACA2),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scheduledTime,
                          style: AppStyles.heading2.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status column
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Status',
                          style: AppStyles.caption.copyWith(
                            color: const Color(0xFF98ACA2),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isOverdue ? 'OVERDUE' : 'PENDING',
                          style: AppStyles.heading2.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                isOverdue
                    ? 'This check is now overdue and has been reported to your manager. Please complete it now.'
                    : 'Please complete the required compliance tasks for this check.',
                style: AppStyles.bodyMedium.copyWith(
                  color: const Color(0xFFB0C4B8),
                  fontSize: 14,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Orange START CHECK Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onStartCheck ??
                      () {
                        Navigator.of(context).pushReplacementNamed(
                          AppRoutes.checklist,
                          arguments: check,
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: AppColors.buttonDarkText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'START CHECK',
                    style: AppStyles.buttonText.copyWith(
                      color: AppColors.buttonDarkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Remind Me Later Button
              if (canSnooze)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: onRemindLater ??
                        () {
                          Navigator.of(context).pop();
                        },
                    child: Text(
                      'REMIND ME AGAIN IN 15 MINUTES',
                      style: AppStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
