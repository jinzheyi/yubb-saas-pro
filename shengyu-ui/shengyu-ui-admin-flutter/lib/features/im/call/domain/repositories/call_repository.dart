import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';

abstract class CallRepository {
  Future<CallInviteResult> createInvite({
    required String chatId,
    required CallType callType,
    required String calleeId,
  });

  Future<CallInviteResult> createGroupInvite({
    required String chatId,
    required String groupId,
    required CallType callType,
    required List<String> inviteeIds,
    String? deviceId,
  });

  Future<Map<String, dynamic>> inviteGroupMembers({
    required String callSessionId,
    required String groupId,
    required List<String> inviteeIds,
  });

  Future<void> accept({required String callSessionId, required String deviceId});

  Future<void> reject({required String callSessionId});

  Future<void> cancel({required String callSessionId});

  Future<void> hangup({required String callSessionId});

  Future<void> leaveGroupCall({required String callSessionId});

  Future<ActiveCallStateResult> syncState({required String callSessionId});

  Stream<CallSocketEvent> watchSocketEvents();

  /// 分页查询通话记录
  Future<List<CallRecord>> getCallRecords({
    int? callType,
    DateTime? startTime,
    DateTime? endTime,
    String? chatId,
    int pageNo = 1,
    int pageSize = 20,
  });

  /// 发送媒体状态更新（摄像头/麦克风开关状态）
  ///
  /// 用于通知对端当前用户的媒体状态变化，实现全链路状态同步
  Future<void> sendMediaStateUpdate({
    required String callSessionId,
    required bool cameraEnabled,
    required bool microphoneEnabled,
  });
}
