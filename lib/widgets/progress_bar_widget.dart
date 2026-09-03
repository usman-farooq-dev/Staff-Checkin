import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

class SegmentedProgressBar extends StatelessWidget {
  final int totalSegments;
  final int completedSegments;
  final String title;

  const SegmentedProgressBar({
    super.key,
    this.totalSegments = 8,
    this.completedSegments = 5,
    this.title = "Today's progress",
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSegments < 0 ? 0 : totalSegments;
    final safeCompleted = completedSegments < 0
        ? 0
        : (completedSegments > safeTotal ? safeTotal : completedSegments);

    final int percentage =
        safeTotal > 0 ? ((safeCompleted / safeTotal) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$safeCompleted',
                    style: AppStyles.heading1.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '/$safeTotal finished',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (safeTotal > 0)
            Row(
              children: List.generate(safeTotal, (index) {
                final bool isCompleted = index < safeCompleted;
                return Expanded(
                  child: Container(
                    height: 14,
                    margin: EdgeInsets.only(
                      right: index == safeTotal - 1 ? 0 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.progressActive
                          : AppColors.progressInactive,
                      borderRadius: BorderRadius.circular(3),
                      border: isCompleted
                          ? null
                          : Border.all(
                              color: AppColors.progressInactiveBorder,
                              width: 1,
                            ),
                    ),
                  ),
                );
              }),
            )
          else
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.progressInactive,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: AppColors.progressInactiveBorder,
                  width: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
