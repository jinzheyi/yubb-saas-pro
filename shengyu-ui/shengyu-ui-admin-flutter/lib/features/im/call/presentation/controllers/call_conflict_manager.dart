import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/active_call_registry.dart';

/// 通话冲突动作枚举
enum CallConflictAction {
  accept,        // 接受新通话
  reject,        // 拒绝新通话
  ignore,        // 忽略（重复通知）
  showWaitingUI, // 显示通话等待界面
}

/// 通话冲突结果
class CallConflictResult {
  final CallConflictAction action;
  final String callId;
  final String? preemptedCallId;
  final String? currentCallId;
  final String? reason;

  const CallConflictResult({
    required this.action,
    required this.callId,
    this.preemptedCallId,
    this.currentCallId,
    this.reason,
  });

  @override
  String toString() {
    return 'CallConflictResult(action: $action, callId: $callId, '
        'preemptedCallId: $preemptedCallId, currentCallId: $currentCallId, '
        'reason: $reason)';
  }
}

/// 通话冲突管理器
/// 
/// 处理多通话冲突场景，参考微信通话等待机制：
/// - 通话中收到新来电时，显示"通话等待"界面
/// - 用户可选择：挂断当前通话接听新来电、拒绝新来电保持当前通话、保持当前通话接听新来电
class CallConflictManager {
  final ActiveCallRegistry _registry;

  CallConflictManager(this._registry);

  /// 处理新来电冲突
  /// 
  /// 当收到新来电时，检查是否有正在进行的通话，如果有则处理冲突
  Future<CallConflictResult> handleIncomingCall(CallLaunchArgs invite) async {
    // 验证输入
    if (invite.callSessionId.isEmpty) {
      debugPrint('[CallConflictManager] 来电 callSessionId 为空，拒绝处理');
      return const CallConflictResult(
        action: CallConflictAction.reject,
        callId: '',
        reason: 'INVALID_CALL_ID',
      );
    }

    final currentCall = _registry.current;

    // 1. 无当前通话：直接接受
    if (currentCall == null) {
      debugPrint('[CallConflictManager] 无当前通话，接受新来电: ${invite.callSessionId}');
      return CallConflictResult(
        action: CallConflictAction.accept,
        callId: invite.callSessionId,
      );
    }

    // 2. 同一通话（多设备通知）：忽略
    if (currentCall.callSessionId == invite.callSessionId) {
      debugPrint('[CallConflictManager] 重复来电通知，忽略: ${invite.callSessionId}');
      return CallConflictResult(
        action: CallConflictAction.ignore,
        callId: invite.callSessionId,
        reason: 'DUPLICATE_CALL',
      );
    }

    // 3. 存在当前通话：显示通话等待界面，让用户选择
    debugPrint('[CallConflictManager] 存在当前通话 ${currentCall.callSessionId}，'
        '新来电 ${invite.callSessionId}，显示等待界面');
    return CallConflictResult(
      action: CallConflictAction.showWaitingUI,
      callId: invite.callSessionId,
      currentCallId: currentCall.callSessionId,
    );
  }

  /// 解决通话冲突 - 新通话优先策略
  /// 
  /// 挂断当前通话，接受新通话
  Future<CallConflictResult> resolveWithNewCallPriority({
    required CallLaunchArgs currentCall,
    required CallLaunchArgs newInvite,
    required Future<void> Function(String callSessionId, String reason) hangupCall,
  }) async {
    // 验证输入
    if (currentCall.callSessionId.isEmpty) {
      debugPrint('[CallConflictManager] 当前通话 callSessionId 为空');
      return CallConflictResult(
        action: CallConflictAction.reject,
        callId: newInvite.callSessionId,
        reason: 'INVALID_CURRENT_CALL_ID',
      );
    }

    if (newInvite.callSessionId.isEmpty) {
      debugPrint('[CallConflictManager] 新来电 callSessionId 为空');
      return CallConflictResult(
        action: CallConflictAction.reject,
        callId: newInvite.callSessionId,
        reason: 'INVALID_NEW_CALL_ID',
      );
    }

    try {
      debugPrint('[CallConflictManager] 新通话优先：挂断 ${currentCall.callSessionId}，'
          '接受 ${newInvite.callSessionId}');
      
      // 挂断当前通话
      await hangupCall(currentCall.callSessionId, 'NEW_CALL_PREEMPT');

      // 接受新通话
      return CallConflictResult(
        action: CallConflictAction.accept,
        callId: newInvite.callSessionId,
        preemptedCallId: currentCall.callSessionId,
      );
    } catch (e, stackTrace) {
      debugPrint('[CallConflictManager] 挂断当前通话失败: $e');
      debugPrint('[CallConflictManager] 堆栈: $stackTrace');
      return CallConflictResult(
        action: CallConflictAction.reject,
        callId: newInvite.callSessionId,
        reason: 'HANGUP_FAILED: $e',
      );
    }
  }

  /// 解决通话冲突 - 当前通话优先策略
  /// 
  /// 拒绝新通话，保持当前通话
  Future<CallConflictResult> resolveWithCurrentCallPriority({
    required CallLaunchArgs newInvite,
    required Future<void> Function(String callSessionId, String reason) rejectCall,
  }) async {
    // 验证输入
    if (newInvite.callSessionId.isEmpty) {
      debugPrint('[CallConflictManager] 新来电 callSessionId 为空');
      return CallConflictResult(
        action: CallConflictAction.reject,
        callId: newInvite.callSessionId,
        reason: 'INVALID_CALL_ID',
      );
    }

    try {
      debugPrint('[CallConflictManager] 当前通话优先：拒绝新来电 ${newInvite.callSessionId}');
      
      // 拒绝新通话
      await rejectCall(newInvite.callSessionId, 'ON_ANOTHER_CALL');

      return CallConflictResult(
        action: CallConflictAction.reject,
        callId: newInvite.callSessionId,
        reason: 'CURRENT_CALL_PRIORITY',
      );
    } catch (e, stackTrace) {
      debugPrint('[CallConflictManager] 拒绝新通话失败: $e');
      debugPrint('[CallConflictManager] 堆栈: $stackTrace');
      return CallConflictResult(
        action: CallConflictAction.reject,
        callId: newInvite.callSessionId,
        reason: 'REJECT_FAILED: $e',
      );
    }
  }

  /// 检查用户是否忙线
  /// 
  /// 用于后端判断是否应该返回忙线信号
  bool isUserBusy() => _registry.current != null;

  /// 获取当前通话信息
  CallLaunchArgs? getCurrentCall() => _registry.current;
}
