import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

class CompletedBadge extends StatelessWidget {
  final String text;

  const CompletedBadge({super.key, this.text = 'Completed'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successGreenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.icComplete,
            width: 13,
            height: 13,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppStyles.caption.copyWith(
              color: AppColors.successGreenText,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class MissedBadge extends StatelessWidget {
  final String text;

  const MissedBadge({super.key, this.text = 'Missed'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.icMissed,
            width: 12,
            height: 12,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppStyles.caption.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class OverdueBadge extends StatelessWidget {
  final String text;

  const OverdueBadge({super.key, this.text = 'Overdue'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.overduePillBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppStyles.caption.copyWith(
          color: AppColors.overduePillText,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class BlockedBadge extends StatelessWidget {
  final String text;

  const BlockedBadge({super.key, this.text = 'Blocked'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blockedPillBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppStyles.caption.copyWith(
          color: AppColors.blockedPillText,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  final String text;

  const CountBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBorderSubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: AppStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
