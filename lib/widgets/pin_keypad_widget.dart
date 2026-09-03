import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

class PinKeypadWidget extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onDeletePressed;

  const PinKeypadWidget({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((digit) => _buildKey(digit)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 88, height: 60), // Empty spacer on bottom left
        _buildKey('0'),
        _buildActionKey(
          onTap: onDeletePressed,
          child: Image.asset(
            AppAssets.icCross,
            width: 24,
            height: 24,
            color: AppColors.textPrimary,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return SizedBox(
      width: 88,
      height: 60,
      child: Material(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => onDigitPressed(digit),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                digit,
                style: AppStyles.heading2.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return SizedBox(
      width: 88,
      height: 60,
      child: Material(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.2,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class PinIndicatorDots extends StatelessWidget {
  final int length;
  final int filledCount;

  const PinIndicatorDots({
    super.key,
    this.length = 4,
    required this.filledCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (index) {
            final isFilled = index < filledCount;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? AppColors.textPrimary
                    : const Color(0xFFD4C8B8),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '$filledCount of $length digits entered',
          style: AppStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
