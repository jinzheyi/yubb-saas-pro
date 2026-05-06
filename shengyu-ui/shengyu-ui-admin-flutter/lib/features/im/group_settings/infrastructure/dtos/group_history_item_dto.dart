import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class GroupHistoryItemDto {
  const GroupHistoryItemDto({
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

  factory GroupHistoryItemDto.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? json['messageType']?.toString();
    return GroupHistoryItemDto(
      messageId: '${json['messageId'] ?? json['id'] ?? ''}',
      chatId: '${json['chatId'] ?? ''}',
      sequence: '${json['sequence'] ?? ''}',
      senderName: '${json['senderName'] ?? json['senderNickname'] ?? ''}',
      content: _buildContent(json, rawType),
      messageType: _parseMessageType(rawType),
      sentAt:
          DateTime.tryParse(json['sendTime']?.toString() ?? '') ??
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          _millisToDateTime(json['sendTime']) ??
          _millisToDateTime(json['timestamp']),
    );
  }

  static String _buildContent(Map<String, dynamic> json, String? rawType) {
    final content = json['content']?.toString() ?? '';
    if (content.isNotEmpty) {
      return content;
    }
    return '';
  }

  static MessageType _parseMessageType(String? raw) {
    switch (raw) {
      case 'image':
      case 'IMAGE':
      case '2':
        return MessageType.image;
      case 'file':
      case 'FILE':
      case '4':
      case '5':
        return MessageType.file;
      case 'location':
      case 'LOCATION':
      case '6':
      case '105':
        return MessageType.location;
      case 'custom':
      case 'CUSTOM':
      case 'contact_card':
      case 'CONTACT_CARD':
      case '9':
        return MessageType.contactCard;
      case 'system':
      case 'SYSTEM':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static DateTime? _millisToDateTime(Object? raw) {
    final value = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    if (value == null || value <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
}
