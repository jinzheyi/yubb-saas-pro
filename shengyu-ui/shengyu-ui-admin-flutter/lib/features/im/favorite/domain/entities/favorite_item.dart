import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class FavoriteItem {
  const FavoriteItem({
    required this.favoriteId,
    required this.messageId,
    required this.chatId,
    required this.conversationType,
    required this.title,
    required this.summary,
    required this.senderName,
    required this.messageType,
    required this.status,
    required this.createdAt,
  });

  final String favoriteId;
  final String messageId;
  final String chatId;
  final ConversationType conversationType;
  final String title;
  final String summary;
  final String senderName;
  final String messageType;
  final String status;
  final DateTime createdAt;
}
