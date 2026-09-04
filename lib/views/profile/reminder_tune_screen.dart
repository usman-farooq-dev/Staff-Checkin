import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/services/reminder_sound_service.dart';
import '../../core/services/staff_auth_service.dart';

class ReminderTuneScreen extends StatefulWidget {
  const ReminderTuneScreen({super.key});

  @override
  State<ReminderTuneScreen> createState() => _ReminderTuneScreenState();
}

class _ReminderTuneScreenState extends State<ReminderTuneScreen> {
  @override
  void initState() {
    super.initState();
    ReminderSoundService.instance.init();
  }

  @override
  void dispose() {
    // Stop any ongoing preview sound when leaving the screen
    ReminderSoundService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tunes = ReminderSoundService.availableTunes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reminder Tunes',
          style: AppStyles.heading2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.2),
          child: Divider(
            height: 1.2,
            thickness: 1.2,
            color: AppColors.cardBorderSubtle,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600 ||
                MediaQuery.sizeOf(context).shortestSide >= 600;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 640 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgWarm,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrangeLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: AppColors.primaryOrange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Compliance Alert Tune',
                                    style: AppStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select the tone that sounds when a scheduled compliance check is due. Tap any tune to listen and set as default.',
                                    style: AppStyles.bodySmall.copyWith(
                                      color: const Color(0xFF5B6471),
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Title
                      Text(
                        'AVAILABLE TUNES',
                        style: AppStyles.caption.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tunes List Container
                      ValueListenableBuilder<String>(
                        valueListenable:
                            ReminderSoundService.instance.selectedTuneIdNotifier,
                        builder: (context, selectedId, _) {
                          return ValueListenableBuilder<String?>(
                            valueListenable: ReminderSoundService
                                .instance.currentlyPlayingTuneIdNotifier,
                            builder: (context, playingId, _) {
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
                                  itemCount: tunes.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.cardBorder,
                                  ),
                                  itemBuilder: (context, index) {
                                    final tune = tunes[index];
                                    final isSelected = tune.id == selectedId;
                                    final isPlaying = tune.id == playingId;

                                    return _buildTuneTile(
                                      tune: tune,
                                      isSelected: isSelected,
                                      isPlaying: isPlaying,
                                      onSelect: () {
                                        final isKiosk = StaffAuthService
                                                .instance
                                                .currentStaff
                                                ?.isKioskMode ??
                                            true;
                                        if (isKiosk) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Cannot change tune: Kiosk Mode is active and managed by administrator.',
                                              ),
                                              backgroundColor:
                                                  AppColors.darkCard,
                                              duration: Duration(seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        ReminderSoundService.instance
                                            .selectTune(tune.id);
                                        ReminderSoundService.instance
                                            .previewTune(tune.id);
                                      },
                                      onTogglePlay: () {
                                        ReminderSoundService.instance
                                            .previewTune(tune.id);
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Stop preview button if audio is playing
                      ValueListenableBuilder<String?>(
                        valueListenable: ReminderSoundService
                            .instance.currentlyPlayingTuneIdNotifier,
                        builder: (context, playingId, _) {
                          if (playingId == null) {
                            return const SizedBox.shrink();
                          }
                          return Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ReminderSoundService.instance.stop();
                              },
                              icon: const Icon(
                                Icons.stop_rounded,
                                size: 18,
                                color: AppColors.warningRedButton,
                              ),
                              label: const Text(
                                'STOP PREVIEW',
                                style: TextStyle(
                                  color: AppColors.warningRedButton,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.warningRedButton,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTuneTile({
    required ReminderTuneModel tune,
    required bool isSelected,
    required bool isPlaying,
    required VoidCallback onSelect,
    required VoidCallback onTogglePlay,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Play / Stop Icon Button
              GestureDetector(
                onTap: onTogglePlay,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? AppColors.primaryOrange
                        : const Color(0xFFFAF7F2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPlaying
                          ? AppColors.primaryOrange
                          : AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: isPlaying ? Colors.white : AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tune.title,
                            style: AppStyles.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrangeLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PLAYING',
                              style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tune.subtitle,
                      style: AppStyles.caption.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Selected Radio / Checkmark Indicator
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF15803D)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF15803D)
                        : const Color(0xFF94A3B8),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
