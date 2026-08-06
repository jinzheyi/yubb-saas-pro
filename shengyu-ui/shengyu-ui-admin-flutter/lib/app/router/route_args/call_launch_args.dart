enum CallEntryMode { outgoing, incoming, restore }

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
    this.isGroupCall = false,
    this.groupId,
    this.inviteeIds = const [],
  });

  final String callSessionId;
  final String chatId;
  final CallType callType;
  final CallEntryMode entryMode;
  final String? inviteId;
  final String? fromUserId;
  final String? toUserId;
  final String? title;
  
  // 群组通话相关
  final bool isGroupCall;
  final String? groupId;
  final List<String> inviteeIds;

  const CallLaunchArgs.empty()
    : callSessionId = '',
      chatId = '',
      callType = CallType.audio,
      entryMode = CallEntryMode.outgoing,
      inviteId = null,
      fromUserId = null,
      toUserId = null,
      title = null,
      isGroupCall = false,
      groupId = null,
      inviteeIds = const [];

  factory CallLaunchArgs.outgoing({
    required String callSessionId,
    required String chatId,
    required CallType callType,
    String? toUserId,
    String? title,
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
    bool? isGroupCall,
    String? groupId,
    List<String>? inviteeIds,
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
      isGroupCall: isGroupCall ?? this.isGroupCall,
      groupId: groupId ?? this.groupId,
      inviteeIds: inviteeIds ?? this.inviteeIds,
    );
  }
}
