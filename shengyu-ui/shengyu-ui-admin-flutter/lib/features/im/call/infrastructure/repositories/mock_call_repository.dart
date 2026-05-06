import 'dart:async';

import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

class MockCallRepository implements CallRepository {
  MockCallRepository() : _socketController = StreamController.broadcast();

  final StreamController<CallSocketEvent> _socketController;

  @override
  Future<void> accept({required String callSessionId}) async {
    _socketController.add(
      CallSocketEvent(
        type: CallSocketEventType.accepted,
        callSessionId: callSessionId,
      ),
    );
  }

  @override
  Future<void> cancel({required String callSessionId}) async {
    _socketController.add(
      CallSocketEvent(
        type: CallSocketEventType.cancelled,
        callSessionId: callSessionId,
      ),
    );
  }

  @override
  Future<CallInviteResult> createInvite({
    required String chatId,
    required CallType callType,
  }) async {
    final callSessionId =
        'call_${DateTime.now().microsecondsSinceEpoch}_$chatId';
    return CallInviteResult(
      callSessionId: callSessionId,
      inviteId: 'invite_$callSessionId',
      chatId: chatId,
      callType: callType,
    );
  }

  @override
  Future<void> hangup({required String callSessionId}) async {
    _socketController.add(
      CallSocketEvent(
        type: CallSocketEventType.ended,
        callSessionId: callSessionId,
      ),
    );
  }

  @override
  Future<void> reject({required String callSessionId}) async {
    _socketController.add(
      CallSocketEvent(
        type: CallSocketEventType.rejected,
        callSessionId: callSessionId,
      ),
    );
  }

  @override
  Future<ActiveCallStateResult> syncState({
    required String callSessionId,
  }) async {
    return ActiveCallStateResult(
      pageStatus: CallPageStatus.connecting,
      callSessionId: callSessionId,
    );
  }

  @override
  Stream<CallSocketEvent> watchSocketEvents() {
    return _socketController.stream;
  }
}
