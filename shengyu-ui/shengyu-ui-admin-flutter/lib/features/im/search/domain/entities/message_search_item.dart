class MessageSearchItem {
  const MessageSearchItem({
    required this.id,
    required this.messageId,
    required this.chatId,
    required this.sequence,
    required this.conversationName,
    required this.senderName,
    required this.content,
    required this.snippet,
    required this.highlight,
    required this.messageType,
    required this.timestamp,
    required this.conversationType,
    required this.targetId,
    required this.groupId,
  });

  final String id;
  final String messageId;
  final String chatId;
  final String sequence;
  final String conversationName;
  final String senderName;
  final String content;
  final String snippet;
  final String highlight;
  final String messageType;
  final DateTime? timestamp;
  final int? conversationType;
  final String targetId;
  final String groupId;
}
