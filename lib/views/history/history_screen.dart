import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/history_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../models/compliance_check_model.dart';
import '../../models/history_record_model.dart';
import '../../models/staff_user_model.dart';
import '../../widgets/status_badge.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _navigateToDetail(BuildContext context, HistoryRecordModel record) {
    Navigator.of(context).pushNamed(
      AppRoutes.historyDetail,
      arguments: record,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StaffUserModel?>(
      valueListenable: StaffAuthService.instance.currentStaffNotifier,
      builder: (context, currentStaff, _) {
        final storeId = currentStaff?.storeId ?? '';

        return SafeArea(
          child: StreamBuilder<List<HistoryGroupModel>>(
            stream: HistoryService.instance.streamHistoryGroups(storeId: storeId),
            builder: (context, snapshot) {
              final groups = snapshot.data ?? [];
              final bool isLoading =
                  snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'History',
                            style: AppStyles.heading1.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your completed compliance records.',
                            style: AppStyles.bodySmall.copyWith(
                              color: const Color(0xFF5B6471),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top Horizontal Divider Line
                    const Divider(
                      color: AppColors.cardBorderSubtle,
                      thickness: 1.2,
                      height: 1.2,
                    ),
                    const SizedBox(height: 12),

                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      )
                    else if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgWarm,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.cardBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No History Records',
                                  style: AppStyles.heading2.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Completed checks for today and past records will show up here.',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: groups.map((group) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header (Today, Yesterday, Aug 30, 2026, etc.)
                                Text(
                                  group.dateHeader,
                                  style: AppStyles.caption.copyWith(
                                    color: const Color(0xFF475569),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Grouped Card Container
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgWarm,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: group.records.length,
                                    separatorBuilder: (context, index) => const Divider(
                                      height: 1,
                                      color: AppColors.cardBorder,
                                      thickness: 1,
                                    ),
                                    itemBuilder: (context, index) {
                                      final record = group.records[index];
                                      return _buildHistoryRow(
                                        record: record,
                                        onTap: () => _navigateToDetail(context, record),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryRow({
    required HistoryRecordModel record,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Time on left
              SizedBox(
                width: 76,
                child: Text(
                  record.scheduledTime,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Title, Evidence count, and Pill Badge in middle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.evidenceSummary,
                      style: AppStyles.caption.copyWith(
                        color: const Color(0xFF5B6471),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (record.status == CheckStatus.completed)
                      const CompletedBadge()
                    else if (record.status == CheckStatus.missed)
                      const MissedBadge(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron arrow
              Image.asset(
                AppAssets.icForward,
                width: 14,
                height: 14,
                color: const Color(0xFF64748B),
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
