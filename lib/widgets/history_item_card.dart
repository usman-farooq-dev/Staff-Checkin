import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../models/compliance_check_model.dart';
import '../models/history_record_model.dart';
import 'status_badge.dart';

class HistoryItemCard extends StatelessWidget {
  final HistoryRecordModel record;
  final VoidCallback onTap;

  const HistoryItemCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppStyles.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            record.scheduledTime,
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              record.title,
                              style: AppStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.evidenceSummary,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (record.status == CheckStatus.completed)
                        const CompletedBadge()
                      else if (record.status == CheckStatus.missed)
                        const MissedBadge(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  AppAssets.icForward,
                  width: 14,
                  height: 14,
                  color: AppColors.textSecondary,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
