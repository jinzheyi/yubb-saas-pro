class ReadReceiptSummaryDto {
  const ReadReceiptSummaryDto({
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

  factory ReadReceiptSummaryDto.fromJson(Map<String, dynamic> json) {
    return ReadReceiptSummaryDto(
      messageId: json['messageId']?.toString() ?? json['id']?.toString() ?? '',
      chatId:
          json['chatId']?.toString() ??
          json['conversationId']?.toString() ??
          '',
      sequence:
          json['sequence']?.toString() ?? json['sortKey']?.toString() ?? '',
      readCount: _toInt(json['readCount']),
      unreadCount: _toInt(json['unreadCount']),
      totalCount: _toInt(json['totalCount']),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
