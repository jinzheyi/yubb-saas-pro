import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/camera_capture_route_args.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

/// 微信风格自定义相机页面。
///
/// 交互对标微信：
/// - 点击快门按钮：拍照
/// - 长按快门按钮：录像（最长 60 秒）
/// - 长按时有圆形进度动画环绕快门按钮（红色圆环从顶部顺时针填充）
/// - 支持前后摄像头切换、闪光灯控制
class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key, required this.args});

  final CameraCaptureRouteArgs args;

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _isInitializing = true;
  String? _error;

  // 录像状态
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // 闪光灯状态
  FlashMode _flashMode = FlashMode.off;

  // 快门按钮按下缩放动画
  late final AnimationController _shrinkAnimation;

  // 录像进度动画（0→1 对应 0→60 秒，平滑驱动圆形进度环）
  late final AnimationController _progressAnimation;

  static const int _maxDuration = AppConfig.cameraMaxVideoDurationSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _shrinkAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _progressAnimation = AnimationController(
      vsync: this,
      duration: Duration(seconds: _maxDuration),
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller?.dispose();
    _shrinkAnimation.dispose();
    _progressAnimation.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context).chatCameraNotFound;
          _isInitializing = false;
        });
        return;
      }

      _cameras = cameras;
      _currentCameraIndex = 0;
      await _setupCamera(cameras.first);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${AppLocalizations.of(context).chatCameraInitFailed}：${e.toString()}';
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await controller.initialize();
    // 部分设备（如前置摄像头）不支持闪光灯模式，忽略异常
    try {
      await controller.setFlashMode(_flashMode);
    } on CameraException {
      _flashMode = FlashMode.off;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _isInitializing = false;
      _error = null;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    final camera = _cameras![_currentCameraIndex];

    setState(() {
      _isInitializing = true;
    });

    await _controller?.dispose();
    await _setupCamera(camera);
  }

  void _toggleFlash() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    });
    controller.setFlashMode(_flashMode);
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final image = await controller.takePicture();
      final file = File(image.path);
      final fileSize = await file.length();

      if (fileSize > AppConfig.cameraMaxPhotoSize) {
        if (!mounted) return;
        _showErrorSnackBar(
          AppLocalizations.of(context).chatCameraPhotoLimit(
            _formatFileSize(AppConfig.cameraMaxPhotoSize),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(image.path);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        '${AppLocalizations.of(context).chatCameraTakePhotoFailed}：${e.toString()}',
      );
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // 启动进度动画（平滑驱动圆形进度环）
      _progressAnimation.forward(from: 0);

      // 计时器仅用于更新秒数显示
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _recordingSeconds = timer.tick;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar(
        '${AppLocalizations.of(context).chatCameraStartRecordFailed}：${e.toString()}',
      );
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _recordingTimer?.cancel();
    _progressAnimation.stop();

    try {
      final video = await controller.stopVideoRecording();
      final file = File(video.path);
      final fileSize = await file.length();

      setState(() {
        _isRecording = false;
      });

      if (fileSize > AppConfig.cameraMaxVideoSize) {
        if (!mounted) return;
        _showErrorSnackBar(
          AppLocalizations.of(context).chatCameraVideoLimit(
            _formatFileSize(AppConfig.cameraMaxVideoSize),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(video.path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar(
        '${AppLocalizations.of(context).chatCameraStopRecordFailed}：${e.toString()}',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.withOpacity(0.9),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 相机预览
            Positioned.fill(
              child: _buildCameraPreview(),
            ),

            // 顶部工具栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            // 底部控制区域
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 关闭按钮
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // 录像时长显示
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_recordingSeconds}s / $_maxDuration s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 闪光灯按钮
          _buildIconButton(
            icon: _flashMode == FlashMode.off
                ? Icons.flash_off
                : Icons.flash_on,
            onTap: _toggleFlash,
          ),

          // 快门按钮（点击拍照，长按录像）
          _buildShutterButton(),

          // 切换摄像头按钮
          _buildIconButton(
            icon: Icons.cameraswitch,
            onTap: _switchCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTapDown: (_) => _shrinkAnimation.forward(),
      onTapUp: (_) {
        _shrinkAnimation.reverse();
        if (!_isRecording) {
          _takePhoto();
        }
      },
      onTapCancel: () {
        _shrinkAnimation.reverse();
        if (_isRecording) {
          _stopRecording();
        }
      },
      onLongPressStart: (_) {
        if (!_isRecording) {
          _startRecording();
        }
      },
      onLongPressEnd: (_) {
        if (_isRecording) {
          _stopRecording();
        }
      },
      child: AnimatedBuilder(
        animation: _shrinkAnimation,
        builder: (context, child) {
          final scale = 1.0 - (_shrinkAnimation.value * 0.1);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 圆形进度环（录像时显示）
                  if (_isRecording)
                    CustomPaint(
                      size: const Size(80, 80),
                      painter: _CircularProgressPainter(
                        progress: _progressAnimation.value,
                        strokeWidth: 4,
                        color: Colors.red,
                      ),
                    ),

                  // 快门按钮
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isRecording ? Colors.red : Colors.white,
                    ),
                    child: _isRecording
                        ? const Icon(Icons.stop, color: Colors.white, size: 28)
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 圆形进度绘制器（用于录像时的进度动画）。
///
/// 从顶部（-90°）开始顺时针绘制红色圆环，模拟微信录像进度效果。
class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  final double progress;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
