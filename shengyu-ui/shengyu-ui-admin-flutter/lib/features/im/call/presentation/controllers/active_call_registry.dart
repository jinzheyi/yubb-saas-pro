import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';

class ActiveCallRegistry {
  const ActiveCallRegistry();

  static CallLaunchArgs? _activeCall;

  CallLaunchArgs? get current => _activeCall;

  void register(CallLaunchArgs args) {
    _activeCall = args;
  }

  void clear([String? callSessionId]) {
    if (callSessionId == null || _activeCall?.callSessionId == callSessionId) {
      _activeCall = null;
    }
  }
}
