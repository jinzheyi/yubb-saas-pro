import 'dart:convert';

import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class ChatHistoryItemDto {
  static const String _systemSenderId = '0';
  static const String _systemSenderName = 'System';

  const ChatHistoryItemDto({
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
    this.extraRaw,
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
  final String? extraRaw;

  factory ChatHistoryItemDto.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? json['messageType']?.toString();
    final extra = _readExtra(json['extra']);
    final systemEventKey = _parseSystemEventKey(extra);
    final isSystemTip = systemEventKey != null;
    final resolvedType = isSystemTip
        ? MessageType.system
        : _parseMessageType(rawType);
    
    String extraString = '';
    final rawExtra = json['extra'];
    if (rawExtra is String) {
      extraString = rawExtra;
    } else if (rawExtra != null) {
      extraString = jsonEncode(rawExtra);
    }
    
    return ChatHistoryItemDto(
      messageId: '${json['messageId'] ?? json['id'] ?? ''}',
      chatId: '${json['chatId'] ?? json['conversationId'] ?? ''}',
      sequence: '${json['sequence'] ?? json['sortKey'] ?? ''}',
      senderId:
          isSystemTip
              ? _systemSenderId
              : '${json['senderId'] ?? json['fromUserId'] ?? ''}',
      senderName:
          isSystemTip
              ? _systemSenderName
              : '${json['senderName'] ?? json['senderNickname'] ?? json['nickname'] ?? json['userName'] ?? ''}',
      senderAvatar:
          isSystemTip
              ? ''
              : '${json['senderAvatar'] ?? json['avatar'] ?? json['avatarUrl'] ?? ''}',
      content: isSystemTip ? (_parseSystemTipContent(extra) ?? '') : _buildContent(json, rawType),
      messageType: resolvedType,
      sentAt:
          DateTime.tryParse(json['sendTime']?.toString() ?? '') ??
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.tryParse(json['createTime']?.toString() ?? '') ??
          _millisToDateTime(json['sendTime']) ??
          _millisToDateTime(json['timestamp']) ??
          _millisToDateTime(json['createTime']),
      systemEventKey: systemEventKey,
      extraRaw: extraString,
    );
  }

  static Map<String, dynamic> _readExtra(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.isNotEmpty && raw.startsWith('{')) {
      try {
        return Map<String, dynamic>.from(
          jsonDecode(raw) as Map<dynamic, dynamic>,
        );
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  static String? _parseSystemEventKey(Map<String, dynamic> extra) {
    final i18n = extra['i18n'];
    if (i18n is Map) {
      final eventKey = i18n['eventKey']?.toString().trim() ?? '';
      if (eventKey.isNotEmpty && eventKey.startsWith('im.system.')) {
        return eventKey;
      }
    }
    return null;
  }

  static String? _parseSystemTipContent(Map<String, dynamic> extra) {
    final i18n = extra['i18n'];
    if (i18n is! Map) {
      return null;
    }
    final rendered =
        i18n['text']?.toString().trim() ??
        i18n['content']?.toString().trim() ??
        i18n['message']?.toString().trim() ??
        '';
    if (rendered.isEmpty) {
      return null;
    }
    return rendered;
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
      case '101':
        return MessageType.image;
      case 'voice':
      case 'VOICE':
      case '3':
      case '102':
        return MessageType.voice;
      case 'video':
      case 'VIDEO':
      case '4':
      case '103':
        return MessageType.video;
      case 'file':
      case 'FILE':
      case '5':
      case '104':
        return MessageType.file;
      case 'location':
      case 'LOCATION':
      case '6':
      case '105':
        return MessageType.location;
      case 'emoji':
      case 'EMOJI':
      case '7':
        return MessageType.emoji;
      case 'sticker':
      case 'STICKER':
      case '8':
        return MessageType.sticker;
      case 'custom':
      case 'CUSTOM':
      case '9':
      case '106':
        return MessageType.custom;
      case 'contact_card':
      case 'CONTACT_CARD':
        return MessageType.contactCard;
      case 'system':
      case 'SYSTEM':
        return MessageType.system;
      case 'quoteReply':
      case 'QUOTE_REPLY':
      case '205':
        return MessageType.text;
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
