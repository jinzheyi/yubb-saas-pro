class FavoriteItemDto {
  const FavoriteItemDto({
    required this.favoriteId,
    required this.messageId,
    required this.messageType,
    required this.messagePreview,
    required this.messageContent,
    required this.messageExtra,
    required this.messageSnapshot,
    required this.sendTime,
    required this.favoriteTime,
  });

  final String favoriteId;
  final String messageId;
  final int messageType;
  final String messagePreview;
  final String messageContent;
  final String messageExtra;
  final String messageSnapshot;
  final String sendTime;
  final String favoriteTime;

  factory FavoriteItemDto.fromJson(Map<String, dynamic> json) {
    return FavoriteItemDto(
      favoriteId:
          json['favoriteId']?.toString() ?? json['id']?.toString() ?? '',
      messageId:
          json['messageId']?.toString() ??
          json['sourceMessageId']?.toString() ??
          '',
      messageType: _parseMessageType(json),
      messagePreview:
          json['messagePreview']?.toString() ??
          json['previewText']?.toString() ??
          '',
      messageContent: json['messageContent']?.toString() ?? '',
      messageExtra: json['messageExtra']?.toString() ?? '',
      messageSnapshot: json['messageSnapshot']?.toString() ?? '',
      sendTime: json['sendTime']?.toString() ?? '',
      favoriteTime: json['favoriteTime']?.toString() ?? '',
    );
  }

  static int _parseMessageType(Map<String, dynamic> json) {
    final raw = json['messageType'] ?? json['type'];
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
