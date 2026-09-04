import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../models/check_task_model.dart';
import 'custom_button.dart';
import 'media_preview_widget.dart';

class TaskItemCard extends StatelessWidget {
  final CheckTaskModel task;
  final VoidCallback onCapture;

  const TaskItemCard({
    super.key,
    required this.task,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasEvidence = task.isCompleted &&
        task.capturedFilePath != null &&
        task.capturedFilePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFFC6E7D2)
              : AppColors.cardBorder,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle Number / Check Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? const Color(0xFFEAF8EF)
                      : const Color(0xFFF4EFE3),
                  border: Border.all(
                    color: task.isCompleted
                        ? const Color(0xFFC6E7D2)
                        : AppColors.cardBorder,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: task.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF15803D),
                        )
                      : Text(
                          '${task.stepNumber}',
                          style: AppStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (task.isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REQUIRED',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Reference Image uploaded by admin (side image)
              if (task.imageUrl.isNotEmpty) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    MediaPreviewDialog.show(
                      context,
                      mediaSource: task.imageUrl,
                      title: task.title,
                      isVideo: false,
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EBE1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildThumbnailImage(task.imageUrl),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xA6000000),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Requirement label
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
              children: [
                if (task.requirementType == RequirementType.video)
                  const Icon(
                    Icons.videocam_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  )
                else
                  Image.asset(
                    AppAssets.icCameraGray,
                    width: 15,
                    height: 15,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 6),
                Text(
                  task.requirementLabel,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: If evidence captured, show Preview + Retake
          if (hasEvidence)
            Row(
              children: [
                // Preview Evidence Button (Dark Green)
                Expanded(
                  flex: 3,
                  child: CustomButton(
                    text: task.isVideoFile ? 'PLAY VIDEO' : 'VIEW PHOTO',
                    variant: ButtonVariant.dark,
                    icon: Icon(
                      task.isVideoFile
                          ? Icons.play_circle_fill_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    height: 44,
                    onPressed: () {
                      MediaPreviewDialog.show(
                        context,
                        mediaSource: task.capturedFilePath!,
                        title: task.title,
                        isVideo: task.isVideoFile,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Retake Button (Outlined)
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'RETAKE',
                    variant: ButtonVariant.outline,
                    height: 44,
                    onPressed: onCapture,
                  ),
                ),
              ],
            )
          else
            // Capture Button
            CustomButton(
              text: 'CAPTURE',
              variant: ButtonVariant.primary,
              icon: Image.asset(
                AppAssets.icCameraBrown,
                width: 17,
                height: 17,
                color: AppColors.buttonDarkText,
                fit: BoxFit.contain,
              ),
              height: 44,
              onPressed: onCapture,
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryOrange,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.image_outlined,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ),
      );
    } else if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.image_outlined,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
      return const Center(
        child: Icon(
          Icons.image_outlined,
          size: 22,
          color: AppColors.textSecondary,
        ),
      );
    }
  }
}
