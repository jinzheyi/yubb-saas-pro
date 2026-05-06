class UploadScope {
  const UploadScope._({
    required this.kind,
    this.chatId,
    this.groupId,
    this.targetUserId,
    this.userId,
  });

  const UploadScope.directChat({
    required String chatId,
    required String targetUserId,
  }) : this._(
         kind: UploadScopeKind.directChat,
         chatId: chatId,
         targetUserId: targetUserId,
       );

  const UploadScope.groupChat({required String groupId, required String chatId})
    : this._(kind: UploadScopeKind.groupChat, groupId: groupId, chatId: chatId);

  const UploadScope.profile({required String userId})
    : this._(kind: UploadScopeKind.profile, userId: userId);

  const UploadScope.sticker({required String userId})
    : this._(kind: UploadScopeKind.sticker, userId: userId);

  final UploadScopeKind kind;
  final String? chatId;
  final String? groupId;
  final String? targetUserId;
  final String? userId;

  String requireChatId() {
    final value = chatId;
    if (value == null || value.isEmpty) {
      throw StateError('upload scope has no chatId');
    }
    return value;
  }

  String requireTargetUserId() {
    final value = targetUserId;
    if (value == null || value.isEmpty) {
      throw StateError('upload scope has no targetUserId');
    }
    return value;
  }
}

enum UploadScopeKind { directChat, groupChat, profile, sticker }
