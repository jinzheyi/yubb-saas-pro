import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';

/// 通话清理原因枚举
/// 
/// 用于边界场景处理（登出/被踢/切换企业等），与 CallEndReason 区分
enum CallCleanupReason {
  userLogout,      // 用户主动登出
  deviceKicked,    // 设备被踢下线
  tokenExpired,    // Token 过期
  tenantSwitch,    // 切换企业
  newCallPreempt,  // 新通话抢占
  normalHangup,    // 正常挂断
}

/// 活跃通话注册表
/// 
/// 管理当前设备的活跃通话，处理登出/被踢下线等边界场景
class ActiveCallRegistry {
  const ActiveCallRegistry();

  static CallLaunchArgs? _activeCall;
  
  /// 通话结束回调（用于通知 CallController 执行清理）
  static Future<void> Function(CallCleanupReason reason)? _onCallEnd;

  CallLaunchArgs? get current => _activeCall;

  void register(CallLaunchArgs args) {
    _activeCall = args;
  }

  void clear([String? callSessionId]) {
    if (callSessionId == null || _activeCall?.callSessionId == callSessionId) {
      _activeCall = null;
    }
  }

  /// 设置通话结束回调
  void setOnCallEnd(Future<void> Function(CallCleanupReason reason)? callback) {
    _onCallEnd = callback;
  }

  /// 处理用户登出
  /// 
  /// 终止当前通话并清理资源
  Future<void> handleUserLogout() async {
    if (_activeCall == null) {
      return;
    }

    // 通知 CallController 执行通话结束流程
    if (_onCallEnd != null) {
      await _onCallEnd!(CallCleanupReason.userLogout);
    }

    // 清理注册表
    clear();
  }

  /// 处理设备被踢下线
  /// 
  /// 终止当前通话并清理资源
  Future<void> handleDeviceKicked() async {
    if (_activeCall == null) {
      return;
    }

    // 通知 CallController 执行通话结束流程
    if (_onCallEnd != null) {
      await _onCallEnd!(CallCleanupReason.deviceKicked);
    }

    // 清理注册表
    clear();
  }

  /// 处理 Token 过期
  /// 
  /// 尝试无感刷新，避免通话中断
  Future<void> handleTokenExpired() async {
    // Token 过期时，通话应该继续
    // 由 AuthController 负责无感刷新 Token
    // 这里只记录日志
  }

  /// 检查是否有活跃通话
  bool hasActiveCall() {
    return _activeCall != null;
  }

  /// 获取当前通话 ID
  String? get currentCallId => _activeCall?.callSessionId;
}
