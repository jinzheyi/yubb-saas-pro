import 'dart:convert';

import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

// 预编译正则表达式，避免 DTO 解析循环内重复构造
final _quoteMsgIdPattern = RegExp(r'"quotedMessageId"\s*:\s*"?([^",}]*)"?');
final _quoteMsgIdPattern2 = RegExp(r'"quoteMessageId"\s*:\s*"?([^",}]*)"?');

class MessageDto {
  static const String _systemSenderId = '0';
  static const String _systemSenderName = 'System';

  const MessageDto({
    required this.messageId,
    required this.clientMessageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.status,
    required this.content,
    required this.sentAt,
    required this.isOutgoing,
    required this.sequence,
    this.revision,
    this.fileId,
    this.fileUrl,
    this.thumbFileId,
    this.thumbnailUrl,
    this.mimeType,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.width,
    this.height,
    this.duration,
    this.durationMs,
    this.voicePlayed,
    this.md5,
    this.stickerId,
    this.customType,
    this.contactUserId,
    this.contactDisplayName,
    this.contactDepartmentName,
    this.contactPostName,
    this.contactAvatar,
    this.locationName,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    this.locationProvider,
    this.locationPoiId,
    this.quoteInfo,
    this.forwardedFrom,
    this.atUserIds = const <String>[],
    this.mentions = const <MentionSegment>[],
    this.reeditContent,
    this.reeditDeadlineTs,
    this.systemEventKey,
    this.systemEventParams,
  });

  final String messageId;
  final String clientMessageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final MessageStatus status;
  final String content;
  final DateTime sentAt;
  final bool isOutgoing;
  final String sequence;
  final String? revision;
  final String? fileId;
  final String? fileUrl;
  final String? thumbFileId;
  final String? thumbnailUrl;
  final String? mimeType;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final int? width;
  final int? height;
  final int? duration;
  final int? durationMs;
  final bool? voicePlayed;
  final String? md5;
  final String? stickerId;
  final String? customType;
  final String? contactUserId;
  final String? contactDisplayName;
  final String? contactDepartmentName;
  final String? contactPostName;
  final String? contactAvatar;
  final String? locationName;
  final String? locationAddress;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationProvider;
  final String? locationPoiId;
  final QuoteInfo? quoteInfo;
  final String? forwardedFrom;
  final List<String> atUserIds;
  final List<MentionSegment> mentions;
  final String? reeditContent;
  final int? reeditDeadlineTs;
  final String? systemEventKey;
  final Map<String, String>? systemEventParams;

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    final extra = _readExtra(json['extra']);
    final contentMap = _readExtra(json['content']);
    final structuredFields = <String, dynamic>{...extra, ...contentMap};
    final quoteInfo = _parseQuoteInfo(json, extra, contentMap);
    final rawType =
        json['type']?.toString() ?? json['messageType']?.toString() ?? '';
    final type = _parseMessageType(rawType);
    final statusRaw =
        json['status']?.toString() ?? json['messageStatus']?.toString() ?? '';
    final status = _parseMessageStatus(statusRaw);
    final customType = _parseCustomType(contentMap, extra);
    final systemEventKey = _parseSystemEventKey(extra);
    final systemEventParams = _parseSystemEventParams(extra);
    final isRecalled =
        statusRaw == '6' || statusRaw.toLowerCase() == 'recalled';
    final isSystemTip = !isRecalled && systemEventKey != null;
    final resolvedType = isRecalled
        ? MessageType.system
        : (isSystemTip
              ? MessageType.system
              : _normalizeCustomType(type, customType));
    final resolvedSenderId =
        json['senderId']?.toString() ??
        json['fromUserId']?.toString() ??
        json['userId']?.toString() ??
        '';
    final resolvedSenderName =
        json['senderName']?.toString() ??
        json['senderNickname']?.toString() ??
        json['nickname']?.toString() ??
        json['userName']?.toString() ??
        '';
    final resolvedContent = isSystemTip
        ? (_parseSystemTipContent(extra) ??
              _parseContent(
                json['content'],
                contentMap,
                resolvedType,
                customType,
                isRecalled,
              ))
        : _parseContent(
            json['content'],
            contentMap,
            resolvedType,
            customType,
            isRecalled,
          );
    return MessageDto(
      messageId: json['messageId']?.toString() ?? json['id']?.toString() ?? '',
      clientMessageId:
          json['clientMessageId']?.toString() ??
          json['reqMessageId']?.toString() ??
          '',
      chatId:
          json['chatId']?.toString() ??
          json['conversationId']?.toString() ??
          '',
      senderId: isSystemTip ? _systemSenderId : resolvedSenderId,
      senderName: isSystemTip ? _systemSenderName : resolvedSenderName,
      senderAvatar: isSystemTip
          ? null
          : (json['senderAvatar']?.toString() ??
                json['avatarUrl']?.toString() ??
                json['avatar']?.toString()),
      type: resolvedType,
      status: status,
      content: resolvedContent,
      sentAt:
          _parseDateTime(
            json['createdAt'] ??
                json['createdTime'] ??
                json['sentAt'] ??
                json['sendTime'] ??
                json['timestamp'],
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isOutgoing: isSystemTip
          ? false
          : json['isOutgoing'] == true || json['isSelf'] == true,
      sequence:
          json['sequence']?.toString() ?? json['sortKey']?.toString() ?? '',
      revision: json['rev']?.toString(),
      fileId: _pickString(json, structuredFields, ['fileId']),
      fileUrl: _pickString(json, structuredFields, [
        'url',
        'fileUrl',
        'downloadUrl',
        'filePath',
      ]),
      thumbFileId: _pickString(json, structuredFields, ['thumbFileId']),
      thumbnailUrl: _pickString(json, structuredFields, [
        'thumbnailUrl',
        'coverUrl',
        'thumbUrl',
        'previewUrl',
        'poster',
      ]),
      mimeType: _pickString(json, structuredFields, [
        'mimeType',
        'contentType',
      ]),
      fileName: _pickString(json, structuredFields, [
        'fileName',
        'name',
        'originName',
      ]),
      fileType: _pickString(json, structuredFields, [
        'fileType',
        'mimeType',
        'contentType',
      ]),
      fileSize: _pickInt(json, structuredFields, ['size', 'fileSize']),
      width: _pickInt(json, structuredFields, ['width']),
      height: _pickInt(json, structuredFields, ['height']),
      duration: _pickDurationSeconds(structuredFields, contentMap),
      durationMs: _pickInt(json, structuredFields, ['durationMs']),
      voicePlayed: _pickBool(json, structuredFields, ['voicePlayed']),
      md5: _pickString(json, structuredFields, ['md5']),
      stickerId: _pickString(json, structuredFields, ['stickerId']),
      customType: customType,
      contactUserId: _pickString(json, structuredFields, [
        'userId',
        'contactUserId',
      ]),
      contactDisplayName: _pickString(json, structuredFields, [
        'displayName',
        'contactDisplayName',
      ]),
      contactDepartmentName: _pickString(json, structuredFields, [
        'deptName',
        'contactDepartmentName',
      ]),
      contactPostName: _pickString(json, structuredFields, [
        'postName',
        'contactPostName',
      ]),
      contactAvatar: _pickString(json, structuredFields, [
        'avatar',
        'contactAvatar',
      ]),
      locationName: _pickString(json, structuredFields, [
        'name',
        'locationName',
      ]),
      locationAddress: _pickString(json, structuredFields, [
        'address',
        'locationAddress',
      ]),
      locationLatitude: _pickDouble(json, structuredFields, ['latitude']),
      locationLongitude: _pickDouble(json, structuredFields, ['longitude']),
      locationProvider: _pickString(json, structuredFields, ['provider']),
      locationPoiId: _pickString(json, structuredFields, ['poiId']),
      quoteInfo: quoteInfo,
      forwardedFrom: _pickString(json, structuredFields, ['forwardedFrom']),
      atUserIds: _parseAtUserIds(json, extra),
      mentions: _parseMentions(json, extra),
      reeditContent: _pickString(json, structuredFields, ['reeditContent']),
      reeditDeadlineTs: _pickInt(json, structuredFields, ['reeditDeadlineTs']),
      systemEventKey: systemEventKey,
      systemEventParams: systemEventParams,
    );
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

  static Map<String, String>? _parseSystemEventParams(Map<String, dynamic> extra) {
    final i18n = extra['i18n'];
    if (i18n is Map) {
      final params = i18n['params'];
      if (params is Map) {
        final result = <String, String>{};
        params.forEach((key, value) {
          final k = key.toString();
          final v = value?.toString() ?? '';
          if (k.isNotEmpty) {
            result[k] = v;
          }
        });
        return result.isEmpty ? null : result;
      }
    }
    return null;
  }

  static List<String> _parseAtUserIds(
    Map<String, dynamic> json,
    Map<String, dynamic> extra,
  ) {
    final source = json['atUserIds'] ?? extra['atUserIds'];
    if (source is! List) {
      return const <String>[];
    }
    return source
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<MentionSegment> _parseMentions(
    Map<String, dynamic> json,
    Map<String, dynamic> extra,
  ) {
    final source = json['mentions'] ?? extra['mentions'];
    if (source is! List) {
      return const <MentionSegment>[];
    }
    final items = <MentionSegment>[];
    for (final item in source) {
      if (item is! Map) {
        continue;
      }
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final userId = map['userId']?.toString().trim() ?? '';
      final nickname = map['nickname']?.toString().trim() ?? '';
      final startIndex = (map['startIndex'] as num?)?.toInt();
      final endIndex = (map['endIndex'] as num?)?.toInt();
      if (userId.isEmpty ||
          nickname.isEmpty ||
          startIndex == null ||
          endIndex == null ||
          startIndex < 0 ||
          endIndex <= startIndex) {
        continue;
      }
      items.add(
        MentionSegment(
          userId: userId,
          nickname: nickname,
          startIndex: startIndex,
          endIndex: endIndex,
        ),
      );
    }
    return items;
  }

  static String _parseContent(
    Object? raw,
    Map<String, dynamic> contentMap,
    MessageType type,
    String? customType,
    bool isRecalled,
  ) {
    if (isRecalled) {
      final text = raw?.toString().trim() ?? '';
      return text.isEmpty ? '消息已撤回' : text;
    }
    final replyContent = contentMap['replyContent'];
    if (replyContent != null && replyContent.toString().trim().isNotEmpty) {
      return replyContent.toString();
    }
    if (type == MessageType.image || type == MessageType.video) {
      return _pickString(contentMap, contentMap, ['url', 'content']) ??
          raw?.toString() ??
          '';
    }
    if (type == MessageType.location) {
      return _pickString(contentMap, contentMap, ['address', 'content']) ??
          raw?.toString() ??
          '';
    }
    if (type == MessageType.file) {
      return _pickString(contentMap, contentMap, ['fileName', 'name']) ??
          raw?.toString() ??
          '';
    }
    if (type == MessageType.voice) {
      return '';
    }
    if (type == MessageType.sticker) {
      return _pickString(contentMap, contentMap, ['url', 'thumbUrl']) ??
          raw?.toString() ??
          '';
    }
    if (type == MessageType.contactCard || type == MessageType.custom) {
      if (raw is String) {
        return raw;
      }
      if (contentMap.isNotEmpty) {
        return jsonEncode(contentMap);
      }
    }
    if (type == MessageType.emoji && customType == null) {
      final candidate =
          _pickString(contentMap, contentMap, ['content', 'emoji']) ??
          raw?.toString() ??
          '';
      return ChatEmojiCatalog.normalizeTokenContent(candidate) ?? candidate;
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        return '';
      }
      return raw;
    }
    return raw?.toString() ?? '';
  }

  static Map<String, dynamic> _readExtra(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = raw.startsWith('{') ? raw : '';
        if (decoded.isNotEmpty) {
          return Map<String, dynamic>.from(
            jsonDecode(decoded) as Map<dynamic, dynamic>,
          );
        }
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  static String? _pickString(
    Map<String, dynamic> json,
    Map<String, dynamic> extra,
    List<String> keys,
  ) {
    for (final key in keys) {
      final topLevel = json[key];
      if (topLevel != null && topLevel.toString().isNotEmpty) {
        return topLevel.toString();
      }
      final nested = extra[key];
      if (nested != null && nested.toString().isNotEmpty) {
        return nested.toString();
      }
    }
    return null;
  }

  static bool? _pickBool(
    Map<String, dynamic> json,
    Map<String, dynamic> extra,
    List<String> keys,
  ) {
    for (final key in keys) {
      final candidates = [json[key], extra[key]];
      for (final value in candidates) {
        if (value is bool) {
          return value;
        }
        if (value is num) {
          return value != 0;
        }
        if (value != null) {
          final text = value.toString().trim().toLowerCase();
          if (text == 'true' || text == '1') {
            return true;
          }
          if (text == 'false' || text == '0') {
            return false;
          }
        }
      }
    }
    return null;
  }

  static int? _pickInt(
    Map<String, dynamic> json,
    Map<String, dynamic> extra,
    List<String> keys,
  ) {
    for (final key in keys) {
      final topLevel = json[key];
      if (topLevel is num) {
        return topLevel.toInt();
      }
      final nested = extra[key];
      if (nested is num) {
        return nested.toInt();
      }
      if (nested != null) {
        return int.tryParse(nested.toString());
      }
      if (topLevel != null) {
        return int.tryParse(topLevel.toString());
      }
    }
    return null;
  }

  static double? _pickDouble(
    Map<String, dynamic> json,
    Map<String, dynamic> extra,
    List<String> keys,
  ) {
    for (final key in keys) {
      final topLevel = json[key];
      if (topLevel is num) {
        return topLevel.toDouble();
      }
      final nested = extra[key];
      if (nested is num) {
        return nested.toDouble();
      }
      if (nested != null) {
        return double.tryParse(nested.toString());
      }
      if (topLevel != null) {
        return double.tryParse(topLevel.toString());
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final numeric = int.tryParse(text);
    if (numeric != null) {
      return DateTime.fromMillisecondsSinceEpoch(numeric);
    }
    return DateTime.tryParse(text);
  }

  static QuoteInfo? _parseQuoteInfo(
    Map<String, dynamic> json,
    Map<String, dynamic> extra,
    Map<String, dynamic> contentMap,
  ) {
    final messageId =
        _pickString(json, extra, ['quoteMessageId']) ??
        _pickString(contentMap, contentMap, [
          'quotedMessageId',
          'quoteMessageId',
        ]) ??
        _extractQuoteIdFromRaw(json['content']) ??
        _extractQuoteIdFromRaw(json['extra']);
    if (messageId == null || messageId.isEmpty || messageId == '0') {
      return null;
    }
    final senderName =
        _pickString(json, extra, ['quoteSenderName']) ??
        _pickString(contentMap, contentMap, [
          'quotedSenderName',
          'quoteSenderName',
        ]) ??
        _extractStringFieldFromRaw(json['content'], const [
          'quotedSenderName',
          'quoteSenderName',
        ]) ??
        _extractStringFieldFromRaw(json['extra'], const ['quoteSenderName']) ??
        '未知';
    final preview =
        _pickString(json, extra, ['quoteContent']) ??
        _pickString(contentMap, contentMap, [
          'quotedContent',
          'quoteContent',
        ]) ??
        _extractStringFieldFromRaw(json['content'], const [
          'quotedContent',
          'quoteContent',
        ]) ??
        _extractStringFieldFromRaw(json['extra'], const ['quoteContent']) ??
        '消息';
    return QuoteInfo(
      messageId: messageId,
      senderName: senderName,
      preview: preview,
    );
  }

  static String? _extractQuoteIdFromRaw(Object? raw) {
    final text = raw?.toString() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final patterns = [_quoteMsgIdPattern, _quoteMsgIdPattern2];
    for (final pattern in patterns) {
      final matched = pattern.firstMatch(text);
      final value = matched?.group(1)?.trim() ?? '';
      if (value.isNotEmpty && value != '0' && value != 'null') {
        return value;
      }
    }
    return null;
  }

  static String? _extractStringFieldFromRaw(Object? raw, List<String> keys) {
    final text = raw?.toString() ?? '';
    if (text.isEmpty) {
      return null;
    }
    for (final key in keys) {
      final escaped = RegExp.escape(key);
      final patterns = <RegExp>[
        RegExp('"$escaped"\\s*:\\s*"([^"]+)"'),
        RegExp('"$escaped"\\s*:\\s*([^,}\\]]+)'),
      ];
      for (final pattern in patterns) {
        final matched = pattern.firstMatch(text);
        final value = matched?.group(1)?.trim() ?? '';
        if (value.isNotEmpty && value != '0' && value != 'null') {
          return value.replaceAll(RegExp(r'^"|"$'), '');
        }
      }
    }
    return null;
  }

  static int? _pickDurationSeconds(
    Map<String, dynamic> extra,
    Map<String, dynamic> contentMap,
  ) {
    final duration = _pickInt(contentMap, extra, ['duration']);
    if (duration != null && duration > 0) {
      return duration;
    }
    final durationMs = _pickInt(contentMap, extra, ['durationMs']);
    if (durationMs != null && durationMs > 0) {
      return (durationMs / 1000).round();
    }
    return null;
  }

  static String? _parseCustomType(
    Map<String, dynamic> contentMap,
    Map<String, dynamic> extra,
  ) {
    final payload = contentMap.isNotEmpty ? contentMap : extra;
    if (payload.isEmpty) {
      return null;
    }
    final type = payload['type']?.toString().trim() ?? '';
    if (type.isNotEmpty) {
      return type;
    }
    if (payload['stickerId'] != null || payload['thumbUrl'] != null) {
      return 'STICKER';
    }
    if (payload['userId'] != null &&
        (payload['displayName'] != null || payload['deptName'] != null)) {
      return 'CONTACT_CARD';
    }
    return null;
  }

  static MessageType _normalizeCustomType(
    MessageType type,
    String? customType,
  ) {
    if (type != MessageType.custom) {
      return type;
    }
    final normalized = customType?.toUpperCase() ?? '';
    if (normalized == 'CONTACT_CARD') {
      return MessageType.contactCard;
    }
    if (normalized == 'STICKER') {
      return MessageType.sticker;
    }
    return MessageType.custom;
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

  static MessageStatus _parseMessageStatus(String? raw) {
    switch (raw) {
      case '0':
      case 'sending':
        return MessageStatus.sending;
      case '1':
      case 'sent':
        return MessageStatus.sent;
      case '2':
      case 'delivered':
        return MessageStatus.delivered;
      case '4':
      case 'read':
        return MessageStatus.read;
      case '6':
      case 'recalled':
        return MessageStatus.recalled;
      case '3':
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.read;
    }
  }
}
