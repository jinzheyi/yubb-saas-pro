import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/camera_capture_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:video_player/video_player.dart';

/// 微信风格自定义相机页面。
///
/// 交互对标微信：
/// - 拍摄阶段：全屏预览，点击快门拍照，长按快门录像（最长 60 秒）
/// - 预览阶段：拍摄完成后进入预览界面，显示"重拍"和"发送"按钮
/// - 照片预览：全屏显示照片，底部两个按钮
/// - 视频预览：全屏显示视频播放器（自动播放），底部两个按钮
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

  // 预览模式状态
  bool _isPreviewing = false;
  String? _capturedFilePath;
  bool _isCapturedVideo = false;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;

  // 扫码模式状态
  MobileScannerController? _mobileScannerController;
  bool _isHandlingScanResult = false;
  bool _isTorchEnabled = false;
  bool _hasTorch = true; // 假设设备有手电筒，后续动态检测

  bool get _isQrScanMode => widget.args.initialMode == CameraCaptureMode.qrScan;

  bool get _supportsNativeScanner =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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

    if (_isQrScanMode) {
      _initializeScanner();
    } else {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller?.dispose();
    _shrinkAnimation.dispose();
    _progressAnimation.dispose();
    _videoPlayerController?.dispose();
    _mobileScannerController?.dispose();
    super.dispose();
  }

  void _initializeScanner() {
    if (!_supportsNativeScanner) return;
    _mobileScannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeStartScanner();
    });
  }

  Future<void> _safeStartScanner() async {
    final scanner = _mobileScannerController;
    if (scanner == null || !_supportsNativeScanner || scanner.value.isRunning) return;
    try {
      await scanner.start();
      // 检测设备是否支持手电筒
      if (mounted) {
        setState(() {
          // torchState 为 unavailable 表示设备不支持手电筒
          _hasTorch = scanner.value.torchState != TorchState.unavailable;
        });
      }
    } catch (_) {
      // 扫码启动失败，静默忽略
    }
  }

  /// 切换扫码模式手电筒
  Future<void> _toggleScannerTorch() async {
    final scanner = _mobileScannerController;
    if (scanner == null || !_hasTorch) return;
    
    try {
      await scanner.toggleTorch();
      if (mounted) {
        setState(() {
          _isTorchEnabled = !_isTorchEnabled;
        });
      }
    } catch (e) {
      // 手电筒切换失败，显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法开启手电筒：${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _safeStopScanner() async {
    final scanner = _mobileScannerController;
    if (scanner == null || !scanner.value.isRunning) return;
    try {
      await scanner.stop();
    } catch (_) {
      // 扫码停止失败，静默忽略
    }
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isHandlingScanResult) return;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (rawValue.isEmpty) return;
    _isHandlingScanResult = true;
    await _safeStopScanner();
    if (!mounted) return;

    // 判断是否是URL（http:// 或 https://）
    final isUrl = rawValue.startsWith('http://') || rawValue.startsWith('https://');

    if (isUrl) {
      // 外部URL，跳转到浏览器页面
      await context.pushNamed(
        RouteNames.browser,
        extra: BrowserPageArgs(
          url: rawValue,
          source: 'scan',
          rawContent: rawValue,
        ),
      );
    } else {
      // 非URL，当作群二维码处理
      await context.pushNamed(RouteNames.joinGroup, extra: rawValue);
    }

    if (!mounted) return;
    _isHandlingScanResult = false;
    await _safeStartScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 预览模式下不处理生命周期
    if (_isPreviewing) return;

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

      if (fileSize > AppConfig.maxImageUploadSize) {
        if (!mounted) return;
        _showErrorSnackBar(
          AppLocalizations.of(context).chatCameraPhotoLimit(
            _formatFileSize(AppConfig.maxImageUploadSize),
          ),
        );
        return;
      }

      // 进入预览模式
      if (!mounted) return;
      setState(() {
        _isPreviewing = true;
        _capturedFilePath = image.path;
        _isCapturedVideo = false;
      });
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

      // 计时器用于更新秒数显示，并在达到最大时长时自动停止
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _recordingSeconds = timer.tick;
        });
        // 达到最大录制时长时自动停止录制
        if (timer.tick >= _maxDuration) {
          _stopRecording();
        }
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

      if (fileSize > AppConfig.maxVideoUploadSize) {
        if (!mounted) return;
        _showErrorSnackBar(
          AppLocalizations.of(context).chatCameraVideoLimit(
            _formatFileSize(AppConfig.maxVideoUploadSize),
          ),
        );
        return;
      }

      // 进入预览模式
      if (!mounted) return;
      setState(() {
        _isPreviewing = true;
        _capturedFilePath = video.path;
        _isCapturedVideo = true;
      });

      // 初始化视频播放器
      await _initializeVideoPlayer(video.path);
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

  Future<void> _initializeVideoPlayer(String path) async {
    try {
      final videoController = VideoPlayerController.file(File(path));
      await videoController.initialize();
      await videoController.setLooping(true);
      await videoController.play();

      if (!mounted) {
        await videoController.dispose();
        return;
      }

      setState(() {
        _videoPlayerController = videoController;
        _isVideoPlaying = true;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        '视频预览初始化失败：${e.toString()}',
      );
    }
  }

  void _retake() {
    // 释放视频播放器
    _videoPlayerController?.dispose();
    _videoPlayerController = null;

    setState(() {
      _isPreviewing = false;
      _capturedFilePath = null;
      _isCapturedVideo = false;
      _isVideoPlaying = false;
    });
  }

  void _confirmSend() {
    if (_capturedFilePath == null) return;
    Navigator.of(context).pop(_capturedFilePath);
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
    if (_isQrScanMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _buildScannerUI()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isPreviewing ? _buildPreviewUI() : _buildCaptureUI(),
      ),
    );
  }

  /// 扫码模式 UI
  Widget _buildScannerUI() {
    if (!_supportsNativeScanner) {
      return Center(
        child: Text(
          AppLocalizations.of(context).chatCameraNotFound,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    final scanner = _mobileScannerController;
    if (scanner == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: scanner,
            onDetect: _handleDetect,
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerOverlayPainter(),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // 手电筒按钮（仅当设备支持时显示）
                if (_hasTorch)
                  IconButton(
                    icon: Icon(
                      _isTorchEnabled ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleScannerTorch,
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              AppLocalizations.of(context).chatScanHint,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// 拍摄阶段 UI
  Widget _buildCaptureUI() {
    return Stack(
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
    );
  }

  /// 预览阶段 UI
  Widget _buildPreviewUI() {
    return Stack(
      children: [
        // 预览内容
        Positioned.fill(
          child: _isCapturedVideo ? _buildVideoPreview() : _buildPhotoPreview(),
        ),

        // 底部按钮
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildPreviewBottomControls(),
        ),
      ],
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

  Widget _buildPhotoPreview() {
    if (_capturedFilePath == null) {
      return const SizedBox.shrink();
    }

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Image.file(
        File(_capturedFilePath!),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoPreview() {
    final videoController = _videoPlayerController;
    if (videoController == null || !videoController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_isVideoPlaying) {
            _videoPlayerController?.pause();
          } else {
            _videoPlayerController?.play();
          }
          _isVideoPlaying = !_isVideoPlaying;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: videoController.value.aspectRatio,
            child: VideoPlayer(videoController),
          ),
          if (!_isVideoPlaying)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
        ],
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

  Widget _buildPreviewBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 重拍按钮
          _buildPreviewButton(
            icon: Icons.refresh,
            label: '重拍',
            onTap: _retake,
          ),

          // 发送按钮
          _buildPreviewButton(
            icon: Icons.check,
            label: '发送',
            onTap: _confirmSend,
            isPrimary: true,
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

  Widget _buildPreviewButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isPrimary
                  ? const Color(0xFF07C160)
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

/// 扫码框绘制器（用于扫码模式的半透明遮罩和扫描框）。
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    // 绘制半透明遮罩
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // 绘制扫描框边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(scanRect, borderPaint);

    // 绘制四个角的装饰线
    final cornerPaint = Paint()
      ..color = const Color(0xFF07C160)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    const cornerLength = 20.0;

    // 左上角
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft + const Offset(0, -cornerLength),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight + const Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
