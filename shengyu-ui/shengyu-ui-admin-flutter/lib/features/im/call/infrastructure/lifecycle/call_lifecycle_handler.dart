import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/lifecycle/app_lifecycle_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/background/background_mode_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/notification/call_notification_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

/// 通话生命周期处理器
/// 
/// 处理应用前后台切换时的通话状态管理：
/// - 应用进入后台：关闭摄像头，保持音频，显示后台通知
/// - 应用恢复前台：恢复视频流，同步状态
/// - 应用被杀死：终止通话，保存记录
/// 
/// 企业级特性：
/// - 后台通话通知（使用本地通知插件）
/// - 状态自动同步（从服务端恢复）
/// - 资源优化（后台关闭摄像头，保持音频）
class CallLifecycleHandler {
  CallLifecycleHandler({
    required CallController callController,
  })  : _callController = callController;

  final CallController _callController;
  
  StreamSubscription<ShengyuAppLifecycleState>? _lifecycleSubscription;
  bool _isVideoDisabledByBackground = false;
  int? _backgroundNotificationId;

  /// 开始监听生命周期变化
  void start() {
    final lifecycleManager = AppLifecycleManager();
    _lifecycleSubscription = lifecycleManager.stateStream.listen(_onLifecycleChanged);
    debugPrint('[CallLifecycleHandler] 开始监听应用生命周期');
  }

  /// 停止监听
  void stop() {
    _lifecycleSubscription?.cancel();
    _lifecycleSubscription = null;
    debugPrint('[CallLifecycleHandler] 停止监听应用生命周期');
  }

  /// 处理生命周期变化
  void _onLifecycleChanged(ShengyuAppLifecycleState newState) {
    final callState = _callController.currentCallState;
    
    // 仅在通话进行中时处理
    if (callState.pageStatus != CallPageStatus.connected) {
      return;
    }

    switch (newState) {
      case ShengyuAppLifecycleState.paused:
      case ShengyuAppLifecycleState.hidden:
      case ShengyuAppLifecycleState.inactive:
        _handleAppBackgrounded();
        break;
      case ShengyuAppLifecycleState.resumed:
        _handleAppForegrounded();
        break;
      case ShengyuAppLifecycleState.detached:
        _handleAppTerminated();
        break;
    }
  }

  /// 应用进入后台
  void _handleAppBackgrounded() {
    debugPrint('[CallLifecycleHandler] 应用进入后台');
    
    final callState = _callController.currentCallState;
    final mediaState = callState.mediaState;
    
    // 如果是视频通话且摄像头开启，关闭摄像头以节省资源
    if (callState.callType == CallType.video && mediaState.cameraEnabled) {
      _callController.toggleCamera();
      _isVideoDisabledByBackground = true;
      debugPrint('[CallLifecycleHandler] 后台模式：关闭摄像头');
    }
    
    // 显示后台通话通知
    _showBackgroundCallNotification(callState);
    
    // 启用后台模式（iOS 音频模式 / Android 音频焦点）
    BackgroundModeManager.instance.enableBackgroundMode();
  }

  /// 应用恢复前台
  void _handleAppForegrounded() async {
    debugPrint('[CallLifecycleHandler] 应用恢复前台');

    try {
      // 恢复音频会话（关键：后台可能导致音频会话配置丢失）
      await _callController.restoreAudioSessionFromForeground();

      // 如果是因为后台而关闭的视频，恢复它
      if (_isVideoDisabledByBackground) {
        final callState = _callController.currentCallState;
        if (callState.callType == CallType.video && !callState.mediaState.cameraEnabled) {
          _callController.toggleCamera();
          debugPrint('[CallLifecycleHandler] 前台模式：恢复摄像头');
        }
        _isVideoDisabledByBackground = false;
      }

      // 移除后台通知
      _removeBackgroundNotification();

      // 同步通话状态
      _syncCallState();
    } catch (e, stackTrace) {
      debugPrint('[CallLifecycleHandler] 应用恢复前台处理失败: $e\n$stackTrace');
    }
  }

  /// 应用被杀死
  void _handleAppTerminated() async {
    debugPrint('[CallLifecycleHandler] 应用即将被杀死');
    
    final callState = _callController.currentCallState;
    if (callState.pageStatus == CallPageStatus.connected) {
      // 终止通话（等待异步完成，确保资源正确释放）
      try {
        await _callController.hangup();
        debugPrint('[CallLifecycleHandler] 应用终止：已挂断通话');
      } catch (e, stackTrace) {
        debugPrint('[CallLifecycleHandler] 应用终止挂断通话失败: $e\n$stackTrace');
      }
    }
    
    // 关键修复：清理所有通话相关通知（包括后台通知和来电通知）
    // 确保应用被杀死时不会残留任何通知
    CallNotificationManager.instance.cancelAllNotifications();
  }

  /// 同步通话状态
  Future<void> _syncCallState() async {
    final callState = _callController.currentCallState;
    if (callState.callSessionId.isEmpty) {
      return;
    }
    
    try {
      // 通过 CallController 的 onStateSync 方法同步状态
      await _callController.onStateSync();
      debugPrint('[CallLifecycleHandler] 通话状态同步成功');
    } catch (e) {
      debugPrint('[CallLifecycleHandler] 通话状态同步失败: $e');
    }
  }

  /// 显示后台通话通知
  /// 
  /// 使用 CallNotificationManager 显示后台通话通知
  void _showBackgroundCallNotification(CallState callState) {
    final callType = callState.callType == CallType.video ? '视频' : '语音';
    final duration = _formatDuration(callState.elapsedSeconds);
    
    debugPrint('[CallLifecycleHandler] 显示后台通知: $callType通话中 ($duration)');
    
    CallNotificationManager.instance.showBackgroundCallNotification(
      callType: callType,
      duration: duration,
    );
    
    _backgroundNotificationId = 1;
  }

  /// 移除后台通知
  void _removeBackgroundNotification() {
    if (_backgroundNotificationId == null) {
      return;
    }
    
    debugPrint('[CallLifecycleHandler] 移除后台通知');
    
    CallNotificationManager.instance.cancelBackgroundNotification();
    _backgroundNotificationId = null;
  }

  /// 格式化通话时长
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
