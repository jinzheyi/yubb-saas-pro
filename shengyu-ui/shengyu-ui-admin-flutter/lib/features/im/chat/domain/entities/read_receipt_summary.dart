class ReadReceiptSummary {
  const ReadReceiptSummary({
    required this.messageId,
    required this.chatId,
    required this.sequence,
    required this.readCount,
    required this.unreadCount,
    required this.totalCount,
  });

  final String messageId;
  final String chatId;
  final String sequence;
  final int readCount;
  final int unreadCount;
  final int totalCount;
}
