import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/dtos/conversation_dto.dart';

class ConversationSyncResponseDto {
  const ConversationSyncResponseDto({
    required this.cursorVersion,
    required this.items,
    required this.hasMore,
  });

  final String cursorVersion;
  final List<ConversationDto> items;
  final bool hasMore;

  factory ConversationSyncResponseDto.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final rawItems =
        json['items'] as List<dynamic>? ??
        json['list'] as List<dynamic>? ??
        json['records'] as List<dynamic>? ??
        const [];
    return ConversationSyncResponseDto(
      cursorVersion:
          json['nextCursorVersion']?.toString() ??
          json['cursorVersion']?.toString() ??
          json['version']?.toString() ??
          '0',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => ConversationDto.fromJson(e, currentUserId: currentUserId))
          .toList(),
      hasMore: _parseBool(json['hasMore']) || _parseBool(json['more']),
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
}
