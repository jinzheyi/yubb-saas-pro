import 'dart:convert';

import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
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
    required this.avatarText,
    required this.avatarBg,
    required this.lastMessageId,
    required this.lastMessageSequence,
    required this.lastReadSequence,
    required this.lastMessagePreview,
    required this.lastMessageType,
    required this.lastMessageSenderName,
    required this.lastMessageIsSelf,
    required this.lastMessageSenderId,
    required this.lastMessageCustomType,
    required this.lastMessageFileName,
    required this.lastMessageSystemEventKey,
    required this.lastMessageSystemEventParams,
    required this.lastMessageStatus,
    required this.lastMessageHasAtMe,
    required this.groupMemberCount,
    required this.groupMemberAvatars,
    required this.groupMemberItems,
    required this.updatedAt,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    required this.deletedByUser,
    required this.online,
    required this.onlineDeviceTypes,
    required this.lastActiveTime,
    required this.groupMemberStatus,
  });

  final String chatId;
  final String title;
  final ConversationType conversationType;
  final String conversationVersion;
  final String targetId;
  final String targetAvatar;
  final String avatarText;
  final String avatarBg;
  final String lastMessageId;
  final String lastMessageSequence;
  final String lastReadSequence;
  final String lastMessagePreview;
  final MessageType lastMessageType;
  final String lastMessageSenderName;
  final bool lastMessageIsSelf;
  final String lastMessageSenderId;
  final String lastMessageCustomType;
  final String lastMessageFileName;
  final String lastMessageSystemEventKey;
  final Map<String, String> lastMessageSystemEventParams;
  final MessageStatus lastMessageStatus;
  final bool lastMessageHasAtMe;
  final int groupMemberCount;
  final List<String> groupMemberAvatars;
  final List<GroupMemberItem> groupMemberItems;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool deletedByUser;
  final bool online;
  final List<int> onlineDeviceTypes;
  final int lastActiveTime;
  final int? groupMemberStatus;

  factory ConversationDto.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['lastMessageSenderId']?.toString() ??
        json['senderId']?.toString() ??
        '';
    final parsedIsSelf =
        _parseBool(json['lastMessageIsSelf']) ||
        _parseBool(json['isSelf']) ||
        _parseBool(json['isOutgoing']) ||
        _parseBool(json['fromSelf']) ||
        _parseBool(json['selfSend']);
    // 当接口未返回 lastMessageIsSelf 时，通过 lastMessageSenderId 与当前登录用户ID对比推断
    final isSelf = parsedIsSelf ||
        (currentUserId != null && currentUserId.isNotEmpty && senderId.isNotEmpty && senderId != '0'
            ? currentUserId == senderId
            : false);
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
          json['userAvatar']?.toString() ??
          json['targetAvatar']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['avatar']?.toString() ??
          '',
      avatarText:
          json['avatarText']?.toString() ??
          json['avatarLabel']?.toString() ??
          '',
      avatarBg:
          json['avatarBg']?.toString() ??
          json['avatarBackground']?.toString() ??
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
      lastMessageType: _normalizeLastMessageType(
        _parseMessageType(json['lastMessageType']?.toString()),
        json['lastMessageContent']?.toString() ?? '',
        json['lastMessageCustomType']?.toString() ??
            json['customType']?.toString() ??
            '',
      ),
      lastMessageSenderName:
          json['lastMessageSenderName']?.toString() ??
          json['senderName']?.toString() ??
          json['senderNickname']?.toString() ??
          json['nickname']?.toString() ??
          json['userName']?.toString() ??
          '',
      lastMessageIsSelf: isSelf,
      lastMessageSenderId: senderId,
      lastMessageCustomType:
          json['lastMessageCustomType']?.toString() ??
          json['customType']?.toString() ??
          '',
      lastMessageFileName:
          json['lastMessageFileName']?.toString() ??
          json['fileName']?.toString() ??
          '',
      lastMessageSystemEventKey:
          json['lastMessageSystemEventKey']?.toString() ??
          json['systemEventKey']?.toString() ??
          '',
      lastMessageSystemEventParams:
          _parseSystemEventParams(json['lastMessageSystemEventParams']) ??
          _parseSystemEventParams(json['systemEventParams']) ??
          const <String, String>{},
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
      groupMemberAvatars: _parseStringList(json['groupMemberAvatars']),
      groupMemberItems: _parseGroupMemberItems(json['groupMemberItems']),
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
      deletedByUser: _parseBool(json['deletedByUser']),
      online: _parseBool(json['online']),
      onlineDeviceTypes: _parseIntList(json['onlineDeviceTypes']),
      lastActiveTime: _parseInt(json['lastActiveTime']) ?? 0,
      groupMemberStatus: _parseInt(json['groupMemberStatus']),
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
      case 'voice':
      case '3':
        return MessageType.voice;
      case 'video':
      case '4':
        return MessageType.video;
      case 'file':
      case '5':
        return MessageType.file;
      case 'location':
      case '6':
      case '105':
        return MessageType.location;
      case 'emoji':
      case '7':
        return MessageType.emoji;
      case 'sticker':
      case '8':
        return MessageType.sticker;
      case 'custom':
        return MessageType.custom;
      case '9':
      case '106':
        return MessageType.contactCard;
      case 'contact_card':
      case 'contactcard':
      case 'business_card':
        return MessageType.contactCard;
      case 'system':
      case '10':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// 根据 lastMessageContent 和 customType 将 custom 类型规范化为具体类型
  /// 例如：lastMessageType=9 (custom) + content 含 CONTACT_CARD → contactCard
  static MessageType _normalizeLastMessageType(
    MessageType type,
    String content,
    String customType,
  ) {
    if (type != MessageType.custom) {
      return type;
    }
    final normalizedCustom = customType.trim().toUpperCase();
    if (normalizedCustom == 'CONTACT_CARD') {
      return MessageType.contactCard;
    }
    if (normalizedCustom == 'STICKER') {
      return MessageType.sticker;
    }
    // 尝试从 content JSON 中解析类型
    final trimmed = content.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final map = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final contentType =
              map['type']?.toString().trim().toUpperCase() ?? '';
          if (contentType == 'CONTACT_CARD') {
            return MessageType.contactCard;
          }
          if (contentType == 'STICKER') {
            return MessageType.sticker;
          }
          if (map['userId'] != null &&
              (map['displayName'] != null || map['deptName'] != null)) {
            return MessageType.contactCard;
          }
        }
      } catch (_) {
        // 解析失败，保持 custom
      }
    }
    return MessageType.custom;
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

  static List<String> _parseStringList(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static List<GroupMemberItem> _parseGroupMemberItems(Object? raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) {
        return GroupMemberItem(
          userId: e['userId']?.toString(),
          name: e['name']?.toString(),
          avatar: e['avatar']?.toString(),
        );
      }).toList();
    }
    return const [];
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
    final numeric = _parseInt(raw);
    if (numeric != null && numeric > 0) {
      final millis = numeric < 100000000000 ? numeric * 1000 : numeric;
      if (millis >= 946684800000) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
    return DateTime.tryParse(normalized);
  }

  static Map<String, String>? _parseSystemEventParams(Object? raw) {
    if (raw is Map) {
      final result = <String, String>{};
      raw.forEach((key, value) {
        final k = key.toString();
        final v = value?.toString() ?? '';
        if (k.isNotEmpty) {
          result[k] = v;
        }
      });
      return result.isEmpty ? null : result;
    }
    return null;
  }
}
