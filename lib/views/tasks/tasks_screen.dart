import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/scheduled_checkin_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../models/scheduled_checkin_model.dart';
import '../../models/staff_user_model.dart';
import '../../widgets/compliance_card.dart';
import '../../widgets/status_badge.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StaffUserModel?>(
      valueListenable: StaffAuthService.instance.currentStaffNotifier,
      builder: (context, currentStaff, _) {
        final storeId = currentStaff?.storeId ?? '';

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600 ||
                  MediaQuery.sizeOf(context).shortestSide >= 600;
              final horizontalPadding = isTablet ? 24.0 : 16.0;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Bar
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          horizontalPadding, 16, horizontalPadding, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks',
                            style: AppStyles.heading1.copyWith(
                              fontSize: isTablet ? 28 : 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your scheduled compliance checks for today.',
                            style: AppStyles.bodySmall.copyWith(
                              color: const Color(0xFF5B6471),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top Horizontal Divider
                    const Divider(
                      color: AppColors.cardBorderSubtle,
                      thickness: 1.2,
                      height: 1.2,
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Upcoming / Overdue / Missed
                          Text(
                            'Upcoming',
                            style: AppStyles.caption.copyWith(
                              color: const Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          StreamBuilder<List<ScheduledCheckInModel>>(
                            stream: ScheduledCheckInService.instance
                                .streamTodaysPendingChecks(storeId: storeId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                );
                              }

                              final pendingChecks = snapshot.data ?? [];

                              if (pendingChecks.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgWarm,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No pending checks for today.',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: pendingChecks.map((check) {
                                  final isMissed = check.isMissedForStore(storeId);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: UpcomingTaskCard(
                                      time: check.formattedTime,
                                      title: check.title,
                                      taskInfo: check.taskInfoSubtitle,
                                      isOverdue: check.isOverdue,
                                      isMissed: isMissed,
                                      onStartCheck: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.checklist,
                                          arguments: check,
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),

                      const SizedBox(height: 12),

                      // Section: Completed
                      Text(
                        'Completed',
                        style: AppStyles.caption.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      StreamBuilder<List<ScheduledCheckInModel>>(
                        stream: ScheduledCheckInService.instance
                            .streamTodaysCompletedChecks(storeId: storeId),
                        builder: (context, snapshot) {
                          final completedChecks = snapshot.data ?? [];

                          if (completedChecks.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgWarm,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.cardBorder,
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'No completed checks yet today.',
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Container(
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
                              itemCount: completedChecks.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: AppColors.cardBorder,
                                thickness: 1,
                              ),
                              itemBuilder: (context, index) {
                                final check = completedChecks[index];
                                return _buildCompletedItem(
                                  time: check.formattedTime,
                                  title: check.title,
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
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

  Widget _buildCompletedItem({
    required String time,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular green check badge on left
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF8EF),
              border: Border.all(color: const Color(0xFFC6E7D2), width: 1.2),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.icComplete,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const CompletedBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
