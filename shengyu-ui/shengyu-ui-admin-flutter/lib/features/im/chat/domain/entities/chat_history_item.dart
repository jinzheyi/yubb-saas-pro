import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class ChatHistoryItem {
  const ChatHistoryItem({
    required this.messageId,
    required this.chatId,
    required this.sequence,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.messageType,
    required this.sentAt,
    this.systemEventKey,
  });

  final String messageId;
  final String chatId;
  final String sequence;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final MessageType messageType;
  final DateTime? sentAt;
  final String? systemEventKey;
}
