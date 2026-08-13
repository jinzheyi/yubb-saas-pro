import 'dart:async';

import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

class MockCallRepository implements CallRepository {
  MockCallRepository() : _socketController = StreamController.broadcast();

  final StreamController<CallSocketEvent> _socketController;

  @override
  Future<void> accept({required String callSessionId, required String deviceId}) async {
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
    required String calleeId,
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
  Future<CallInviteResult> createGroupInvite({
    required String chatId,
    required String groupId,
    required CallType callType,
    required List<String> inviteeIds,
    String? deviceId,
  }) {
    return createInvite(chatId: chatId, callType: callType, calleeId: inviteeIds.first);
  }

  @override
  Future<Map<String, dynamic>> inviteGroupMembers({
    required String callSessionId, required String groupId, required List<String> inviteeIds,
  }) async => {'callSessionId': callSessionId, 'invitedCount': inviteeIds.length};

  @override
  Future<void> leaveGroupCall({required String callSessionId}) async {
    _socketController.add(
      CallSocketEvent(
        type: CallSocketEventType.groupLeave,
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

  @override
  Future<List<CallRecord>> getCallRecords({
    int? callType,
    DateTime? startTime,
    DateTime? endTime,
    String? chatId,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    // Mock 实现：直接返回空列表。
    return <CallRecord>[];
  }

  @override
  Future<void> sendMediaStateUpdate({
    required String callSessionId,
    required bool cameraEnabled,
    required bool microphoneEnabled,
  }) async {
    // Mock 实现：模拟发送媒体状态更新。
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 释放资源，防止内存泄漏。
  void dispose() {
    if (!_socketController.isClosed) {
      _socketController.close();
    }
  }
}
