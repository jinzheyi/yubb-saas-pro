import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';

class CallCoordinator {
  const CallCoordinator(this._router);

  final GoRouter _router;

  void openIncomingCall(CallLaunchArgs args) {
    _router.pushNamed(RouteNames.callIncoming, extra: args);
  }

  void openOutgoingCall(CallLaunchArgs args) {
    _router.pushNamed(RouteNames.callOutgoing, extra: args);
  }

  void openCallSession(CallLaunchArgs args) {
    _router.pushReplacementNamed(RouteNames.callSession, extra: args);
  }

  void closeCallFlow() {
    if (_router.canPop()) {
      _router.pop();
    }
  }
}
