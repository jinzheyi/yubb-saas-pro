class GroupConversationSettings {
  const GroupConversationSettings({
    required this.chatId,
    required this.pinned,
    required this.noDisturb,
  });

  final String chatId;
  final bool pinned;
  final bool noDisturb;
}
