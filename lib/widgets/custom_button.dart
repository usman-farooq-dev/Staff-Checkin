import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

enum ButtonVariant { primary, dark, red, outline, light }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final Widget? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width = double.infinity,
    this.height = 48,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;

    if (backgroundColor != null) {
      bgColor = backgroundColor!;
      textColor = Colors.white;
      border = null;
    } else {
      switch (variant) {
        case ButtonVariant.primary:
          bgColor = AppColors.primaryOrange;
          textColor = AppColors.buttonDarkText;
          border = null;
          break;
        case ButtonVariant.dark:
          bgColor = AppColors.darkCard;
          textColor = Colors.white;
          border = null;
          break;
        case ButtonVariant.red:
          bgColor = AppColors.warningRedButton;
          textColor = Colors.white;
          border = null;
          break;
        case ButtonVariant.outline:
          bgColor = Colors.transparent;
          textColor = AppColors.textPrimary;
          border = Border.all(color: AppColors.cardBorder, width: 1.5);
          break;
        case ButtonVariant.light:
          bgColor = Colors.white;
          textColor = AppColors.textPrimary;
          border = null;
          break;
      }
    }

    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: isEnabled ? bgColor : bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: border,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: AppStyles.buttonText.copyWith(
                    color: textColor,
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
    );
  }
}
