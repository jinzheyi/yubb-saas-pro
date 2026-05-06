class FavoriteDetailDto {
  const FavoriteDetailDto({
    required this.favoriteId,
    required this.messageType,
    required this.messagePreview,
    required this.messageContent,
    required this.messageExtra,
    required this.messageSnapshot,
    required this.sendTime,
    required this.favoriteTime,
  });

  final String favoriteId;
  final int messageType;
  final String messagePreview;
  final String messageContent;
  final String messageExtra;
  final String messageSnapshot;
  final String sendTime;
  final String favoriteTime;

  factory FavoriteDetailDto.fromJson(Map<String, dynamic> json) {
    return FavoriteDetailDto(
      favoriteId:
          json['favoriteId']?.toString() ?? json['id']?.toString() ?? '0',
      messageType: (json['messageType'] as num?)?.toInt() ?? 0,
      messagePreview: json['messagePreview']?.toString() ?? '',
      messageContent: json['messageContent']?.toString() ?? '',
      messageExtra: json['messageExtra']?.toString() ?? '',
      messageSnapshot: json['messageSnapshot']?.toString() ?? '',
      sendTime: json['sendTime']?.toString() ?? '',
      favoriteTime: json['favoriteTime']?.toString() ?? '',
    );
  }
}
