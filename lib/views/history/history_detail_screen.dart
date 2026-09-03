import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/services/history_service.dart';
import '../../models/compliance_check_model.dart';
import '../../models/history_record_model.dart';
import '../../widgets/media_preview_widget.dart';
import '../../widgets/status_badge.dart';

class HistoryDetailScreen extends StatefulWidget {
  final HistoryRecordModel? record;

  const HistoryDetailScreen({super.key, this.record});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late HistoryRecordModel _record;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _record = widget.record ??
        const HistoryRecordModel(
          id: '1',
          title: 'Store Check',
          date: 'Aug 30, 2026',
          scheduledTime: '8:58 PM',
          autoRecordedTime: '9:00 PM',
          completedTime: '9:04 PM',
          totalEvidence: 3,
          completedEvidence: 3,
          status: CheckStatus.completed,
          staffName: 'Ahmed Khan',
          storeName: 'Islamabad Store',
          location: 'F-7 Markaz, Islamabad',
        );

    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    if (widget.record != null) {
      final updated =
          await HistoryService.instance.getFullHistoryDetails(widget.record!);
      if (mounted) {
        setState(() {
          _record = updated;
          _isLoadingDetails = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AppAssets.icBack,
                            width: 14,
                            height: 14,
                            color: const Color(0xFF475569),
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'History',
                            style: AppStyles.bodySmall.copyWith(
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _record.title,
                          style: AppStyles.heading1.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_record.status == CheckStatus.completed)
                        const CompletedBadge()
                      else
                        const MissedBadge(),
                    ],
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

            // Details and Evidence Scrollable List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Details Table Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgWarm,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Date', _record.date),
                          _buildDivider(),
                          _buildDetailRow('Scheduled', _record.scheduledTime),
                          _buildDivider(),
                          _buildDetailRow('Acknowledged', _record.autoRecordedTime),
                          _buildDivider(),
                          _buildDetailRow('Completed', _record.completedTime),
                          _buildDivider(),
                          _buildDetailRow('Staff', _record.staffName),
                          _buildDivider(),
                          _buildDetailRow('Store', _record.storeName),
                          _buildDivider(),
                          _buildDetailRow('Location', _record.location),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Evidence
                    Text(
                      'Evidence (${_record.completedEvidence} items)',
                      style: AppStyles.caption.copyWith(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_isLoadingDetails)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      )
                    else if (_record.status == CheckStatus.missed)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFCA5A5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No evidence recorded. This check was missed on scheduled date.',
                                style: AppStyles.bodySmall.copyWith(
                                  color: const Color(0xFF991B1B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_record.evidenceList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgWarm,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'No individual evidence logs uploaded for this check.',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ..._record.evidenceList.map(
                        (evidence) => _buildEvidenceCard(evidence),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(
              color: const Color(0xFF5B6471),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: AppColors.cardBorder,
      thickness: 1,
    );
  }

  Widget _buildEvidenceCard(EvidenceItemModel evidence) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (evidence.mediaUrl.isNotEmpty) {
            MediaPreviewDialog.show(
              context,
              mediaSource: evidence.mediaUrl,
              title: evidence.title,
              isVideo: evidence.isVideo,
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBgWarm,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: Row(
            children: [
              // Square thumbnail / icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: evidence.isVideo
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                ),
                child: Center(
                  child: Icon(
                    evidence.isVideo
                        ? Icons.videocam_rounded
                        : Icons.image_rounded,
                    size: 24,
                    color: evidence.isVideo
                        ? const Color(0xFFD97706)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidence.title,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: evidence.isVideo
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFBAE6FD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            evidence.fileType,
                            style: TextStyle(
                              color: evidence.isVideo
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF0369A1),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            evidence.fileName,
                            style: AppStyles.caption.copyWith(
                              color: const Color(0xFF5B6471),
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
