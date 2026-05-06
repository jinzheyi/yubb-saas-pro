import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class FavoriteItemDto {
  const FavoriteItemDto({
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

  factory FavoriteItemDto.fromJson(Map<String, dynamic> json) {
    return FavoriteItemDto(
      favoriteId:
          json['favoriteId']?.toString() ?? json['id']?.toString() ?? '',
      messageId:
          json['messageId']?.toString() ??
          json['sourceMessageId']?.toString() ??
          '',
      chatId:
          json['sourceChatId']?.toString() ?? json['chatId']?.toString() ?? '',
      conversationType: _parseConversationType(
        json['conversationType']?.toString() ??
            json['sourceConversationType']?.toString() ??
            json['chatType']?.toString(),
      ),
      title:
          json['title']?.toString() ??
          json['conversationName']?.toString() ??
          json['sourceChatName']?.toString() ??
          json['sourceConversationName']?.toString() ??
          json['chatName']?.toString() ??
          '',
      summary:
          json['summary']?.toString() ??
          json['contentSummary']?.toString() ??
          json['messageSummary']?.toString() ??
          json['previewText']?.toString() ??
          json['content']?.toString() ??
          '',
      senderName:
          json['senderName']?.toString() ??
          json['sourceSenderName']?.toString() ??
          json['senderNickname']?.toString() ??
          '',
      messageType:
          json['messageType']?.toString() ?? json['type']?.toString() ?? '',
      status:
          json['status']?.toString() ??
          json['messageStatus']?.toString() ??
          json['sourceMessageStatus']?.toString() ??
          '',
      createdAt: _parseCreatedAt(json),
    );
  }

  static ConversationType _parseConversationType(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'group':
      case '2':
        return ConversationType.group;
      case 'direct':
      case 'single':
      case 'private':
      case '1':
        return ConversationType.direct;
      default:
        return ConversationType.direct;
    }
  }

  static DateTime _parseCreatedAt(Map<String, dynamic> json) {
    final candidates = <Object?>[
      json['createdTime'],
      json['createTime'],
      json['createdAt'],
      json['favoriteTime'],
    ];
    for (final raw in candidates) {
      if (raw == null) {
        continue;
      }
      if (raw is num) {
        final value = raw.toInt();
        if (value > 0) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        continue;
      }
      final text = raw.toString().trim();
      if (text.isEmpty) {
        continue;
      }
      final millis = int.tryParse(text);
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      final normalized = text.contains(' ')
          ? text.replaceFirst(' ', 'T')
          : text;
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
