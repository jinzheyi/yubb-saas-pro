import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class ChatMediaItem {
  const ChatMediaItem({
    required this.messageId,
    required this.chatId,
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.fileUrl,
    required this.thumbnailUrl,
    required this.senderName,
    required this.sentAt,
    required this.messageType,
    required this.mimeType,
  });

  final String messageId;
  final String chatId;
  final String fileId;
  final String fileName;
  final int fileSize;
  final String fileUrl;
  final String thumbnailUrl;
  final String senderName;
  final DateTime? sentAt;
  final MessageType messageType;
  final String mimeType;
}
