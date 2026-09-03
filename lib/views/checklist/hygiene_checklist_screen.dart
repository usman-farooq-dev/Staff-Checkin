import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/services/checkin_log_service.dart';
import '../../core/services/permission_service.dart';
import '../../models/check_task_model.dart';
import '../../models/scheduled_checkin_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/task_item_card.dart';
import '../alert/staff_alert_dialog.dart';
import '../camera/camera_capture_screen.dart';

class HygieneChecklistScreen extends StatefulWidget {
  final ScheduledCheckInModel? check;

  const HygieneChecklistScreen({
    super.key,
    this.check,
  });

  @override
  State<HygieneChecklistScreen> createState() => _HygieneChecklistScreenState();
}

class _HygieneChecklistScreenState extends State<HygieneChecklistScreen> {
  late List<CheckTaskModel> _tasks;
  late String _title;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _title = widget.check?.title ?? 'Hygiene Check';

    if (widget.check != null && widget.check!.tasks.isNotEmpty) {
      _tasks = List.from(widget.check!.tasks);
    } else {
      _tasks = [
        const CheckTaskModel(
          stepNumber: 1,
          title: 'Toppings Bar',
          description: 'Take a photo or video of the toppings bar.',
          requirementType: RequirementType.photo,
        ),
        const CheckTaskModel(
          stepNumber: 2,
          title: 'Frozen Yoghurt Machine',
          description: 'Capture the frozen yoghurt machine nozzles.',
          requirementType: RequirementType.photoOrVideo,
        ),
        const CheckTaskModel(
          stepNumber: 3,
          title: 'Dining Area',
          description: 'Take a photo of the dining area and tables.',
          requirementType: RequirementType.photo,
        ),
        const CheckTaskModel(
          stepNumber: 4,
          title: 'Kitchen',
          description: 'Record a short video walking through the kitchen.',
          requirementType: RequirementType.video,
        ),
        const CheckTaskModel(
          stepNumber: 5,
          title: 'Floors & Benchtops',
          description: 'Take a photo of the floors and benchtops.',
          requirementType: RequirementType.photo,
        ),
      ];
    }
  }

  int get _completedCount => _tasks
      .where((t) =>
          t.isCompleted &&
          t.capturedFilePath != null &&
          t.capturedFilePath!.isNotEmpty)
      .length;

  Future<void> _openCameraCapture(int index) async {
    // 1. Request camera & mic permission
    try {
      await PermissionService.checkAndRequestCameraPermission(context);
    } catch (_) {}

    if (!mounted) return;

    // 2. Direct navigation to Camera Capture Screen
    final task = _tasks[index];
    final String? result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(task: task),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _tasks[index] = task.copyWith(
          isCompleted: true,
          capturedFilePath: result,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${task.title} evidence captured!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Validate that all tasks have the required media evidence before submitting
  bool _validateAllTasks() {
    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      final bool hasEvidence = task.isCompleted &&
          task.capturedFilePath != null &&
          task.capturedFilePath!.isNotEmpty;

      if (!hasEvidence) {
        StaffAlertDialog.showError(
          context,
          message:
              'Missing Evidence: Task #${task.stepNumber} "${task.title}" requires ${task.requirementLabel.toLowerCase()}.\n\nPlease capture photo/video before submitting.',
        );
        return false;
      }

      // If requirement is photo, ensure it's not a video if strict
      if (task.requirementType == RequirementType.photo && task.isVideoFile) {
        StaffAlertDialog.showError(
          context,
          message:
              'Task "${task.title}" specifically requires a PHOTO, but a video was recorded. Please retake as photo.',
        );
        return false;
      }

      // If requirement is video, ensure it's a video
      if (task.requirementType == RequirementType.video && !task.isVideoFile) {
        StaffAlertDialog.showError(
          context,
          message:
              'Task "${task.title}" specifically requires a VIDEO, but a photo was taken. Please retake as video.',
        );
        return false;
      }

      // If requirementType is photoOrVideo (both), either is accepted
    }
    return true;
  }

  Future<void> _submitCheck() async {
    if (_isSubmitting) return;

    // 1. Check if all tasks have valid evidence
    if (!_validateAllTasks()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final scheduleId = widget.check?.id ??
        'SCH-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-01';

    // 2. Upload media and submit structured log to 'CheckIn_Logs' collection
    final success = await CheckInLogService.instance.submitCheckInLog(
      scheduleId: scheduleId,
      tasks: _tasks,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Check-in log submitted & marked completed!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } else {
      StaffAlertDialog.showError(
        context,
        message: 'Failed to upload check-in logs. Please check your internet connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int completed = _completedCount;
    final int total = _tasks.length;
    final int remaining = total - completed;

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
                  // Back Button: < Today
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
                            'Today',
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: AppStyles.heading1.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$total tasks • evidence required',
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Top Right Completed Indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$completed',
                                  style: AppStyles.heading2.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextSpan(
                                  text: '/$total',
                                  style: AppStyles.heading2.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Completed',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Active Progress Bar below Completed counter
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? completed / total : 0.0,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE5DAC4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.progressActive,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable Checklist Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return TaskItemCard(
                    task: task,
                    onCapture: () => _openCameraCapture(index),
                  );
                },
              ),
            ),

            // Bottom Sticky Submit Area
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 4
                    : 14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    text: _isSubmitting ? 'UPLOADING & SUBMITTING...' : 'SUBMIT CHECK',
                    isLoading: _isSubmitting,
                    height: 50,
                    borderRadius: 8,
                    onPressed: _isSubmitting ? null : _submitCheck,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    remaining > 0
                        ? '$remaining tasks still need evidence'
                        : 'All evidence captured, ready to submit!',
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
