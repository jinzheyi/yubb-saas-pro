import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_record_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_session_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_signal_event_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class CallDtoMapper {
  const CallDtoMapper();

  CallInviteResult toInviteResult(CallSessionDto dto) {
    return CallInviteResult(
      callSessionId: dto.callSessionId,
      inviteId: dto.inviteId,
      chatId: dto.chatId,
      callType: callTypeFromServer(dto.callType),
      title: dto.title,
      callerProfile: _toParticipant(dto.callerProfile),
      calleeProfile: _toParticipant(dto.calleeProfile),
    );
  }

  ActiveCallStateResult toActiveStateResult(CallSessionDto dto) {
    return ActiveCallStateResult(
      pageStatus: _pageStatusFromServer(dto.status),
      elapsedSeconds: dto.elapsedSeconds ?? 0,
      callSessionId: dto.callSessionId,
      chatId: dto.chatId,
      callType: callTypeFromServer(dto.callType),
      title: dto.title,
      callerProfile: _toParticipant(dto.callerProfile),
      calleeProfile: _toParticipant(dto.calleeProfile),
      acceptedDeviceId: dto.acceptedDeviceId,
      roomBundle: _toRtcRoomBundle(dto.rtcRoom),
    );
  }

  CallSocketEvent toSocketEvent(CallSignalEventDto dto) {
    return CallSocketEvent(
      type: _eventTypeFromServer(dto.type),
      callSessionId: dto.callSessionId,
      payload: dto.payload,
    );
  }

  String callTypeToServer(CallType callType) {
    switch (callType) {
      case CallType.audio:
        return 'audio';
      case CallType.video:
        return 'video';
    }
  }

  CallType callTypeFromServer(String callType) {
    switch (callType) {
      case 'video':
        return CallType.video;
      case 'audio':
      default:
        return CallType.audio;
    }
  }

  CallPageStatus _pageStatusFromServer(String status) {
    switch (status) {
      case 'ringing':
        return CallPageStatus.ringing;
      case 'accepting':
        return CallPageStatus.accepting;
      case 'connected':
        return CallPageStatus.connected;
      case 'reconnecting':
        return CallPageStatus.reconnecting;
      case 'ended':
        return CallPageStatus.ended;
      case 'failed':
        return CallPageStatus.failed;
      default:
        return CallPageStatus.connecting;
    }
  }

  CallSocketEventType _eventTypeFromServer(String type) {
    // 关键修复：后端事件命名存在连字符和下划线两种风格混用
    // 例如：CallSignalProcessor 用 call.transfer_requested（下划线）
    //       ImCallServiceImpl 用 call.group-invite（连字符）
    // 统一将下划线转换为连字符后再匹配，兼容两种命名风格
    final normalized = type.replaceAll('_', '-');
    switch (normalized) {
      case 'call.invite':
        return CallSocketEventType.invite;
      case 'call.accepted':
        return CallSocketEventType.accepted;
      case 'call.rejected':
        return CallSocketEventType.rejected;
      case 'call.busy':
        return CallSocketEventType.busy;
      case 'call.cancelled':
        return CallSocketEventType.cancelled;
      case 'call.timeout':
        return CallSocketEventType.timeout;
      case 'call.ended':
        return CallSocketEventType.ended;
      case 'call.device-terminated':
      case 'call.device-kicked':  // 关键修复：兼容后端 MemberChangeService 的 call.device_kicked
        return CallSocketEventType.deviceTerminated;
      case 'call.media-token-issued':
        return CallSocketEventType.mediaTokenIssued;
      case 'call.state-sync':
        return CallSocketEventType.stateSync;
      case 'call.record':
        return CallSocketEventType.callRecord;
      case 'call.missed':
        return CallSocketEventType.missed;
      case 'call.transfer-requested':
        return CallSocketEventType.transferRequested;
      case 'call.transfer-accepted':
        return CallSocketEventType.transferAccepted;
      case 'call.transfer-rejected':
        return CallSocketEventType.transferRejected;
      case 'call.transfer-cancelled':
        return CallSocketEventType.transferCancelled;
      case 'call.group-invite':
        return CallSocketEventType.groupInvite;
      case 'call.group-join':
        return CallSocketEventType.groupJoin;
      case 'call.group-leave':
        return CallSocketEventType.groupLeave;
      case 'call.group-ended':  // 关键修复：兼容后端 GroupCallService 的 call.group_ended
        return CallSocketEventType.groupLeave;  // 群组结束视为离开事件处理
      case 'call.group-participant-update':
        return CallSocketEventType.groupParticipantUpdate;
      case 'call.media-state-update':
        return CallSocketEventType.mediaStateUpdate;
      case 'call.media-control':  // 关键修复：兼容后端 CallSignalProcessor 的 call.media_control
        return CallSocketEventType.mediaStateUpdate;
      case 'call.recording-started':  // 关键修复：兼容后端 CallRecordingService
      case 'call.recording-stopped':
        return CallSocketEventType.mediaStateUpdate;  // 录制状态变更视为媒体状态更新
      default:
        // 未识别的事件类型，返回 stateSync 作为兜底
        return CallSocketEventType.stateSync;
    }
  }

  CallParticipantProfile? _toParticipant(CallParticipantDto? dto) {
    if (dto == null || dto.userId.isEmpty) {
      return null;
    }
    return CallParticipantProfile(
      userId: dto.userId,
      displayName: dto.displayName,
      avatarUrl: dto.avatarUrl,
    );
  }

  RtcRoomBundle? _toRtcRoomBundle(CallRtcRoomDto? dto) {
    if (dto == null || dto.roomId.isEmpty) {
      return null;
    }
    return RtcRoomBundle(
      callSessionId: dto.callSessionId,
      roomId: dto.roomId,
      publisherId: dto.publisherId,
      displayName: dto.displayName,
      janusUrl: dto.janusUrl,
      turnUrls: dto.turnUrls,
      turnUsername: dto.turnUsername,
      turnCredential: dto.turnCredential,
      token: dto.token,
    );
  }

  CallRecord toCallRecord(CallRecordDto dto) {
    return CallRecord(
      callId: dto.callId,
      chatId: dto.chatId,
      callType: dto.callType,
      status: dto.status,
      duration: dto.duration,
      callerId: dto.callerId,
      calleeId: dto.calleeId,
      callerName: dto.callerName,
      callerAvatar: dto.callerAvatar,
      calleeName: dto.calleeName,
      calleeAvatar: dto.calleeAvatar,
      startTime: dto.startTime,
      endTime: dto.endTime,
      isCaller: dto.isCaller,
      conversationType: dto.conversationType,
    );
  }

  /// 将通话记录 DTO 转换为聊天消息实体
  ///
  /// 用于在通话结束后，将通话记录作为消息插入聊天时间线
  /// 参考微信：1v1 通话以气泡显示，群通话以居中系统消息显示
  Message toCallRecordMessage(CallRecordDto dto, String currentUserId) {
    final isGroupCall = dto.conversationType == ConversationType.group;
    final isOutgoing = dto.callerId == currentUserId;

    return Message(
      messageId: 'call_record_${dto.callId}',
      chatId: dto.chatId,
      senderId: dto.callerId,
      senderName: dto.callerName ?? '',
      senderAvatar: dto.callerAvatar,
      type: MessageType.callRecord,
      status: MessageStatus.sent,
      content: '', // 通话记录无文本内容，由 CallRecordMessageBubble 渲染
      sentAt: dto.startTime,
      isOutgoing: isOutgoing,
      extra: MessageExtra(
        callId: dto.callId,
        callType: dto.callType,
        callStatus: dto.status,
        duration: dto.duration,
        callerId: dto.callerId,
        calleeId: dto.calleeId,
        initiateTime: dto.startTime.millisecondsSinceEpoch,
        isGroupCall: isGroupCall,
        inviteeNames: dto.inviteeNames,
      ),
    );
  }
}
