import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_dto.dart';

class MessageWindowResponseDto {
  const MessageWindowResponseDto({
    required this.messages,
    required this.hasMoreBefore,
    required this.hasMoreAfter,
    required this.anchorFound,
    this.anchorMessageId,
    this.oldestSequence,
    this.newestSequence,
  });

  final List<MessageDto> messages;
  final bool hasMoreBefore;
  final bool hasMoreAfter;
  final bool anchorFound;
  final String? anchorMessageId;
  final String? oldestSequence;
  final String? newestSequence;

  factory MessageWindowResponseDto.fromJson(Map<String, dynamic> json) {
    final rawMessages =
        json['messages'] as List<dynamic>? ??
        json['list'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        const [];
    return MessageWindowResponseDto(
      messages: rawMessages
          .whereType<Map<String, dynamic>>()
          .map(MessageDto.fromJson)
          .toList(),
      hasMoreBefore: _parseBool(json['hasMoreBefore'] ?? json['beforeHasMore']),
      hasMoreAfter: _parseBool(json['hasMoreAfter'] ?? json['afterHasMore']),
      anchorFound: !_parseExplicitFalse(json['anchorFound']),
      anchorMessageId:
          json['anchorMessageId']?.toString() ?? json['anchorId']?.toString(),
      oldestSequence:
          json['oldestSequence']?.toString() ??
          json['minSequence']?.toString() ??
          json['firstSequence']?.toString(),
      newestSequence:
          json['newestSequence']?.toString() ??
          json['maxSequence']?.toString() ??
          json['lastSequence']?.toString(),
    );
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

  static bool _parseExplicitFalse(Object? raw) {
    if (raw is bool) {
      return raw == false;
    }
    if (raw is num) {
      return raw == 0;
    }
    final text = raw?.toString().trim().toLowerCase() ?? '';
    return text == 'false' || text == '0';
  }
}
