enum CallEntryMode { outgoing, incoming, restore }

/// 通话页返回给入口流程的、只用于页面编排的结果。
enum CallPageResult { groupMemberBusy }

enum CallType { audio, video }

class CallLaunchArgs {
  const CallLaunchArgs({
    required this.callSessionId,
    required this.chatId,
    required this.callType,
    required this.entryMode,
    this.inviteId,
    this.fromUserId,
    this.toUserId,
    this.title,
    this.conversationTitle,
    this.callerName,
    this.callerAvatarUrl,
    this.peerAvatarUrl,
    this.callerId,
    this.isGroupOwner,
    this.isGroupCall = false,
    this.groupId,
    this.inviteeIds = const [],
    this.acceptedFromNative = false,
  });

  final String callSessionId;
  final String chatId;
  final CallType callType;
  final CallEntryMode entryMode;
  final String? inviteId;
  final String? fromUserId;
  final String? toUserId;
  final String? title;
  final String? conversationTitle;
  final String? callerName;
  final String? callerAvatarUrl;
  final String? peerAvatarUrl;
  final String? callerId;
  final bool? isGroupOwner;

  // 群组通话相关
  final bool isGroupCall;
  final String? groupId;
  final List<String> inviteeIds;
  final bool acceptedFromNative;

  const CallLaunchArgs.empty()
    : callSessionId = '',
      chatId = '',
      callType = CallType.audio,
      entryMode = CallEntryMode.outgoing,
      inviteId = null,
      fromUserId = null,
      toUserId = null,
      title = null,
      conversationTitle = null,
      callerName = null,
      callerAvatarUrl = null,
      peerAvatarUrl = null,
      callerId = null,
      isGroupOwner = null,
      isGroupCall = false,
      groupId = null,
      inviteeIds = const [],
      acceptedFromNative = false;

  factory CallLaunchArgs.outgoing({
    required String callSessionId,
    required String chatId,
    required CallType callType,
    String? toUserId,
    String? title,
    String? conversationTitle,
    String? peerName,
    String? peerAvatarUrl,
    String? callerId,
    bool isGroupCall = false,
    String? groupId,
    List<String> inviteeIds = const [],
  }) {
    return CallLaunchArgs(
      callSessionId: callSessionId,
      chatId: chatId,
      callType: callType,
      entryMode: CallEntryMode.outgoing,
      toUserId: toUserId,
      title: title,
      conversationTitle: conversationTitle ?? peerName ?? title,
      peerAvatarUrl: peerAvatarUrl,
      callerId: callerId,
      isGroupOwner: isGroupCall ? true : null,
      isGroupCall: isGroupCall,
      groupId: groupId,
      inviteeIds: inviteeIds,
    );
  }

  CallLaunchArgs copyWith({
    String? callSessionId,
    String? chatId,
    CallType? callType,
    CallEntryMode? entryMode,
    String? inviteId,
    String? fromUserId,
    String? toUserId,
    String? title,
    String? conversationTitle,
    String? callerName,
    String? callerAvatarUrl,
    String? peerAvatarUrl,
    String? callerId,
    bool? isGroupOwner,
    bool? isGroupCall,
    String? groupId,
    List<String>? inviteeIds,
    bool? acceptedFromNative,
  }) {
    return CallLaunchArgs(
      callSessionId: callSessionId ?? this.callSessionId,
      chatId: chatId ?? this.chatId,
      callType: callType ?? this.callType,
      entryMode: entryMode ?? this.entryMode,
      inviteId: inviteId ?? this.inviteId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      title: title ?? this.title,
      conversationTitle: conversationTitle ?? this.conversationTitle,
      callerName: callerName ?? this.callerName,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      callerId: callerId ?? this.callerId,
      isGroupOwner: isGroupOwner ?? this.isGroupOwner,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      groupId: groupId ?? this.groupId,
      inviteeIds: inviteeIds ?? this.inviteeIds,
      acceptedFromNative: acceptedFromNative ?? this.acceptedFromNative,
    );
  }
}
