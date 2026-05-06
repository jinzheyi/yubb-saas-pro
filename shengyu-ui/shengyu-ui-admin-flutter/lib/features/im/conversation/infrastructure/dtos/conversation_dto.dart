import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class ConversationDto {
  const ConversationDto({
    required this.chatId,
    required this.title,
    required this.conversationType,
    required this.conversationVersion,
    required this.targetId,
    required this.targetAvatar,
    required this.lastMessageId,
    required this.lastMessageSequence,
    required this.lastReadSequence,
    required this.lastMessagePreview,
    required this.lastMessageType,
    required this.lastMessageStatus,
    required this.lastMessageHasAtMe,
    required this.groupMemberCount,
    required this.updatedAt,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    required this.online,
    required this.onlineDeviceTypes,
    required this.lastActiveTime,
  });

  final String chatId;
  final String title;
  final ConversationType conversationType;
  final String conversationVersion;
  final String targetId;
  final String targetAvatar;
  final String lastMessageId;
  final String lastMessageSequence;
  final String lastReadSequence;
  final String lastMessagePreview;
  final MessageType lastMessageType;
  final MessageStatus lastMessageStatus;
  final bool lastMessageHasAtMe;
  final int groupMemberCount;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool online;
  final List<int> onlineDeviceTypes;
  final int lastActiveTime;

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      chatId:
          json['chatId']?.toString() ??
          json['conversationId']?.toString() ??
          json['id']?.toString() ??
          '',
      title:
          json['title']?.toString() ??
          json['targetName']?.toString() ??
          json['chatName']?.toString() ??
          json['name']?.toString() ??
          '',
      conversationVersion:
          json['conversationVersion']?.toString() ??
          json['version']?.toString() ??
          '',
      targetId:
          json['targetId']?.toString() ??
          json['conversationTargetId']?.toString() ??
          json['receiveId']?.toString() ??
          json['groupId']?.toString() ??
          json['toUserId']?.toString() ??
          '',
      targetAvatar:
          json['targetAvatar']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['avatar']?.toString() ??
          '',
      lastMessageId:
          json['lastMessageId']?.toString() ??
          json['messageId']?.toString() ??
          '',
      lastMessageSequence:
          json['lastMessageSequence']?.toString() ??
          json['sequence']?.toString() ??
          json['sortKey']?.toString() ??
          '',
      lastReadSequence:
          json['lastReadSequence']?.toString() ??
          json['readSequence']?.toString() ??
          '',
      conversationType: _parseConversationType(
        json['conversationType']?.toString(),
      ),
      lastMessagePreview:
          json['lastMessagePreview']?.toString() ??
          json['lastMessageContent']?.toString() ??
          json['previewText']?.toString() ??
          json['content']?.toString() ??
          '',
      lastMessageType: _parseMessageType(json['lastMessageType']?.toString()),
      lastMessageStatus: _parseMessageStatus(
        json['lastMessageStatus']?.toString(),
      ),
      lastMessageHasAtMe:
          _parseBool(json['lastMessageHasAtMe']) ||
          _parseBool(json['atMe']) ||
          _parseBool(json['mentionedMe']),
      groupMemberCount:
          _parseInt(json['groupMemberCount']) ??
          _parseInt(json['memberCount']) ??
          _parseInt(json['memberNum']) ??
          0,
      updatedAt:
          _parseDateTime(json['updatedAt']) ??
          _parseDateTime(json['lastMessageTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: _parseInt(json['unreadCount']) ?? 0,
      isPinned: _parseBool(json['isPinned']) || _parseBool(json['topStatus']),
      isMuted:
          _parseBool(json['isMuted']) ||
          _parseBool(json['noDisturb']) ||
          _parseBool(json['muteStatus']),
      online: _parseBool(json['online']),
      onlineDeviceTypes: _parseIntList(json['onlineDeviceTypes']),
      lastActiveTime: _parseInt(json['lastActiveTime']) ?? 0,
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

  static MessageType _parseMessageType(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'image':
      case '2':
        return MessageType.image;
      case 'file':
      case '4':
      case '5':
        return MessageType.file;
      case 'location':
      case '6':
      case '105':
        return MessageType.location;
      case 'custom':
      case 'contact_card':
      case '9':
        return MessageType.contactCard;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'pending':
      case 'sending':
        return MessageStatus.sending;
      case 'success':
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'recalled':
      case '6':
        return MessageStatus.recalled;
      case 'failed':
      case 'error':
        return MessageStatus.failed;
      default:
        return MessageStatus.read;
    }
  }

  static int? _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  static List<int> _parseIntList(Object? raw) {
    if (raw is List) {
      return raw.map(_parseInt).whereType<int>().toList(growable: false);
    }
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return const <int>[];
    }
    return text
        .split(',')
        .map((item) => _parseInt(item))
        .whereType<int>()
        .toList(growable: false);
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    final text = raw?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1';
  }

  static DateTime? _parseDateTime(Object? raw) {
    final millis = _parseInt(raw);
    if (millis != null && millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
    return DateTime.tryParse(normalized);
  }
}
