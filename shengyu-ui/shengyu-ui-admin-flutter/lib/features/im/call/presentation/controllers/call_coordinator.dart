import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';

class CallCoordinator {
  const CallCoordinator(this._router);

  final GoRouter _router;

  void openIncomingCall(CallLaunchArgs args) {
    // 关键修复：添加参数验证，防止空值导致路由异常
    if (args.callSessionId.isEmpty) {
      debugPrint('[CallCoordinator] openIncomingCall: callSessionId 为空，跳过导航');
      return;
    }
    _router.pushNamed(RouteNames.callIncoming, extra: args);
  }

  void openOutgoingCall(CallLaunchArgs args) {
    // 关键修复：添加参数验证，防止空值导致路由异常
    if (args.callSessionId.isEmpty) {
      debugPrint('[CallCoordinator] openOutgoingCall: callSessionId 为空，跳过导航');
      return;
    }
    _router.pushNamed(RouteNames.callOutgoing, extra: args);
  }

  void openCallSession(CallLaunchArgs args) {
    // 关键修复：添加参数验证，防止空值导致路由异常
    if (args.callSessionId.isEmpty) {
      debugPrint('[CallCoordinator] openCallSession: callSessionId 为空，跳过导航');
      return;
    }
    _router.pushReplacementNamed(RouteNames.callSession, extra: args);
  }

  void openGroupCallSession(CallLaunchArgs args) {
    // 关键修复：添加参数验证，防止空值导致路由异常
    if (args.callSessionId.isEmpty) {
      debugPrint('[CallCoordinator] openGroupCallSession: callSessionId 为空，跳过导航');
      return;
    }
    // 关键修复：群组通话必须提供 groupId
    if (args.groupId == null || args.groupId!.isEmpty) {
      debugPrint('[CallCoordinator] openGroupCallSession: groupId 为空，跳过导航');
      return;
    }
    _router.pushReplacementNamed(RouteNames.groupCallSession, extra: args);
  }

  void openGroupOutgoingCall(CallLaunchArgs args) {
    // 关键修复：添加参数验证，防止空值导致路由异常
    if (args.callSessionId.isEmpty) {
      debugPrint('[CallCoordinator] openGroupOutgoingCall: callSessionId 为空，跳过导航');
      return;
    }
    // 关键修复：群组通话必须提供 groupId
    if (args.groupId == null || args.groupId!.isEmpty) {
      debugPrint('[CallCoordinator] openGroupOutgoingCall: groupId 为空，跳过导航');
      return;
    }
    _router.pushNamed(RouteNames.groupOutgoingCall, extra: args);
  }

  void closeCallFlow() {
    if (_router.canPop()) {
      _router.pop();
    }
  }
}
