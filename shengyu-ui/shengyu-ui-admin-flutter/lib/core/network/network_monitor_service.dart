import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/core/network/network_probe_stub.dart'
    if (dart.library.html) 'package:shengyu_ui_admin_im/core/network/network_probe_web.dart'
    if (dart.library.io) 'package:shengyu_ui_admin_im/core/network/network_probe_io.dart';

/// 网络状态枚举
enum NetworkStatus {
  unknown,   // 未知
  wifi,      // WiFi
  mobile,    // 移动数据
  none,      // 无网络
}

/// 网络状态监控服务
class NetworkMonitorService {
  static final NetworkMonitorService _instance = NetworkMonitorService._internal();
  factory NetworkMonitorService() => _instance;
  NetworkMonitorService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController = 
      StreamController<NetworkStatus>.broadcast();
  
  NetworkStatus _currentStatus = NetworkStatus.wifi; // 默认 wifi（Web 平台页面能加载说明有网）
  int _pingDelayMs = 0;
  
  /// 当前网络状态
  NetworkStatus get currentStatus => _currentStatus;
  
  /// 网络状态流
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  
  /// 是否处于可用网络
  bool get isNetworkAvailable => 
      _currentStatus == NetworkStatus.wifi || 
      _currentStatus == NetworkStatus.mobile ||
      _currentStatus == NetworkStatus.unknown; // unknown 视为可用（Web 平台兜底）
  
  /// 是否处于弱网（通过 ping 延迟判定）
  bool get isWeakNetwork => _pingDelayMs > 500;
  
  /// Ping 延迟（毫秒）
  int get pingDelayMs => _pingDelayMs;

  Timer? _probeTimer;
  int _statusChangeCount = 0;
  DateTime? _lastStatusChangeTime;

  /// 初始化监控
  void init() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _checkCurrentStatus();
    
    // 定时网络质量探测（每 30s）
    _probeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _probeNetworkQuality());
  }

  /// 销毁
  void dispose() {
    _probeTimer?.cancel();
    _statusController.close();
  }

  /// 连通性变化
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    if (results.isEmpty) return;
    final result = results.first;
    NetworkStatus newStatus;
    switch (result) {
      case ConnectivityResult.wifi:
        newStatus = NetworkStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        newStatus = NetworkStatus.mobile;
        break;
      case ConnectivityResult.none:
        newStatus = NetworkStatus.none;
        break;
      default:
        newStatus = NetworkStatus.unknown; // Web 平台或无法探测时
    }
    _updateStatus(newStatus);
  }

  /// 检查当前状态
  Future<void> _checkCurrentStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        _onConnectivityChanged(results);
      }
    } catch (e) {
      debugPrint('[NetworkMonitor] check status error: $e');
    }
  }

  /// 网络质量探测（ping 延迟）
  Future<void> _probeNetworkQuality() async {
    if (!isNetworkAvailable) {
      _pingDelayMs = 9999;
      return;
    }

    final sw = Stopwatch()..start();
    try {
      final ms = await probeNetworkLatency();
      sw.stop();
      _pingDelayMs = ms;
    } catch (e) {
      _pingDelayMs = 9999; // ping 失败
    }
  }

  /// 更新状态（带防抖）
  void _updateStatus(NetworkStatus newStatus) {
    if (newStatus == _currentStatus) return;
    
    final now = DateTime.now();
    if (_lastStatusChangeTime != null && 
        now.difference(_lastStatusChangeTime!).inSeconds < 3) {
      _statusChangeCount++;
      if (_statusChangeCount < 3) return; // 3s 内变化 3 次才判定
    } else {
      _statusChangeCount = 0;
    }
    
    _lastStatusChangeTime = now;
    _currentStatus = newStatus;
    _statusController.add(newStatus);
    
    debugPrint('[NetworkMonitor] Status changed to: ${newStatus.name}');
  }
}
