import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_session_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_signal_event_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

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
    switch (type) {
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
        return CallSocketEventType.deviceTerminated;
      case 'call.media-token-issued':
        return CallSocketEventType.mediaTokenIssued;
      case 'call.state-sync':
        return CallSocketEventType.stateSync;
      default:
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
}
