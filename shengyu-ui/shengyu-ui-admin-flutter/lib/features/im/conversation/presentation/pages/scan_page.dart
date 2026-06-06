import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  static const _frameSize = 275.0;

  late final MobileScannerController _controller;
  bool _isHandlingResult = false;
  bool _isStarting = false;
  bool _isStopping = false;
  bool _cameraReady = false;

  bool get _supportsNativeScanner =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
    if (_supportsNativeScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_safeStartScanner());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_supportsNativeScanner || !_controller.value.hasCameraPermission) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_safeStartScanner());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_safeStopScanner());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '扫一扫',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 18, 28, 0),
              child: Text(
                '将二维码或邀请码对准扫描框。新 Flutter 版本会过滤重复回调，避免老页那种重复跳转和误触。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xD1FFFFFF),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: _frameSize,
                  height: _frameSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _supportsNativeScanner
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                controller: _controller,
                                fit: BoxFit.cover,
                                scanWindow: Rect.fromCenter(
                                  center: const Offset(
                                    _frameSize / 2,
                                    _frameSize / 2,
                                  ),
                                  width: _frameSize * 0.88,
                                  height: _frameSize * 0.88,
                                ),
                                onDetect: _handleDetect,
                                errorBuilder: (context, error) {
                                  return _ScannerFallback(
                                    title: _resolveScannerErrorTitle(error),
                                    description:
                                        _resolveScannerErrorDescription(error),
                                  );
                                },
                              ),
                              IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const _ScannerCorners(),
                                ),
                              ),
                            ],
                          )
                        : _ScannerFallback(
                            title: strings.scanPlatformNotSupported,
                            description: strings.scanManualJoinHint,
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
              child: Column(
                children: [
                  if (_supportsNativeScanner)
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        final enabled = state.torchState == TorchState.on;
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _cameraReady ? _toggleTorch : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: const Color(0x24FFFFFF),
                              disabledBackgroundColor: const Color(0x14FFFFFF),
                            ),
                            icon: Icon(
                              enabled
                                  ? Icons.flashlight_off_rounded
                                  : Icons.flashlight_on_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              enabled ? '关闭手电筒' : '打开手电筒',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  if (_supportsNativeScanner) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.pushNamed(RouteNames.joinGroup),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: const Color(0xFF1677FF),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('手动入群'),
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

  Future<void> _safeStartScanner() async {
    if (!_supportsNativeScanner ||
        !mounted ||
        _isHandlingResult ||
        _isStarting ||
        _controller.value.isRunning) {
      return;
    }
    _isStarting = true;
    try {
      await _controller.start();
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraReady = _controller.value.hasCameraPermission;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraReady = false;
      });
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _safeStopScanner() async {
    if (!_supportsNativeScanner ||
        _isStopping ||
        !_controller.value.isRunning) {
      return;
    }
    _isStopping = true;
    try {
      await _controller.stop();
      if (mounted) {
        setState(() {
          _cameraReady = false;
        });
      }
    } finally {
      _isStopping = false;
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.torchToggleFailed(error.toString()))));
    }
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isHandlingResult) {
      return;
    }
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (rawValue.isEmpty) {
      return;
    }
    _isHandlingResult = true;
    await _safeStopScanner();
    if (!mounted) {
      return;
    }
    await context.pushNamed(RouteNames.joinGroup, extra: rawValue);
    if (!mounted) {
      return;
    }
    _isHandlingResult = false;
    await _safeStartScanner();
  }

  Future<void> _handleBack() async {
    await _safeStopScanner();
    if (!mounted) {
      return;
    }
    context.pop();
  }

  String _resolveScannerErrorTitle(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('Permission')) {
      return '相机权限未开启';
    }
    return '扫码暂不可用';
  }

  String _resolveScannerErrorDescription(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('Permission')) {
      return '请在系统设置里允许相机权限，或改用下方手动入群入口。';
    }
    return '当前设备暂时无法启动扫码，仍可继续手动入群。';
  }
}

class _ScannerFallback extends StatelessWidget {
  const _ScannerFallback({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x330B1220),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: 42,
            color: Color(0xD1FFFFFF),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    const color = Colors.white;
    return Stack(
      children: const [
        _ScannerCorner(alignment: Alignment.topLeft, color: color),
        _ScannerCorner(alignment: Alignment.topRight, color: color),
        _ScannerCorner(alignment: Alignment.bottomLeft, color: color),
        _ScannerCorner(alignment: Alignment.bottomRight, color: color),
      ],
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  const _ScannerCorner({required this.alignment, required this.color});

  final Alignment alignment;
  final Color color;

  bool get _isTop =>
      alignment == Alignment.topLeft || alignment == Alignment.topRight;
  bool get _isLeft =>
      alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border(
            top: _isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: !_isTop
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            left: _isLeft
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            right: !_isLeft
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft
                ? const Radius.circular(18)
                : Radius.zero,
            topRight: alignment == Alignment.topRight
                ? const Radius.circular(18)
                : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft
                ? const Radius.circular(18)
                : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight
                ? const Radius.circular(18)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}
