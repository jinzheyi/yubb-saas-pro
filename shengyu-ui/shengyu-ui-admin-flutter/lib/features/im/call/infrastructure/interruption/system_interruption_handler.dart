import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

/// 系统级中断处理器
/// 
/// 处理通话过程中的系统级中断事件：
/// - 系统来电中断：暂停通话，等待用户选择
/// - 闹钟响起：降低通话音量，继续通话
/// - 低电量模式：降低视频质量，关闭不必要的功能
/// - 网络切换：ICE 重新协商，保持通话
class SystemInterruptionHandler {
  SystemInterruptionHandler({
    required CallController callController,
  }) : _callController = callController;

  final CallController _callController;
  
  bool _isPausedBySystemCall = false;
  bool _isVideoDisabledByLowBattery = false;

  /// 检查通话是否仍在进行中
  bool _isCallActive() {
    final callState = _callController.currentCallState;
    return callState.pageStatus == CallPageStatus.connected;
  }

  /// 处理系统来电
  Future<void> handlePhoneCallIncoming() async {
    debugPrint('[SystemInterruptionHandler] 系统来电中断');
    
    if (!_isCallActive()) {
      return;
    }

    final callState = _callController.currentCallState;

    // 1. 暂停通话音频（麦克风）
    if (callState.mediaState.microphoneEnabled) {
      _callController.toggleMute();
      _isPausedBySystemCall = true;
    }

    // 2. 系统来电界面由操作系统自动显示，无需应用层干预
    
    // 3. 等待用户选择（由原生层回调）
    // 用户可以选择：
    // - 结束 IM 通话，接听系统来电
    // - 忽略系统来电，继续 IM 通话
  }

  /// 系统来电结束（用户已处理）
  Future<void> handlePhoneCallEnded({required bool shouldResumeCall}) async {
    debugPrint('[SystemInterruptionHandler] 系统来电结束: shouldResumeCall=$shouldResumeCall');
    
    if (!shouldResumeCall) {
      // 用户选择结束 IM 通话
      try {
        await _callController.hangup();
      } catch (e) {
        debugPrint('[SystemInterruptionHandler] 挂断通话失败: $e');
      }
      _isPausedBySystemCall = false;
      return;
    }

    // 恢复通话（需要检查通话是否仍在进行中）
    if (_isPausedBySystemCall && _isCallActive()) {
      final callState = _callController.currentCallState;
      if (!callState.mediaState.microphoneEnabled) {
        _callController.toggleMute();
      }
      _isPausedBySystemCall = false;
    } else {
      _isPausedBySystemCall = false;
    }
  }

  /// 处理闹钟响起
  Future<void> handleAlarmStarted() async {
    debugPrint('[SystemInterruptionHandler] 闹钟响起');
    
    if (!_isCallActive()) {
      return;
    }

    // 降低通话音量（不暂停）
    // 通过 audio_session 包调整音频焦点为 duck 模式
    try {
      await _callController.duckAudioFocus();
    } catch (e) {
      debugPrint('[SystemInterruptionHandler] 降低音量失败: $e');
    }
  }

  /// 处理闹钟结束
  Future<void> handleAlarmEnded() async {
    debugPrint('[SystemInterruptionHandler] 闹钟结束');
    
    // 恢复通话音量
    // 通过 audio_session 包恢复音频焦点为正常模式
    try {
      await _callController.restoreAudioFocus();
    } catch (e) {
      debugPrint('[SystemInterruptionHandler] 恢复音量失败: $e');
    }
  }

  /// 处理低电量模式
  Future<void> handleLowBattery({required int batteryLevel}) async {
    debugPrint('[SystemInterruptionHandler] 低电量模式: $batteryLevel%');
    
    if (!_isCallActive()) {
      return;
    }

    final callState = _callController.currentCallState;

    if (batteryLevel < 10) {
      // 电量低于 10%：降低视频质量
      if (callState.callType == CallType.video && callState.mediaState.cameraEnabled) {
        try {
          // 通过 WebRTC 调整视频编码参数，降低帧率和码率
          await _callController.setVideoQuality(lowQuality: true);
          debugPrint('[SystemInterruptionHandler] 降低视频质量');
        } catch (e) {
          debugPrint('[SystemInterruptionHandler] 降低视频质量失败: $e');
        }
      }

      // 关闭屏幕共享
      if (callState.mediaState.screenShareEnabled) {
        try {
          await _callController.toggleScreenShare();
          debugPrint('[SystemInterruptionHandler] 关闭屏幕共享');
        } catch (e) {
          debugPrint('[SystemInterruptionHandler] 关闭屏幕共享失败: $e');
        }
      }
    }

    if (batteryLevel < 5) {
      // 电量低于 5%：关闭视频
      if (callState.callType == CallType.video && callState.mediaState.cameraEnabled) {
        try {
          _callController.toggleCamera();
          _isVideoDisabledByLowBattery = true;
          debugPrint('[SystemInterruptionHandler] 关闭视频');
        } catch (e) {
          debugPrint('[SystemInterruptionHandler] 关闭视频失败: $e');
        }
      }

      // 提示用户电量极低
      // 注意：UI 提示由上层页面负责监听电量状态并显示对话框
      debugPrint('[SystemInterruptionHandler] 电量极低，建议显示警告对话框');
    }
  }

  /// 处理电量恢复
  Future<void> handleBatteryRecovered({required int batteryLevel}) async {
    debugPrint('[SystemInterruptionHandler] 电量恢复: $batteryLevel%');
    
    if (batteryLevel >= 20 && _isVideoDisabledByLowBattery && _isCallActive()) {
      final callState = _callController.currentCallState;
      if (callState.callType == CallType.video && !callState.mediaState.cameraEnabled) {
        try {
          // 恢复视频
          _callController.toggleCamera();
          _isVideoDisabledByLowBattery = false;
          debugPrint('[SystemInterruptionHandler] 恢复视频');
        } catch (e) {
          debugPrint('[SystemInterruptionHandler] 恢复视频失败: $e');
        }
      }
      
      // 恢复视频质量（从低质量恢复到正常质量）
      try {
        await _callController.setVideoQuality(lowQuality: false);
        debugPrint('[SystemInterruptionHandler] 恢复正常视频质量');
      } catch (e) {
        debugPrint('[SystemInterruptionHandler] 恢复正常视频质量失败: $e');
      }
    }
  }

  /// 处理网络切换（WiFi -> 移动网络）
  void handleNetworkSwitched({required String fromNetwork, required String toNetwork}) {
    debugPrint('[SystemInterruptionHandler] 网络切换: $fromNetwork -> $toNetwork');
    
    if (!_isCallActive()) {
      return;
    }

    // WebRTC 会自动处理 ICE 重新协商
    // 这里只需要记录日志和可能的 UI 提示
    debugPrint('[SystemInterruptionHandler] 网络切换，WebRTC 将自动重新协商');
  }

  /// 清理资源
  void dispose() {
    _isPausedBySystemCall = false;
    _isVideoDisabledByLowBattery = false;
  }
}
