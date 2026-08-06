import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/rtc/network_quality_monitor.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';

/// 自适应码率控制器
/// 
/// 根据网络质量动态调整视频码率和分辨率，实现弱网优化
class AdaptiveBitrateController {
  AdaptiveBitrateController({
    required this.peerConnection,
    this.minBitrate = 100000, // 100 kbps
    this.maxBitrate = 2000000, // 2 Mbps
    this.startBitrate = 500000, // 500 kbps
  });

  final RTCPeerConnection peerConnection;
  final int minBitrate;
  final int maxBitrate;
  final int startBitrate;

  late int _currentBitrate = startBitrate;
  NetworkQuality _lastQuality = NetworkQuality.unknown;
  Timer? _adjustmentTimer;
  
  /// 当前码率
  int get currentBitrate => _currentBitrate;

  /// 网络质量变化时调整码率
  void onNetworkQualityChanged(NetworkQualityStats stats) {
    final newQuality = stats.quality;
    
    // 如果质量等级没有变化，不进行调整
    if (newQuality == _lastQuality) {
      return;
    }
    
    _lastQuality = newQuality;
    
    // 根据网络质量调整码率
    switch (newQuality) {
      case NetworkQuality.excellent:
        _adjustBitrate(maxBitrate);
        break;
      case NetworkQuality.good:
        _adjustBitrate((maxBitrate * 0.75).toInt());
        break;
      case NetworkQuality.fair:
        _adjustBitrate((maxBitrate * 0.5).toInt());
        break;
      case NetworkQuality.poor:
        _adjustBitrate((maxBitrate * 0.25).toInt());
        break;
      case NetworkQuality.unknown:
        // 保持当前码率
        break;
    }
  }

  /// 调整码率
  void _adjustBitrate(int targetBitrate) {
    // 限制在最小和最大码率之间
    final clampedBitrate = targetBitrate.clamp(minBitrate, maxBitrate);
    
    if (clampedBitrate == _currentBitrate) {
      return;
    }
    
    _currentBitrate = clampedBitrate;
    
    // 延迟调整，避免频繁调整
    _adjustmentTimer?.cancel();
    _adjustmentTimer = Timer(const Duration(milliseconds: 500), () {
      _applyBitrate(clampedBitrate);
    });
  }

  /// 应用码率调整
  Future<void> _applyBitrate(int bitrate) async {
    try {
      final senders = await peerConnection.senders;
      
      for (final sender in senders) {
        final track = sender.track;
        if (track != null && track.kind == 'video') {
          final parameters = sender.parameters;
          
          // 设置码率限制
          if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
            parameters.encodings![0].maxBitrate = bitrate;
            await sender.setParameters(parameters);
          }
        }
      }
    } catch (e) {
      // 忽略调整错误
    }
  }

  /// 释放资源
  void dispose() {
    _adjustmentTimer?.cancel();
    _adjustmentTimer = null;
  }
}

/// 自动降级策略
/// 
/// 当网络质量持续较差时，自动降级视频质量或关闭视频
class AutoDegradationStrategy {
  AutoDegradationStrategy({
    required this.peerConnection,
    this.poorQualityThreshold = 3, // 连续 3 次 poor 质量触发降级
    this.degradationInterval = const Duration(seconds: 5),
  });

  final RTCPeerConnection peerConnection;
  final int poorQualityThreshold;
  final Duration degradationInterval;

  int _poorQualityCount = 0;
  Timer? _degradationTimer;
  bool _isDegraded = false;

  /// 网络质量变化时检查是否需要降级
  void onNetworkQualityChanged(NetworkQualityStats stats) {
    if (stats.quality == NetworkQuality.poor) {
      _poorQualityCount++;
      
      if (_poorQualityCount >= poorQualityThreshold && !_isDegraded) {
        _degrade();
      }
    } else {
      // 质量恢复，重置计数
      _poorQualityCount = 0;
      
      if (_isDegraded && stats.quality == NetworkQuality.good) {
        _restore();
      }
    }
  }

  /// 降级视频质量
  Future<void> _degrade() async {
    _isDegraded = true;
    
    try {
      final senders = await peerConnection.senders;
      
      for (final sender in senders) {
        final track = sender.track;
        if (track != null && track.kind == 'video') {
          // 降低帧率
          final parameters = sender.parameters;
          if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
            parameters.encodings![0].maxFramerate = 15; // 降低到 15fps
            await sender.setParameters(parameters);
          }
        }
      }
    } catch (e) {
      // 忽略降级错误
    }
  }

  /// 恢复视频质量
  Future<void> _restore() async {
    _isDegraded = false;
    
    try {
      final senders = await peerConnection.senders;
      
      for (final sender in senders) {
        final track = sender.track;
        if (track != null && track.kind == 'video') {
          // 恢复帧率
          final parameters = sender.parameters;
          if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
            parameters.encodings![0].maxFramerate = 30; // 恢复到 30fps
            await sender.setParameters(parameters);
          }
        }
      }
    } catch (e) {
      // 忽略恢复错误
    }
  }

  /// 释放资源
  void dispose() {
    _degradationTimer?.cancel();
    _degradationTimer = null;
  }
}
