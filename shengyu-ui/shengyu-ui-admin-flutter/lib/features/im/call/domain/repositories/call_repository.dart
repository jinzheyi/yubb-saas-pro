import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';

abstract class CallRepository {
  Future<CallInviteResult> createInvite({
    required String chatId,
    required CallType callType,
  });

  Future<void> accept({required String callSessionId});

  Future<void> reject({required String callSessionId});

  Future<void> cancel({required String callSessionId});

  Future<void> hangup({required String callSessionId});

  Future<ActiveCallStateResult> syncState({required String callSessionId});

  Stream<CallSocketEvent> watchSocketEvents();
}
