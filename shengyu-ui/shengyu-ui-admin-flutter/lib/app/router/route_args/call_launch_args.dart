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
  });

  final String callSessionId;
  final String chatId;
  final CallType callType;
  final CallEntryMode entryMode;
  final String? inviteId;
  final String? fromUserId;
  final String? toUserId;
  final String? title;

  const CallLaunchArgs.empty()
    : callSessionId = '',
      chatId = '',
      callType = CallType.audio,
      entryMode = CallEntryMode.outgoing,
      inviteId = null,
      fromUserId = null,
      toUserId = null,
      title = null;

  factory CallLaunchArgs.outgoing({
    required String callSessionId,
    required String chatId,
    required CallType callType,
    String? title,
  }) {
    return CallLaunchArgs(
      callSessionId: callSessionId,
      chatId: chatId,
      callType: callType,
      entryMode: CallEntryMode.outgoing,
      title: title,
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
    );
  }
}
