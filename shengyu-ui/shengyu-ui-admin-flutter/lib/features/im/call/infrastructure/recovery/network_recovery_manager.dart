import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/sync_active_call_state_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_media_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

/// 网络恢复管理器
/// 
/// 处理通话过程中的网络异常恢复：
/// - 网络断开：显示重连界面，启动重连计时器
/// - 网络恢复：重新建立 WebSocket 连接，重新加入 Janus 房间
/// - 重连超时：终止通话
/// 
/// 企业级特性：
/// - 指数退避重连策略（2s, 4s, 8s, 16s...）
/// - 状态同步与媒体流恢复
/// - 超时保护机制
/// - 真实网络状态监听（connectivity_plus）
/// - 网络质量降级自适应
class NetworkRecoveryManager {
  NetworkRecoveryManager({
    required CallController callController,
    required SyncActiveCallStateUseCase syncActiveCallStateUseCase,
    required CallMediaController callMediaController,
    this.reconnectTimeoutSeconds = 30,
    this.maxRetryAttempts = 5,
  })  : _callController = callController,
        _syncActiveCallStateUseCase = syncActiveCallStateUseCase,
        _callMediaController = callMediaController;

  final CallController _callController;
  final SyncActiveCallStateUseCase _syncActiveCallStateUseCase;
  final CallMediaController _callMediaController;
  final int reconnectTimeoutSeconds;
  final int maxRetryAttempts;

  Timer? _reconnectTimer;
  Timer? _timeoutTimer;
  int _retryAttempts = 0;
  bool _isReconnecting = false;
  
  /// `connectivity_plus` 网络监听。
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// 上次已知的网络状态
  NetworkStatus _lastNetworkStatus = NetworkStatus.connected;

  /// 启动网络监听
  /// 
  /// 使用 connectivity_plus 监听真实网络变化
  void startNetworkMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    debugPrint('[NetworkRecoveryManager] 开始监听网络状态变化');
  }

  /// 网络状态变化回调
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final status = _mapConnectivityToNetworkStatus(results);
    
    if (status == _lastNetworkStatus) return;
    
    debugPrint('[NetworkRecoveryManager] 网络状态变更: $_lastNetworkStatus -> $status');
    _lastNetworkStatus = status;
    
    onNetworkChanged(status);
  }

  /// 将 connectivity_plus 结果映射为 NetworkStatus
  NetworkStatus _mapConnectivityToNetworkStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.disconnected;
    }
    
    // 如果有 WiFi 或移动网络，视为已连接
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkStatus.connected;
    }
    
    // 其他情况视为质量下降
    return NetworkStatus.degraded;
  }

  /// 网络状态变化监听
  void onNetworkChanged(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.disconnected:
        _handleNetworkDisconnected();
        break;
      case NetworkStatus.connected:
        _handleNetworkConnected();
        break;
      case NetworkStatus.degraded:
        _handleNetworkDegraded();
        break;
    }
  }

  /// 网络断开处理
  void _handleNetworkDisconnected() {
    debugPrint('[NetworkRecoveryManager] 网络断开');
    
    final callState = _callController.currentCallState;
    if (callState.pageStatus != CallPageStatus.connected &&
        callState.pageStatus != CallPageStatus.reconnecting) {
      return;
    }

    // 1. 显示重连中界面
    _callController.markReconnecting();
    _isReconnecting = true;

    // 2. 启动重连超时计时器
    _startReconnectTimeout();

    // 3. 立即尝试重连
    _attemptReconnect();
  }

  /// 网络恢复处理
  void _handleNetworkConnected() {
    debugPrint('[NetworkRecoveryManager] 网络恢复');
    
    if (_isReconnecting) {
      // 网络恢复后立即尝试重连
      _retryAttempts = 0;
      _attemptReconnect();
    }
  }

  /// 网络质量下降处理
  void _handleNetworkDegraded() {
    debugPrint('[NetworkRecoveryManager] 网络质量下降');
    
    // 网络质量下降时，通知媒体控制器降低视频质量
    // 这部分逻辑已经在 AdaptiveBitrateController 中实现
    // 这里仅做日志记录
  }

  /// 尝试重连
  Future<void> _attemptReconnect() async {
    if (_retryAttempts >= maxRetryAttempts) {
      debugPrint('[NetworkRecoveryManager] 重连次数已达上限 ($maxRetryAttempts)');
      _handleReconnectFailed();
      return;
    }

    _retryAttempts++;
    debugPrint('[NetworkRecoveryManager] 尝试重连 ($_retryAttempts/$maxRetryAttempts)');

    try {
      // 1. 查询通话状态
      final callState = _callController.currentCallState;
      final callSessionId = callState.callSessionId;
      
      if (callSessionId.isEmpty) {
        debugPrint('[NetworkRecoveryManager] 通话会话 ID 为空');
        _handleReconnectFailed();
        return;
      }

      // 2. 同步通话状态（从服务端恢复）
      final synced = await _syncActiveCallStateUseCase.execute(
        callSessionId: callSessionId,
      );
      
      debugPrint('[NetworkRecoveryManager] 状态同步完成, pageStatus=${synced.pageStatus}');

      // 3. 根据同步结果恢复状态
      if (synced.pageStatus == CallPageStatus.connected) {
        // 通话仍在进行中，恢复连接状态
        _callController.restoreConnected();

        // 恢复音频会话（关键：网络断开可能导致音频会话丢失）
        await _callMediaController.restoreAudioSession();

        // 关键修复：重启生命周期处理器和系统中断处理器
        // 进入重连状态时这些处理器被停止了，重连成功后必须恢复它们的监听
        _callController.restartHandlersAfterReconnect();

        _isReconnecting = false;
        _retryAttempts = 0;
        _timeoutTimer?.cancel();
        _timeoutTimer = null;

        debugPrint('[NetworkRecoveryManager] 重连成功，通话已恢复，音频会话已恢复，处理器已重启');
      } else if (synced.pageStatus == CallPageStatus.ended ||
                 synced.pageStatus == CallPageStatus.failed) {
        // 通话已经结束
        _isReconnecting = false;
        _retryAttempts = 0;
        _timeoutTimer?.cancel();
        _timeoutTimer = null;
        
        debugPrint('[NetworkRecoveryManager] 通话已结束，清理重连状态');
      } else {
        // 其他状态，安排下次重试
        _scheduleReconnectRetry();
      }
    } catch (e) {
      debugPrint('[NetworkRecoveryManager] 重连失败: $e');
      _scheduleReconnectRetry();
    }
  }

  /// 安排下一次重连尝试（指数退避策略）
  void _scheduleReconnectRetry() {
    if (_retryAttempts >= maxRetryAttempts) {
      _handleReconnectFailed();
      return;
    }

    // 真正的指数退避策略: 2^attempt 秒 (2s, 4s, 8s, 16s, 32s)
    final delaySeconds = _calculateBackoffDelay(_retryAttempts);
    debugPrint('[NetworkRecoveryManager] $delaySeconds秒后重试重连 (第$_retryAttempts次)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_isReconnecting) {
        _attemptReconnect();
      }
    });
  }

  /// 计算指数退避延迟
  /// 
  /// 公式: 2^attempt 秒，最大 30 秒
  /// 重试退避：attempt=1 -> 2s，attempt=2 -> 4s，attempt=3 -> 8s，attempt=4 -> 16s，attempt=5 -> 30s。
  int _calculateBackoffDelay(int attempt) {
    final delay = (1 << attempt).clamp(1, 30);
    return delay;
  }

  /// 启动重连超时计时器
  void _startReconnectTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(Duration(seconds: reconnectTimeoutSeconds), () {
      if (_isReconnecting) {
        debugPrint('[NetworkRecoveryManager] 重连超时 ($reconnectTimeoutSeconds秒)');
        _handleReconnectFailed();
      }
    });
  }

  /// 重连失败处理
  void _handleReconnectFailed() {
    // 关键修复：防止递归调用 hangup()
    // 如果已经不在重连状态，直接返回
    if (!_isReconnecting) {
      debugPrint('[NetworkRecoveryManager] _handleReconnectFailed: 已不在重连状态，跳过');
      return;
    }

    // 关键修复：先清理所有定时器和状态，再调用 hangup()
    // 防止 hangup() 触发的回调再次进入此方法
    _isReconnecting = false;
    _retryAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    // 终止通话（异步调用，避免阻塞当前清理流程）
    Future.microtask(() {
      _callController.hangup();
      debugPrint('[NetworkRecoveryManager] 重连失败，已终止通话');
    });
  }

  /// 是否正在重连中
  bool get isReconnecting => _isReconnecting;
  
  /// 当前重试次数
  int get retryAttempts => _retryAttempts;

  /// 清理资源
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isReconnecting = false;
    _retryAttempts = 0;
    debugPrint('[NetworkRecoveryManager] 资源已清理');
  }
}

/// 网络状态枚举
enum NetworkStatus {
  connected,    // 已连接
  disconnected, // 已断开
  degraded,     // 质量下降
}
