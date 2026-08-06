import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 音频级别监控服务
///
/// 通过 WebRTC getStats() 定期采集音频级别，判断当前说话者。
/// - 本地音频：从 media-source 统计中获取 audioLevel
/// - 远端音频：从 inbound-rtp 统计中计算 RMS（totalAudioEnergy / totalSamplesDuration）
class AudioLevelMonitor {
  AudioLevelMonitor({
    required this.peerConnection,
    this.interval = const Duration(milliseconds: 500),
    this.speakingThreshold = 0.05,
  });

  final RTCPeerConnection peerConnection;
  final Duration interval;
  final double speakingThreshold;

  Timer? _timer;
  StreamController<String?>? _speakingController;
  
  /// 当前说话者的 feed ID 流
  ///
  /// 当检测到说话者变化时发出新的 feed ID；
  /// 当无人说话时发出 null。
  Stream<String?> get speakingStream => _speakingController?.stream ?? const Stream.empty();

  /// 上次检测到的说话 feed ID
  String? _lastSpeakingFeedId;

  /// 是否正在监控
  bool _isRunning = false;

  /// 启动监控
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    
    // 关键修复：延迟创建 StreamController，避免在 dispose 后仍被访问
    _speakingController ??= StreamController<String?>.broadcast();
    
    _timer = Timer.periodic(interval, (_) => _collectStats());
  }

  /// 停止监控
  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    
    // 关键修复：检查 StreamController 是否已关闭，避免重复关闭
    if (_speakingController != null && !_speakingController!.isClosed) {
      _speakingController!.close();
      _speakingController = null;
    }
  }

  /// 采集 WebRTC 统计信息并分析音频级别
  Future<void> _collectStats() async {
    if (!_isRunning) return;
    try {
      final stats = await peerConnection.getStats(null);
      final audioLevels = _parseAudioLevels(stats);

      // 找到音频级别最高的 feed
      String? loudestFeedId;
      double maxLevel = 0.0;
      for (final entry in audioLevels.entries) {
        if (entry.value > maxLevel) {
          maxLevel = entry.value;
          loudestFeedId = entry.key;
        }
      }

      // 判断说话者
      String? newSpeakingFeedId;
      if (loudestFeedId != null && maxLevel >= speakingThreshold) {
        newSpeakingFeedId = loudestFeedId;
      }

      // 仅在状态变化时通知
      if (newSpeakingFeedId != _lastSpeakingFeedId) {
        _lastSpeakingFeedId = newSpeakingFeedId;
        if (_speakingController != null && !_speakingController!.isClosed) {
          _speakingController!.add(newSpeakingFeedId);
        }
      }
    } catch (_) {
      // 忽略统计采集错误
    }
  }

  /// 从 WebRTC 统计报告中解析音频级别
  ///
  /// 返回 Map：feedId -> audioLevel (0.0~1.0)
  Map<String, double> _parseAudioLevels(List<StatsReport> stats) {
    final levels = <String, double>{};

    for (final report in stats) {
      final values = report.values;

      // 本地音频：从 media-source 获取 audioLevel
      if (report.type == 'media-source' && values['kind'] == 'audio') {
        final audioLevel = _extractAudioLevel(values);
        if (audioLevel > 0) {
          // 使用 'local' 作为本地源的标识
          levels['local'] = audioLevel;
        }
      }

      // 远端音频：从 inbound-rtp 获取音频级别
      if (report.type == 'inbound-rtp' && values['kind'] == 'audio') {
        final audioLevel = _extractAudioLevel(values);
        if (audioLevel > 0) {
          // 使用 trackIdentifier 或 ssrc 作为远端源的标识
          final trackId = values['trackIdentifier']?.toString() ??
              values['ssrc']?.toString() ??
              report.id;
          levels[trackId] = audioLevel;
        }
      }
    }

    return levels;
  }

  /// 从统计值中提取音频级别
  ///
  /// 优先使用 audioLevel（0.0~1.0 线性值）；
  /// 不可用时通过 totalAudioEnergy 和 totalSamplesDuration 计算 RMS。
  double _extractAudioLevel(Map<dynamic, dynamic> values) {
    // 方式 1：直接使用 audioLevel
    final directLevel = values['audioLevel'];
    if (directLevel != null && directLevel is num && directLevel > 0) {
      return directLevel.toDouble().clamp(0.0, 1.0);
    }

    // 方式 2：通过 totalAudioEnergy 计算 RMS
    final totalEnergy = values['totalAudioEnergy'];
    final totalDuration = values['totalSamplesDuration'];
    if (totalEnergy != null &&
        totalDuration != null &&
        totalEnergy is num &&
        totalDuration is num &&
        totalDuration > 0) {
      final rms = totalEnergy.toDouble() / totalDuration.toDouble();
      return rms.clamp(0.0, 1.0);
    }

    return 0.0;
  }

  /// 释放资源
  void dispose() {
    stop();
  }
}
