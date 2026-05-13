import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/chat_history_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/chat_media_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/location_search_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/location_search_result_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_window_response_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/read_receipt_detail_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/read_receipt_summary_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/search/infrastructure/dtos/message_search_item_dto.dart';

class MessageRemoteDataSource {
  MessageRemoteDataSource({required this.dio});

  final Dio dio;

  Future<MessageDto> _resolveSendMessageDto(
    Object? responseBody, {
    required String chatId,
    required String clientMessageId,
    required int messageType,
    required String content,
    String? extra,
  }) async {
    final result = ApiResult.fromJson<Object?>(
      responseBody as Map<String, dynamic>,
      dataParser: (raw) => raw,
    );
    if (!result.isSuccess) {
      throw ApiException(
        code: result.code,
        message: result.message.isEmpty ? 'API request failed' : result.message,
        details: result.data,
      );
    }
    final raw = result.data;
    if (raw is Map<String, dynamic>) {
      return MessageDto.fromJson(raw);
    }
    if (raw is Map) {
      return MessageDto.fromJson(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    final messageId = _extractSentMessageId(raw);
    return _buildAcceptedSendAckDto(
      messageId,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: messageType,
      content: content,
      extra: extra,
    );
  }

  String? _extractSentMessageId(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      final value = raw.toInt().toString();
      return value.isEmpty || value == '0' ? null : value;
    }
    final text = raw.toString().trim();
    if (text.isEmpty || text == '0' || text == 'null') {
      return null;
    }
    return text;
  }

  MessageDto _buildAcceptedSendAckDto(
    String? messageId, {
    required String chatId,
    required String clientMessageId,
    required int messageType,
    required String content,
    String? extra,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return MessageDto.fromJson(<String, dynamic>{
      'id': messageId ?? '',
      'messageId': messageId ?? '',
      'status': 'sent',
      'messageType': messageType,
      'content': content,
      'createdAt': now,
      'sentAt': now,
      'chatId': chatId,
      'senderId': '',
      'senderName': '',
      'isOutgoing': true,
      'clientMessageId': clientMessageId,
      if (extra != null && extra.trim().isNotEmpty) 'extra': extra,
    });
  }

  Future<MessageWindowResponseDto> fetchLatestWindow(
    OpenChatCommand command,
  ) async {
    final queryParameters = <String, dynamic>{
      'chatId': command.chatId,
      if (command.windowMode != null && command.windowMode!.isNotEmpty)
        'mode': command.windowMode,
      if (command.anchorSequence != null && command.anchorSequence!.isNotEmpty)
        'anchorSequence': command.anchorSequence,
      if (command.anchorMessageId != null &&
          command.anchorMessageId!.isNotEmpty)
        'anchorMessageId': command.anchorMessageId,
      if (command.windowLimit != null && command.windowLimit! > 0)
        'limit': command.windowLimit,
      if (command.beforeLimit != null && command.beforeLimit! > 0)
        'beforeLimit': command.beforeLimit,
      if (command.afterLimit != null && command.afterLimit! > 0)
        'afterLimit': command.afterLimit,
    };
    final response = await dio.get(
      '/system/im/message/window',
      queryParameters: queryParameters,
    );
    final result = ApiResult.fromJson<MessageWindowResponseDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return MessageWindowResponseDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
        );
      },
    );
    return result.requireData();
  }

  Future<MessageWindowResponseDto> fetchOlderMessages({
    required String chatId,
    required String? beforeSequence,
  }) async {
    final response = await dio.get(
      '/system/im/message/history',
      queryParameters: {
        'chatId': chatId,
        'beforeSequence': beforeSequence,
        'limit': 30,
      },
    );
    final result = ApiResult.fromJson<MessageWindowResponseDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return MessageWindowResponseDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
        );
      },
    );
    return result.requireData();
  }

  Future<MessageDto> fetchMessageDetail({required String messageId}) async {
    final response = await dio.get(
      '/system/im/message/detail',
      queryParameters: {'id': messageId},
    );
    final result = ApiResult.fromJson<MessageDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return MessageDto.fromJson(raw as Map<String, dynamic>? ?? const {});
      },
    );
    return result.requireData();
  }

  Future<MessageDto> sendTextMessage({
    required String chatId,
    required String text,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  }) async {
    final normalizedAtUserIds = atUserIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    final mentionsPayload = mentions
        .map((item) => item.toJson())
        .toList(growable: false);
    final trimmedText = text.trim();
    final isQuoteReply = quoteInfo != null;
    final contentPayload = isQuoteReply
        ? jsonEncode(<String, Object?>{
            'content': trimmedText,
            'quotedMessageId': quoteInfo.messageId,
            'quotedContent': quoteInfo.preview,
            'quotedSenderName': quoteInfo.senderName,
            'atUserIds': normalizedAtUserIds,
            'mentions': mentionsPayload,
          })
        : trimmedText;
    final extraPayload = isQuoteReply
        ? contentPayload
        : (normalizedAtUserIds.isEmpty && mentionsPayload.isEmpty
              ? null
              : jsonEncode(<String, Object?>{
                  'atUserIds': normalizedAtUserIds,
                  'mentions': mentionsPayload,
                }));
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': isQuoteReply ? 205 : 1,
        'content': contentPayload,
        'clientMessageId': clientMessageId,
        if (normalizedAtUserIds.isNotEmpty) 'atUserIds': normalizedAtUserIds,
        if (mentionsPayload.isNotEmpty) 'mentions': mentionsPayload,
        ...?extraPayload == null
            ? null
            : <String, Object?>{'extra': extraPayload},
        if (quoteInfo != null) 'quoteMessageId': quoteInfo.messageId,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: isQuoteReply ? 205 : 1,
      content: contentPayload,
      extra: extraPayload,
    );
  }

  Future<MessageDto> sendImageMessage({
    required String chatId,
    required String fileId,
    required String url,
    required String thumbnailUrl,
    required int width,
    required int height,
    required int size,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final extra = jsonEncode({
      'fileId': fileId,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'width': width,
      'height': height,
      'size': size,
    });
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': 2,
        'content': url,
        'clientMessageId': clientMessageId,
        'extra': extra,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: 2,
      content: url,
      extra: extra,
    );
  }

  Future<MessageDto> sendVideoMessage({
    required String chatId,
    required String fileId,
    required String url,
    String? thumbFileId,
    required String thumbnailUrl,
    required int duration,
    required int width,
    required int height,
    required int size,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final extra = jsonEncode({
      'fileId': fileId,
      if (thumbFileId?.trim().isNotEmpty == true) 'thumbFileId': thumbFileId,
      'url': url,
      if (thumbnailUrl.trim().isNotEmpty) 'coverUrl': thumbnailUrl,
      if (thumbnailUrl.trim().isNotEmpty) 'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'width': width,
      'height': height,
      'size': size,
    });
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': 4,
        'content': url,
        'clientMessageId': clientMessageId,
        'extra': extra,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: 4,
      content: url,
      extra: extra,
    );
  }

  Future<MessageDto> sendVoiceMessage({
    required String chatId,
    required String fileId,
    required String url,
    required int duration,
    required int size,
    required int durationMs,
    required String format,
    required String md5,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final extra = jsonEncode({
      'fileId': fileId,
      'url': url,
      'duration': duration,
      'size': size,
      'durationMs': durationMs,
      'format': format,
      'md5': md5,
    });
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': 3,
        'content': url,
        'clientMessageId': clientMessageId,
        'extra': extra,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: 3,
      content: url,
      extra: extra,
    );
  }

  Future<MessageDto> sendFileMessage({
    required String chatId,
    required String fileId,
    required String url,
    required String fileName,
    required int size,
    required String fileType,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final extra = jsonEncode({
      'fileId': fileId,
      'url': url,
      'fileName': fileName,
      'size': size,
      'fileType': fileType,
    });
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': 5,
        'content': url,
        'clientMessageId': clientMessageId,
        'extra': extra,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: 5,
      content: url,
      extra: extra,
    );
  }

  Future<MessageDto> sendContactCardMessage({
    required String chatId,
    required ContactCardSharePayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final contentRaw = jsonEncode({
      'type': 'CONTACT_CARD',
      'userId': payload.userId,
      'displayName': payload.displayName,
      'deptName': payload.departmentName,
      'postName': payload.postName,
      'avatar': payload.avatar,
    });
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': 9,
        'content': contentRaw,
        'extra': contentRaw,
        'clientMessageId': clientMessageId,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: 9,
      content: contentRaw,
      extra: contentRaw,
    );
  }

  Future<MessageDto> sendLocationMessage({
    required String chatId,
    required LocationSharePayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final preview = payload.address.trim().isNotEmpty
        ? payload.address.trim()
        : payload.name.trim();
    final extraRaw = jsonEncode({
      'clientMessageId': clientMessageId,
      'latitude': payload.latitude,
      'longitude': payload.longitude,
      'address': payload.address,
      'name': payload.name,
      'provider': payload.provider,
      'poiId': payload.poiId,
    });
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': 6,
        'content': preview,
        'extra': extraRaw,
        'clientMessageId': clientMessageId,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: 6,
      content: preview,
      extra: extraRaw,
    );
  }

  Future<MessageDto> sendStickerMessage({
    required String chatId,
    required StickerPayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final contentRaw = jsonEncode({
      'type': 'STICKER',
      'stickerId': payload.stickerId,
      'fileId': payload.fileId,
      'thumbFileId': payload.thumbFileId ?? '',
      'url': payload.url,
      'thumbUrl': payload.thumbUrl ?? '',
      'md5': payload.md5 ?? '',
      'width': payload.width,
      'height': payload.height,
      'mimeType': payload.mimeType ?? '',
    });
    final response = await dio.post(
      '/system/im/message/send',
      data: {
        'chatId': chatId,
        if (receiverId != null &&
            receiverId.trim().isNotEmpty &&
            receiverId != '0')
          'receiverId': receiverId.trim(),
        if (groupId != null && groupId.trim().isNotEmpty && groupId != '0')
          'groupId': groupId.trim(),
        'messageType': 8,
        'content': '[动画表情]',
        'extra': contentRaw,
        'clientMessageId': clientMessageId,
      },
    );
    return _resolveSendMessageDto(
      response.data,
      chatId: chatId,
      clientMessageId: clientMessageId,
      messageType: 8,
      content: '[动画表情]',
      extra: contentRaw,
    );
  }

  Future<void> markConversationRead({
    required String chatId,
    required String readSequence,
  }) async {
    await dio.put(
      '/system/im/conversation/mark-read-seq',
      queryParameters: {'chatId': chatId, 'readSequence': readSequence},
    );
  }

  Future<void> addFavorite({required String messageId}) async {
    await dio.post('/system/im/favorite/add', data: {'messageId': messageId});
  }

  Future<void> markVoicePlayed({required String messageId}) async {
    await dio.put(
      '/system/im/message/mark-voice-played',
      queryParameters: {'messageId': messageId},
    );
  }

  Future<void> markVoicePlayedBatch({required List<String> messageIds}) async {
    final ids = messageIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    if (ids.isEmpty) {
      return;
    }
    await dio.put(
      '/system/im/message/mark-voice-played-batch',
      queryParameters: {'messageIds': ids},
    );
  }

  Future<List<String>> fetchVoicePlayedStatus({
    required String chatId,
    required List<String> messageIds,
  }) async {
    final ids = messageIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    if (chatId.trim().isEmpty || ids.isEmpty) {
      return const <String>[];
    }
    final response = await dio.get(
      '/system/im/message/voice-played-status',
      queryParameters: {'chatId': chatId, 'messageIds': ids},
    );
    final result = ApiResult.fromJson<List<String>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _parseVoicePlayedIds(raw),
    );
    return result.data;
  }

  Future<int> fetchRecallWindowSeconds() async {
    final response = await dio.get('/system/im/message/recall-config');
    final result = ApiResult.fromJson<int>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final map = raw as Map<String, dynamic>? ?? const {};
        return (map['windowSeconds'] as num?)?.toInt() ?? 120;
      },
    );
    return result.data;
  }

  Future<void> recallMessage({required String messageId}) async {
    await dio.put(
      '/system/im/message/recall',
      queryParameters: {'id': messageId},
    );
  }

  Future<void> deleteMessage({required String messageId}) async {
    await dio.delete(
      '/system/im/message/delete',
      queryParameters: {'id': messageId},
    );
  }

  Future<void> clearConversationHistory({required String chatId}) async {
    await dio.delete(
      '/system/im/message/clear',
      queryParameters: {'chatId': chatId},
    );
  }

  List<String> _parseVoicePlayedIds(Object? raw) {
    final ids = <String>[];
    final seen = <String>{};

    void append(Object? value) {
      final id = value?.toString().trim() ?? '';
      if (id.isEmpty || id == '0' || !seen.add(id)) {
        return;
      }
      ids.add(id);
    }

    if (raw is List) {
      for (final item in raw) {
        append(item);
      }
      return ids;
    }
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is List) {
        for (final item in nested) {
          append(item);
        }
      }
    }
    return ids;
  }

  Future<ReadReceiptSummaryDto?> fetchReadReceiptSummary({
    required String messageId,
  }) async {
    final response = await dio.get(
      '/system/im/read-receipt/summary',
      queryParameters: {'messageId': messageId},
    );
    final result = ApiResult.fromJson<ReadReceiptSummaryDto?>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        if (raw == null) {
          return null;
        }
        return ReadReceiptSummaryDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
        );
      },
    );
    return result.data;
  }

  Future<List<ReadReceiptSummaryDto>> fetchReadReceiptSummaries({
    required List<String> messageIds,
  }) async {
    final normalizedIds = messageIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    if (normalizedIds.isEmpty) {
      return const <ReadReceiptSummaryDto>[];
    }
    final response = await dio.get(
      '/system/im/read-receipt/summary/batch',
      queryParameters: {'messageIds': normalizedIds},
    );
    final result = ApiResult.fromJson<List<ReadReceiptSummaryDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final items = raw is Map<String, dynamic>
            ? _resolveList(raw)
            : raw is List
            ? raw
            : const <dynamic>[];
        return items
            .whereType<Map<String, dynamic>>()
            .map((item) => ReadReceiptSummaryDto.fromJson(item))
            .toList(growable: false);
      },
    );
    return result.data;
  }

  Future<List<ReadReceiptDetailItemDto>> fetchReadReceiptDetail({
    required String messageId,
    required String status,
    int pageNo = 1,
    int pageSize = 100,
  }) async {
    final response = await dio.get(
      '/system/im/read-receipt/detail',
      queryParameters: {
        'messageId': messageId,
        'status': status,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
    );
    final result = ApiResult.fromJson<List<ReadReceiptDetailItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final items = _resolveList(data);
        return items
            .whereType<Map<String, dynamic>>()
            .map(ReadReceiptDetailItemDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<List<ChatMediaItemDto>> fetchChatMedia({
    required String chatId,
    String? fileType,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final response = await dio.get(
      '/system/im/message/media',
      queryParameters: {
        'chatId': chatId,
        'pageNo': pageNo,
        'pageSize': pageSize,
        if (fileType != null && fileType.isNotEmpty) 'fileType': fileType,
      },
    );
    final result = ApiResult.fromJson<List<ChatMediaItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final items = _resolveList(data);
        return items
            .whereType<Map<String, dynamic>>()
            .map(ChatMediaItemDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<List<ChatHistoryItemDto>> searchChatHistory({
    required String chatId,
    required String keyword,
    String? category,
    String? startTime,
    String? endTime,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final response = await dio.get(
      '/system/im/message/search',
      queryParameters: {
        'chatId': chatId,
        'keyword': keyword.trim(),
        if (startTime != null && startTime.isNotEmpty) 'startTime': startTime,
        if (endTime != null && endTime.isNotEmpty) 'endTime': endTime,
        'pageNo': pageNo,
        'pageSize': pageSize,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final result = ApiResult.fromJson<List<ChatHistoryItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final items = _resolveList(data);
        return items
            .whereType<Map<String, dynamic>>()
            .map(ChatHistoryItemDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<List<MessageSearchItemDto>> searchMessages({
    required String keyword,
    String? chatId,
    String? category,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get(
      '/system/im/message/search',
      queryParameters: {
        'keyword': keyword.trim(),
        'pageNo': pageNo,
        'pageSize': pageSize,
        if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final result = ApiResult.fromJson<List<MessageSearchItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final items = data['list'] as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(MessageSearchItemDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<List<LocationSearchItemDto>> searchLocations({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  }) async {
    final result = await searchLocationResult(
      keyword: keyword,
      latitude: latitude,
      longitude: longitude,
      pageSize: pageSize,
    );
    return result.items;
  }

  Future<LocationSearchResultDto> searchLocationResult({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  }) async {
    final clampedPageSize = pageSize < 1 ? 1 : (pageSize > 20 ? 20 : pageSize);
    final queryParameters = <String, dynamic>{
      'keyword': keyword.trim(),
      'pageSize': clampedPageSize,
    };
    if (latitude != null) {
      queryParameters['latitude'] = latitude;
    }
    if (longitude != null) {
      queryParameters['longitude'] = longitude;
    }
    final response = await dio.get(
      '/system/im/message/location-search',
      queryParameters: queryParameters,
    );
    final result = ApiResult.fromJson<LocationSearchResultDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final items =
            data['pois'] as List<dynamic>? ??
            data['list'] as List<dynamic>? ??
            data['records'] as List<dynamic>? ??
            data['items'] as List<dynamic>? ??
            const [];
        final parsedItems = items
            .whereType<Map<String, dynamic>>()
            .map(LocationSearchItemDto.fromJson)
            .toList();
        return LocationSearchResultDto(
          enabled: data['enabled'] != false,
          message: data['message']?.toString() ?? '',
          items: parsedItems,
        );
      },
    );
    return result.requireData();
  }

  Future<int?> forwardMessages({
    required String targetChatId,
    required List<String> messageIds,
    int forwardType = 1,
    String? comment,
  }) async {
    final normalizedTargetChatId = targetChatId.trim();
    final normalizedMessageIds = messageIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    if (normalizedTargetChatId.isEmpty || normalizedMessageIds.isEmpty) {
      throw ArgumentError('invalid forward params');
    }
    final response = await dio.post(
      '/system/im/message/forward',
      data: {
        'targetChatId': normalizedTargetChatId,
        'messageIds': normalizedMessageIds,
        'forwardType': forwardType == 2 ? 2 : 1,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    final result = ApiResult.fromJson<int?>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        if (raw is List) {
          return raw.length;
        }
        if (raw is Map<String, dynamic>) {
          final messageIds = raw['messageIds'];
          if (messageIds is List) {
            return messageIds.length;
          }
          final records = raw['records'];
          if (records is List) {
            return records.length;
          }
          final count = raw['count'];
          if (count is num) {
            return count.toInt();
          }
        }
        if (raw is Map) {
          final messageIds = raw['messageIds'];
          if (messageIds is List) {
            return messageIds.length;
          }
        }
        if (raw is num) {
          return raw.toInt();
        }
        return null;
      },
    );
    return result.requireData();
  }

  List<dynamic> _resolveList(Map<String, dynamic> data) {
    return data['list'] as List<dynamic>? ??
        data['records'] as List<dynamic>? ??
        data['items'] as List<dynamic>? ??
        const [];
  }
}
