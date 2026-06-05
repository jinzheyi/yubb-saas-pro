class FavoriteItem {
  const FavoriteItem({
    required this.favoriteId,
    required this.messageId,
    required this.messageType,
    required this.messagePreview,
    required this.messageContent,
    required this.messageExtra,
    required this.messageSnapshot,
    required this.sendTime,
    required this.favoriteTime,
    this.senderId = '',
    this.senderNickname = '',
    this.senderAvatar = '',
    this.isSelf = false,
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

  // 发送者信息（与聊天记录接口保持一致）
  final String senderId;
  final String senderNickname;
  final String senderAvatar;
  final bool isSelf;
}
