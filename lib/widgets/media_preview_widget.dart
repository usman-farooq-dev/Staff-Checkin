import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

class MediaPreviewDialog extends StatefulWidget {
  final String mediaSource; // Can be a local file path OR a network URL (https://...)
  final String title;
  final bool isVideo;

  const MediaPreviewDialog({
    super.key,
    required this.mediaSource,
    required this.title,
    this.isVideo = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String mediaSource,
    required String title,
    bool isVideo = false,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => MediaPreviewDialog(
        mediaSource: mediaSource,
        title: title,
        isVideo: isVideo,
      ),
    );
  }

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  bool get _isNetwork =>
      widget.mediaSource.startsWith('http://') ||
      widget.mediaSource.startsWith('https://');

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      if (_isNetwork) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.mediaSource),
        );
      } else {
        final file = File(widget.mediaSource);
        if (await file.exists()) {
          _videoController = VideoPlayerController.file(file);
        } else {
          setState(() {
            _hasError = true;
          });
          return;
        }
      }

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video preview: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppStyles.heading2.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Media Content Container
            Flexible(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(18)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                  ),
                  child: widget.isVideo
                      ? AspectRatio(
                          aspectRatio: 9 / 12,
                          child: _buildVideoPlayer(),
                        )
                      : _buildImageViewer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
            const SizedBox(height: 8),
            Text(
              'Unable to load video evidence',
              style: AppStyles.caption.copyWith(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: AnimatedOpacity(
                opacity: _videoController!.value.isPlaying ? 0.0 : 0.85,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 12,
          right: 12,
          child: VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.primaryOrange,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageViewer() {
    if (_isNetwork) {
      return Image.network(
        widget.mediaSource,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryOrange,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white54,
              size: 48,
            ),
          );
        },
      );
    } else if (widget.mediaSource.startsWith('assets/')) {
      return Image.asset(
        widget.mediaSource,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white54,
              size: 48,
            ),
          );
        },
      );
    } else {
      final file = File(widget.mediaSource);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
        );
      }
      return const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white54,
          size: 48,
        ),
      );
    }
  }
}
