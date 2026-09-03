import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/check_task_model.dart';

enum CaptureMode { photo, video }

class CameraCaptureScreen extends StatefulWidget {
  final CheckTaskModel? task;

  const CameraCaptureScreen({super.key, this.task});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.auto;

  late CaptureMode _currentMode;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _showGrid = false;
  bool _isFlashing = false;

  // Captured evidence result
  XFile? _capturedFile;
  bool _isCaptured = false;

  // Video playback for captured video verification
  VideoPlayerController? _videoPreviewController;
  bool _isVideoPreviewInitialized = false;

  // Tap-to-focus animation coordinates
  Offset? _focusPosition;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial mode
    if (widget.task?.requirementType == RequirementType.video) {
      _currentMode = CaptureMode.video;
    } else {
      _currentMode = CaptureMode.photo;
    }

    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _focusTimer?.cancel();
    _videoPreviewController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(cameraController.description);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initCameraController(_cameras[_selectedCameraIndex]);
      } else {
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _initCameraController(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera controller init error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _toggleCameraLens() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
      default:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      debugPrint('Flash mode error: $e');
    }
  }

  void _onTapViewfinder(TapDownDetails details) async {
    if (_isCaptured || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final point = Offset(
        details.localPosition.dx / size.width,
        details.localPosition.dy / size.height,
      );

      try {
        await _controller!.setFocusPoint(point);
        await _controller!.setExposurePoint(point);
      } catch (_) {}
    }

    setState(() {
      _focusPosition = details.localPosition;
    });

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _focusPosition = null;
        });
      }
    });
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isFlashing = true;
    });

    try {
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _isFlashing = false;
          _capturedFile = file;
          _isCaptured = true;
        });
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
      if (mounted) {
        setState(() {
          _isFlashing = false;
        });
      }
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    HapticFeedback.heavyImpact();

    if (!_isRecording) {
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordSeconds++;
            });
          }
        });
      } catch (e) {
        debugPrint('Start video error: $e');
      }
    } else {
      try {
        _recordTimer?.cancel();
        final XFile file = await _controller!.stopVideoRecording();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _capturedFile = file;
            _isCaptured = true;
          });
          _initCapturedVideoPreview(file);
        }
      } catch (e) {
        debugPrint('Stop video error: $e');
      }
    }
  }

  Future<void> _initCapturedVideoPreview(XFile file) async {
    try {
      _videoPreviewController?.dispose();
      _videoPreviewController = VideoPlayerController.file(File(file.path));
      await _videoPreviewController!.initialize();
      _videoPreviewController!.setLooping(true);
      _videoPreviewController!.play();
      if (mounted) {
        setState(() {
          _isVideoPreviewInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading captured video preview: $e');
    }
  }

  void _retake() {
    _videoPreviewController?.pause();
    _videoPreviewController?.dispose();
    _videoPreviewController = null;

    setState(() {
      _isCaptured = false;
      _capturedFile = null;
      _recordSeconds = 0;
      _isVideoPreviewInitialized = false;
    });
  }

  void _confirmCapture() {
    _videoPreviewController?.pause();
    // Return full absolute path of captured file
    final path = _capturedFile?.path ?? '';
    Navigator.of(context).pop(path);
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final taskTitle = widget.task?.title ?? 'Compliance Evidence';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Viewfinder or Captured Preview (Photo/Video)
            if (_isCameraInitialized && _controller != null && !_isCaptured)
              GestureDetector(
                onTapDown: _onTapViewfinder,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize?.height ?? 1,
                      height: _controller!.value.previewSize?.width ?? 1,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              )
            else if (_isCaptured && _capturedFile != null && _currentMode == CaptureMode.photo)
              // Captured photo preview
              Image.file(
                File(_capturedFile!.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else if (_isCaptured && _capturedFile != null && _currentMode == CaptureMode.video)
              // Captured video preview with playback
              _isVideoPreviewInitialized && _videoPreviewController != null
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_videoPreviewController!.value.isPlaying) {
                            _videoPreviewController!.pause();
                          } else {
                            _videoPreviewController!.play();
                          }
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoPreviewController!.value.size.width,
                                height: _videoPreviewController!.value.size.height,
                                child: VideoPlayer(_videoPreviewController!),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: _videoPreviewController!.value.isPlaying ? 0.0 : 0.85,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 52,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 120,
                            left: 20,
                            right: 20,
                            child: VideoProgressIndicator(
                              _videoPreviewController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: AppColors.primaryOrange,
                                bufferedColor: Colors.white30,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    )
            else
              // Fallback viewfinder backdrop
              Container(
                color: const Color(0xFF141917),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),

            // 2. Viewfinder Overlay (Grid, Focus box, Frame corners)
            if (!_isCaptured) ...[
              // Grid overlay
              if (_showGrid) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(height: 1, color: Colors.white24),
                    Container(height: 1, color: Colors.white24),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: 1, color: Colors.white24),
                    Container(width: 1, color: Colors.white24),
                  ],
                ),
              ],

              // Viewfinder corners
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 120,
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: _buildCorner(isTop: true, isLeft: true),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: _buildCorner(isTop: true, isLeft: false),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: _buildCorner(isTop: false, isLeft: true),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _buildCorner(isTop: false, isLeft: false),
                    ),
                  ],
                ),
              ),

              // Tap Focus Box
              if (_focusPosition != null)
                Positioned(
                  left: _focusPosition!.dx - 35,
                  top: _focusPosition!.dy - 35,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],

            // 3. Shutter Flash Effect
            if (_isFlashing)
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
              ),

            // 4. Top Header & Controls Bar
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),

                      // Task Banner
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentMode == CaptureMode.video
                                    ? Icons.videocam_outlined
                                    : Icons.camera_alt_outlined,
                                color: const Color(0xFFDE8B2D),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  taskTitle,
                                  style: AppStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Controls: Grid & Flash
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showGrid ? Icons.grid_on : Icons.grid_off,
                              color: _showGrid ? const Color(0xFFDE8B2D) : Colors.white70,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _showGrid = !_showGrid;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _flashMode == FlashMode.auto
                                    ? Icons.flash_auto
                                    : _flashMode == FlashMode.always
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                              color: _flashMode != FlashMode.off
                                  ? const Color(0xFFDE8B2D)
                                  : Colors.white70,
                              size: 22,
                            ),
                            onPressed: _toggleFlash,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Video Recording Timer Indicator
            if (_isRecording)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'REC ${_formatDuration(_recordSeconds)}',
                          style: AppStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. Bottom Controls Bar
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(top: 14, bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mode Switcher (PHOTO / VIDEO)
                      if (!_isCaptured && !_isRecording)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModeTab('PHOTO', CaptureMode.photo),
                            const SizedBox(width: 32),
                            _buildModeTab('VIDEO', CaptureMode.video),
                          ],
                        ),

                      const SizedBox(height: 22),

                      // Action Buttons
                      if (!_isCaptured)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 48, height: 48),

                              // Central Shutter Button
                              GestureDetector(
                                onTap: _currentMode == CaptureMode.photo
                                    ? _takePhoto
                                    : _toggleVideoRecording,
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: _currentMode == CaptureMode.photo
                                        ? Container(
                                            width: 60,
                                            height: 60,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Container(
                                            width: _isRecording ? 30 : 60,
                                            height: _isRecording ? 30 : 60,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDC2626),
                                              borderRadius: BorderRadius.circular(
                                                _isRecording ? 6 : 30,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              // Flip Camera Lens Button
                              IconButton(
                                icon: const Icon(
                                  Icons.flip_camera_ios_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _toggleCameraLens,
                              ),
                            ],
                          ),
                        )
                      else
                        // Confirmation Buttons (RETAKE & USE EVIDENCE)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _retake,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white38,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'RETAKE',
                                    style: AppStyles.buttonText.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _confirmCapture,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryOrange,
                                    foregroundColor: AppColors.buttonDarkText,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'USE EVIDENCE',
                                    style: AppStyles.buttonText.copyWith(
                                      color: AppColors.buttonDarkText,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, CaptureMode mode) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () {
        if (_isRecording) return;
        setState(() {
          _currentMode = mode;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppStyles.bodyMedium.copyWith(
              color: isSelected ? const Color(0xFFFFD54F) : Colors.white60,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13.5,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD54F),
              ),
            )
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.white60, width: 2.5)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white60, width: 2.5)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.white60, width: 2.5)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white60, width: 2.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
