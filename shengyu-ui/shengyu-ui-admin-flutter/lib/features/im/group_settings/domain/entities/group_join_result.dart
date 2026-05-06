class GroupJoinResult {
  const GroupJoinResult({
    required this.resultType,
    required this.groupId,
    required this.chatId,
    required this.message,
  });

  final int resultType;
  final String groupId;
  final String chatId;
  final String message;
}
