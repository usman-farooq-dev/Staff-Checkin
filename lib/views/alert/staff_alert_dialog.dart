import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../widgets/custom_button.dart';

enum StaffAlertType {
  invalidPin,
  inactiveAccount,
  error,
}

class StaffAlertDialog extends StatelessWidget {
  final StaffAlertType alertType;
  final String title;
  final String message;
  final String? subMessage;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  const StaffAlertDialog({
    super.key,
    required this.alertType,
    required this.title,
    required this.message,
    this.subMessage,
    this.buttonText = 'TRY AGAIN',
    this.onButtonPressed,
  });

  static Future<void> showInvalidPin(
    BuildContext context, {
    String? message,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StaffAlertDialog(
        alertType: StaffAlertType.invalidPin,
        title: 'Invalid PIN',
        message: message ??
            'The PIN you entered does not match any registered staff member in the system.',
        subMessage: 'Please verify your PIN code and try again.',
        buttonText: 'TRY AGAIN',
        onButtonPressed: () {
          Navigator.of(ctx).pop();
          onDismiss?.call();
        },
      ),
    );
  }

  static Future<void> showInactiveAccount(
    BuildContext context, {
    required String staffName,
    String? staffId,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StaffAlertDialog(
        alertType: StaffAlertType.inactiveAccount,
        title: 'Account Inactive',
        message:
            'The account for $staffName${staffId != null && staffId.isNotEmpty ? ' (ID: $staffId)' : ''} is currently deactivated or inactive.',
        subMessage:
            'Please contact your store manager or administrator to activate your account before checking in.',
        buttonText: 'OK',
        onButtonPressed: () {
          Navigator.of(ctx).pop();
          onDismiss?.call();
        },
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StaffAlertDialog(
        alertType: StaffAlertType.error,
        title: 'Verification Error',
        message: message,
        subMessage: 'Please check your internet connection or try again shortly.',
        buttonText: 'CLOSE',
        onButtonPressed: () {
          Navigator.of(ctx).pop();
          onDismiss?.call();
        },
      ),
    );
  }

  Color _getHeaderColor() {
    switch (alertType) {
      case StaffAlertType.invalidPin:
        return const Color(0xFFDC2626); // Crimson Red
      case StaffAlertType.inactiveAccount:
        return const Color(0xFFD97706); // Amber / Warning
      case StaffAlertType.error:
        return const Color(0xFFE11D48); // Rose Red
    }
  }

  IconData _getIcon() {
    switch (alertType) {
      case StaffAlertType.invalidPin:
        return Icons.lock_outline_rounded;
      case StaffAlertType.inactiveAccount:
        return Icons.person_off_outlined;
      case StaffAlertType.error:
        return Icons.wifi_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getHeaderColor();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Circle Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Icon(
                _getIcon(),
                size: 32,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 18),

            // Alert Title
            Text(
              title,
              style: AppStyles.heading1.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Main Message
            Text(
              message,
              style: AppStyles.bodyMedium.copyWith(
                color: const Color(0xFF374151),
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            if (subMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  subMessage!,
                  style: AppStyles.caption.copyWith(
                    color: const Color(0xFF6B7280),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Button
            CustomButton(
              text: buttonText,
              height: 48,
              borderRadius: 10,
              backgroundColor: themeColor,
              onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
