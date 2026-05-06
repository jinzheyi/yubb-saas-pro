class SocketHeader {
  const SocketHeader({
    required this.messageId,
    required this.messageType,
    this.chatId,
    this.senderId,
    this.receiverId,
    this.groupId,
    this.tenantId,
    this.timestamp,
    this.sequence,
    this.extra,
  });

  final String messageId;
  final int messageType;
  final String? chatId;
  final String? senderId;
  final String? receiverId;
  final String? groupId;
  final String? tenantId;
  final String? timestamp;
  final String? sequence;
  final String? extra;

  factory SocketHeader.fromJson(Map<String, dynamic> json) {
    return SocketHeader(
      messageId: json['messageId']?.toString() ?? '',
      messageType: (json['messageType'] as num?)?.toInt() ?? 0,
      chatId: json['chatId']?.toString(),
      senderId: json['senderId']?.toString(),
      receiverId: json['receiverId']?.toString(),
      groupId: json['groupId']?.toString(),
      tenantId: json['tenantId']?.toString(),
      timestamp: json['timestamp']?.toString(),
      sequence: json['sequence']?.toString(),
      extra: json['extra']?.toString(),
    );
  }
}
