import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class GroupHistoryItem {
  const GroupHistoryItem({
    required this.messageId,
    required this.chatId,
    required this.sequence,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.sentAt,
  });

  final String messageId;
  final String chatId;
  final String sequence;
  final String senderName;
  final String content;
  final MessageType messageType;
  final DateTime? sentAt;
}
