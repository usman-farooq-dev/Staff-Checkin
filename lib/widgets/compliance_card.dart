import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import 'custom_button.dart';

class DarkNextCheckCard extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final VoidCallback onStartCheck;

  const DarkNextCheckCard({
    super.key,
    this.time = '6:57 PM',
    this.title = 'Hygiene Check',
    this.subtitle = 'Overdue by 8 minutes • 5 tasks',
    required this.onStartCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next check',
            style: AppStyles.caption.copyWith(
              color: AppColors.textLightMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: AppStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppStyles.heading2.copyWith(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textLightMuted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onStartCheck,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(
                    'START CHECK',
                    style: AppStyles.buttonText.copyWith(
                      color: AppColors.buttonDarkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoPendingCheckCard extends StatelessWidget {
  const NoPendingCheckCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF15803D).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFF15803D), width: 1.5),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF22C55E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'All caught up for today',
                style: AppStyles.heading2.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No pending compliance checks for your store at this time.',
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textLightMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class UpcomingTaskCard extends StatelessWidget {
  final String time;
  final String title;
  final String taskInfo;
  final bool isOverdue;
  final VoidCallback onStartCheck;

  const UpcomingTaskCard({
    super.key,
    this.time = '5:59 PM',
    this.title = 'Hygiene Check',
    this.taskInfo = '5 tasks • Overdue by 1 hr 26 min',
    this.isOverdue = true,
    required this.onStartCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: AppStyles.heading2.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            taskInfo,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          // Overdue / Upcoming Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOverdue ? const Color(0xFFFDE8E4) : const Color(0xFFEBF5FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOverdue ? const Color(0xFFF7C6BC) : const Color(0xFFB9E6FE),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOverdue)
                  Image.asset(
                    AppAssets.icWarning,
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                  )
                else
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Color(0xFF026AA2),
                  ),
                const SizedBox(width: 6),
                Text(
                  isOverdue ? 'Overdue' : 'Upcoming',
                  style: AppStyles.caption.copyWith(
                    color: isOverdue ? const Color(0xFFB9381E) : const Color(0xFF026AA2),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // START CHECK Button
          CustomButton(
            text: 'START CHECK',
            variant: ButtonVariant.primary,
            height: 46,
            borderRadius: 8,
            onPressed: onStartCheck,
          ),
        ],
      ),
    );
  }
}

class NotificationWarningCard extends StatelessWidget {
  final VoidCallback onEnable;

  const NotificationWarningCard({
    super.key,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications disabled',
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You may miss scheduled compliance reminders.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            height: 42,
            child: Material(
              color: AppColors.warningRedButton,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onEnable,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(
                    'ENABLE NOTIFICATIONS',
                    style: AppStyles.buttonText.copyWith(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
