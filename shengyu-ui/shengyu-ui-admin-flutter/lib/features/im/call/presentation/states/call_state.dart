import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';

enum CallPageStatus {
  initial,
  loading,
  ringing,
  accepting,
  connecting,
  connected,
  reconnecting,
  ending,
  ended,
  failed,
}

enum CallEndReason {
  none,
  cancelledByCaller,
  rejectedByCallee,
  busy,
  noAnswer,
  hangupByLocal,
  hangupByRemote,
  kickedByOtherDevice,
  networkTimeout,
  rtcError,
  permissionDenied,
}

/// 待处理来电信息（通话等待场景）
class PendingIncomingCall {
  const PendingIncomingCall({
    required this.callSessionId,
    required this.callType,
    required this.callerProfile,
    this.title,
    this.isGroupCall = false,
    this.groupId,
  });

  final String callSessionId;
  final CallType callType;
  final CallParticipantProfile callerProfile;
  final String? title;
  
  /// 关键修复：添加群组通话标识，确保切换通话时能正确导航到群组通话界面
  final bool isGroupCall;
  final String? groupId;
}

class CallState {
  const CallState({
    this.callSessionId = '',
    this.chatId = '',
    this.calleeId,
    this.callType,
    this.entryMode,
    this.title,
    this.pageStatus = CallPageStatus.initial,
    this.endReason = CallEndReason.none,
    this.isIncoming = false,
    this.isOutgoing = false,
    this.hasAccepted = false,
    this.hasConnected = false,
    this.elapsedSeconds = 0,
    this.callerProfile,
    this.calleeProfile,
    this.acceptedDeviceId,
    this.roomBundle,
    this.error,
    this.mediaState = const CallMediaState(),
    this.isGroupCall = false,
    this.groupId,
    this.participants = const [],
    this.inviteeIds = const [],
    this.speakingUserId,
    this.pendingIncomingCall,
  });

  final String callSessionId;
  final String chatId;
  final String? calleeId;
  final CallType? callType;
  final CallEntryMode? entryMode;
  final String? title;
  final CallPageStatus pageStatus;
  final CallEndReason endReason;
  final bool isIncoming;
  final bool isOutgoing;
  final bool hasAccepted;
  final bool hasConnected;
  final int elapsedSeconds;
  final CallParticipantProfile? callerProfile;
  final CallParticipantProfile? calleeProfile;
  final String? acceptedDeviceId;
  final RtcRoomBundle? roomBundle;
  final AppError? error;
  final CallMediaState mediaState;
  
  // 群组通话相关
  final bool isGroupCall;
  final String? groupId;
  final List<CallParticipantProfile> participants;
  final List<String> inviteeIds;
  
  // 说话者指示器（群组通话使用）
  final String? speakingUserId;

  // 通话等待：待处理来电
  final PendingIncomingCall? pendingIncomingCall;

  CallState copyWith({
    String? callSessionId,
    String? chatId,
    String? calleeId,
    CallType? callType,
    CallEntryMode? entryMode,
    String? title,
    CallPageStatus? pageStatus,
    CallEndReason? endReason,
    bool? isIncoming,
    bool? isOutgoing,
    bool? hasAccepted,
    bool? hasConnected,
    int? elapsedSeconds,
    CallParticipantProfile? callerProfile,
    CallParticipantProfile? calleeProfile,
    String? acceptedDeviceId,
    RtcRoomBundle? roomBundle,
    Object? error = _noChange,
    CallMediaState? mediaState,
    bool? isGroupCall,
    String? groupId,
    List<CallParticipantProfile>? participants,
    List<String>? inviteeIds,
    String? speakingUserId,
    PendingIncomingCall? pendingIncomingCall,
  }) {
    return CallState(
      callSessionId: callSessionId ?? this.callSessionId,
      chatId: chatId ?? this.chatId,
      calleeId: calleeId ?? this.calleeId,
      callType: callType ?? this.callType,
      entryMode: entryMode ?? this.entryMode,
      title: title ?? this.title,
      pageStatus: pageStatus ?? this.pageStatus,
      endReason: endReason ?? this.endReason,
      isIncoming: isIncoming ?? this.isIncoming,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      hasAccepted: hasAccepted ?? this.hasAccepted,
      hasConnected: hasConnected ?? this.hasConnected,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      callerProfile: callerProfile ?? this.callerProfile,
      calleeProfile: calleeProfile ?? this.calleeProfile,
      acceptedDeviceId: acceptedDeviceId ?? this.acceptedDeviceId,
      roomBundle: roomBundle ?? this.roomBundle,
      error: identical(error, _noChange) ? this.error : error as AppError?,
      mediaState: mediaState ?? this.mediaState,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      groupId: groupId ?? this.groupId,
      participants: participants ?? this.participants,
      inviteeIds: inviteeIds ?? this.inviteeIds,
      speakingUserId: speakingUserId ?? this.speakingUserId,
      pendingIncomingCall: pendingIncomingCall ?? this.pendingIncomingCall,
    );
  }
}

const Object _noChange = Object();
