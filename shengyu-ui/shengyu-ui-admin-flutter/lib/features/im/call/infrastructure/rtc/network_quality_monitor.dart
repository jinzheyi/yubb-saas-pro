import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';

/// 网络质量监控服务
/// 
/// 定期获取 RTCPeerConnection 的统计信息，计算网络质量指标
class NetworkQualityMonitor {
  NetworkQualityMonitor({
    required this.peerConnection,
    this.interval = const Duration(seconds: 2),
  });

  final RTCPeerConnection peerConnection;
  final Duration interval;
  
  Timer? _timer;
  StreamController<NetworkQualityStats>? _statsController;
  
  /// 网络质量统计流
  Stream<NetworkQualityStats> get statsStream => _statsController?.stream ?? const Stream.empty();
  
  /// 启动监控
  void start() {
    // 关键修复：检查是否已启动，避免重复创建 StreamController
    if (_statsController != null && !_statsController!.isClosed) {
      return;
    }
    
    _statsController = StreamController<NetworkQualityStats>.broadcast();
    _timer = Timer.periodic(interval, (_) => _collectStats());
  }
  
  /// 停止监控
  void stop() {
    _timer?.cancel();
    _timer = null;
    _statsController?.close();
    _statsController = null;
  }
  
  /// 收集统计信息
  Future<void> _collectStats() async {
    try {
      final stats = await peerConnection.getStats(null);
      final qualityStats = _parseStats(stats);
      _statsController?.add(qualityStats);
    } catch (e) {
      // 忽略统计收集错误
    }
  }
  
  /// 解析统计信息
  NetworkQualityStats _parseStats(List<StatsReport> stats) {
    int? rtt;
    double? packetLoss;
    int? availableOutgoingBitrate;
    int? availableIncomingBitrate;
    
    // 遍历所有统计报告
    for (final report in stats) {
      final values = report.values;
      
      // 获取 RTT（从 candidate-pair）
      if (report.type == 'candidate-pair' && values['state'] == 'succeeded') {
        final currentRtt = values['currentRoundTripTime'];
        if (currentRtt != null) {
          rtt = (currentRtt as num).toInt();
        }
      }
      
      // 获取丢包率（从 inbound-rtp 或 outbound-rtp）
      if (report.type == 'inbound-rtp' || report.type == 'outbound-rtp') {
        final packetsLost = values['packetsLost'] as int? ?? 0;
        final packetsReceived = values['packetsReceived'] as int? ?? 0;
        final packetsSent = values['packetsSent'] as int? ?? 0;
        
        final totalPackets = packetsReceived + packetsSent;
        if (totalPackets > 0) {
          packetLoss = packetsLost / totalPackets;
        }
      }
      
      // 获取可用码率（从 candidate-pair）
      if (report.type == 'candidate-pair' && values['state'] == 'succeeded') {
        final availableOutgoing = values['availableOutgoingBitrate'];
        final availableIncoming = values['availableIncomingBitrate'];
        
        if (availableOutgoing != null) {
          availableOutgoingBitrate = (availableOutgoing as num).toInt();
        }
        if (availableIncoming != null) {
          availableIncomingBitrate = (availableIncoming as num).toInt();
        }
      }
    }
    
    // 计算网络质量等级
    final quality = _calculateQuality(
      rtt: rtt,
      packetLoss: packetLoss,
    );
    
    return NetworkQualityStats(
      roundTripTime: rtt,
      packetLossRate: packetLoss,
      availableOutgoingBitrate: availableOutgoingBitrate,
      availableIncomingBitrate: availableIncomingBitrate,
      quality: quality,
    );
  }
  
  /// 计算网络质量等级
  NetworkQuality _calculateQuality({
    int? rtt,
    double? packetLoss,
  }) {
    // 如果缺少关键指标，返回未知
    if (rtt == null && packetLoss == null) {
      return NetworkQuality.unknown;
    }
    
    // 优秀：RTT < 100ms 且 丢包率 < 1%
    if ((rtt == null || rtt < 100) && (packetLoss == null || packetLoss < 0.01)) {
      return NetworkQuality.excellent;
    }
    
    // 良好：RTT < 300ms 且 丢包率 < 5%
    if ((rtt == null || rtt < 300) && (packetLoss == null || packetLoss < 0.05)) {
      return NetworkQuality.good;
    }
    
    // 一般：RTT < 500ms 且 丢包率 < 10%
    if ((rtt == null || rtt < 500) && (packetLoss == null || packetLoss < 0.10)) {
      return NetworkQuality.fair;
    }
    
    // 较差：其他情况
    return NetworkQuality.poor;
  }
  
  /// 释放资源
  void dispose() {
    stop();
  }
}

/// 网络质量统计信息
class NetworkQualityStats {
  const NetworkQualityStats({
    this.roundTripTime,
    this.packetLossRate,
    this.availableOutgoingBitrate,
    this.availableIncomingBitrate,
    this.quality = NetworkQuality.unknown,
  });
  
  /// RTT（毫秒）
  final int? roundTripTime;
  
  /// 丢包率（0-1）
  final double? packetLossRate;
  
  /// 可用上行码率（bps）
  final int? availableOutgoingBitrate;
  
  /// 可用下行码率（bps）
  final int? availableIncomingBitrate;
  
  /// 网络质量等级
  final NetworkQuality quality;
}
