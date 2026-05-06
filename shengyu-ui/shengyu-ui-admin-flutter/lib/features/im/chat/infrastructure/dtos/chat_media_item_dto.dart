import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class ChatMediaItemDto {
  const ChatMediaItemDto({
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

  factory ChatMediaItemDto.fromJson(Map<String, dynamic> json) {
    final rawType =
        json['mediaType']?.toString() ??
        json['type']?.toString() ??
        json['messageType']?.toString();
    final fileUrl =
        '${json['fileUrl'] ?? json['url'] ?? json['content'] ?? ''}';
    final thumbnailUrl =
        '${json['thumbnailUrl'] ?? json['coverUrl'] ?? json['thumbUrl'] ?? fileUrl}';
    return ChatMediaItemDto(
      messageId: '${json['messageId'] ?? json['id'] ?? ''}',
      chatId: '${json['chatId'] ?? json['conversationId'] ?? ''}',
      fileId: '${json['fileId'] ?? json['id'] ?? json['attachmentId'] ?? ''}',
      fileName:
          '${json['fileName'] ?? json['name'] ?? json['originName'] ?? ''}',
      fileSize: _toInt(json['fileSize']) != 0
          ? _toInt(json['fileSize'])
          : _toInt(json['size']),
      fileUrl: fileUrl,
      thumbnailUrl: thumbnailUrl,
      senderName:
          '${json['senderNickname'] ?? json['senderName'] ?? json['nickname'] ?? json['userName'] ?? ''}',
      sentAt:
          DateTime.tryParse(json['sendTime']?.toString() ?? '') ??
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.tryParse(json['createTime']?.toString() ?? '') ??
          _millisToDateTime(json['sendTime']) ??
          _millisToDateTime(json['timestamp']) ??
          _millisToDateTime(json['createTime']),
      messageType: _parseMessageType(rawType),
      mimeType:
          '${json['mimeType'] ?? json['fileType'] ?? json['contentType'] ?? ''}',
    );
  }

  static MessageType _parseMessageType(String? raw) {
    switch (raw) {
      case 'image':
      case 'IMAGE':
      case '2':
        return MessageType.image;
      case 'video':
      case 'VIDEO':
      case '3':
      case '6':
        return MessageType.file;
      case 'file':
      case 'FILE':
      case '4':
      case '5':
        return MessageType.file;
      default:
        return MessageType.file;
    }
  }

  static DateTime? _millisToDateTime(Object? raw) {
    final value = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    if (value == null || value <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
