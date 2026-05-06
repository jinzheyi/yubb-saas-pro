import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_media_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_detail_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/message_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/mappers/message_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/search/domain/entities/message_search_item.dart';

class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._remoteDataSource);

  final MessageRemoteDataSource _remoteDataSource;

  @override
  Future<ChatWindowResult> getMessageWindow(OpenChatCommand command) async {
    final dto = await _remoteDataSource.fetchLatestWindow(command);
    return MessageDtoMapper.toWindowResult(dto);
  }

  @override
  Future<ChatWindowResult> getOlderMessages({
    required String chatId,
    required String? beforeSequence,
  }) async {
    final dto = await _remoteDataSource.fetchOlderMessages(
      chatId: chatId,
      beforeSequence: beforeSequence,
    );
    return MessageDtoMapper.toWindowResult(dto);
  }

  @override
  Future<Message> getMessageDetail({required String messageId}) async {
    final dto = await _remoteDataSource.fetchMessageDetail(
      messageId: messageId,
    );
    return MessageDtoMapper.toEntity(dto);
  }

  @override
  Future<void> markConversationRead({required String chatId}) async {
    await _remoteDataSource.markConversationRead(chatId: chatId);
  }

  @override
  Future<void> addFavorite({required String messageId}) async {
    await _remoteDataSource.addFavorite(messageId: messageId);
  }

  @override
  Future<void> markVoicePlayed({required String messageId}) async {
    await _remoteDataSource.markVoicePlayed(messageId: messageId);
  }

  @override
  Future<void> markVoicePlayedBatch({required List<String> messageIds}) async {
    await _remoteDataSource.markVoicePlayedBatch(messageIds: messageIds);
  }

  @override
  Future<List<String>> getVoicePlayedStatus({
    required String chatId,
    required List<String> messageIds,
  }) {
    return _remoteDataSource.fetchVoicePlayedStatus(
      chatId: chatId,
      messageIds: messageIds,
    );
  }

  @override
  Future<int> getRecallWindowSeconds() {
    return _remoteDataSource.fetchRecallWindowSeconds();
  }

  @override
  Future<void> recallMessage({required String messageId}) async {
    await _remoteDataSource.recallMessage(messageId: messageId);
  }

  @override
  Future<void> deleteMessage({required String messageId}) async {
    await _remoteDataSource.deleteMessage(messageId: messageId);
  }

  @override
  Future<void> clearConversationHistory({required String chatId}) async {
    await _remoteDataSource.clearConversationHistory(chatId: chatId);
  }

  @override
  Future<ReadReceiptSummary?> getReadReceiptSummary({
    required String messageId,
  }) async {
    final item = await _remoteDataSource.fetchReadReceiptSummary(
      messageId: messageId,
    );
    if (item == null) {
      return null;
    }
    return ReadReceiptSummary(
      messageId: item.messageId,
      chatId: item.chatId,
      sequence: item.sequence,
      readCount: item.readCount,
      unreadCount: item.unreadCount,
      totalCount: item.totalCount,
    );
  }

  @override
  Future<List<ReadReceiptDetailItem>> getReadReceiptDetail({
    required String messageId,
    required String status,
    int pageNo = 1,
    int pageSize = 100,
  }) async {
    final items = await _remoteDataSource.fetchReadReceiptDetail(
      messageId: messageId,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return items
        .map(
          (item) => ReadReceiptDetailItem(
            userId: item.userId,
            userName: item.userName,
            avatar: item.avatar,
            readTime: item.readTime,
          ),
        )
        .toList();
  }

  @override
  Future<List<ChatMediaItem>> getChatMedia({
    required String chatId,
    String? fileType,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final items = await _remoteDataSource.fetchChatMedia(
      chatId: chatId,
      fileType: fileType,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return items
        .map(
          (item) => ChatMediaItem(
            messageId: item.messageId,
            chatId: item.chatId,
            fileId: item.fileId,
            fileName: item.fileName,
            fileSize: item.fileSize,
            fileUrl: item.fileUrl,
            thumbnailUrl: item.thumbnailUrl,
            senderName: item.senderName,
            sentAt: item.sentAt,
            messageType: item.messageType,
            mimeType: item.mimeType,
          ),
        )
        .toList();
  }

  @override
  Future<List<ChatHistoryItem>> searchChatHistory({
    required String chatId,
    required String keyword,
    String? category,
    String? startTime,
    String? endTime,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final items = await _remoteDataSource.searchChatHistory(
      chatId: chatId,
      keyword: keyword,
      category: category,
      startTime: startTime,
      endTime: endTime,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return items
        .map(
          (item) => ChatHistoryItem(
            messageId: item.messageId,
            chatId: item.chatId,
            sequence: item.sequence,
            senderId: item.senderId,
            senderName: item.senderName,
            senderAvatar: item.senderAvatar,
            content: item.content,
            messageType: item.messageType,
            sentAt: item.sentAt,
            systemEventKey: item.systemEventKey,
          ),
        )
        .toList();
  }

  @override
  Future<List<MessageSearchItem>> searchMessages({
    required String keyword,
    String? chatId,
    String? category,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    final items = await _remoteDataSource.searchMessages(
      keyword: keyword,
      chatId: chatId,
      category: category,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return items
        .map(
          (item) => MessageSearchItem(
            id: item.id,
            messageId: item.messageId,
            chatId: item.chatId,
            sequence: item.sequence,
            conversationName: item.conversationName,
            senderName: item.senderName,
            content: item.content,
            snippet: item.snippet,
            highlight: item.highlight,
            messageType: item.messageType,
            timestamp: item.timestamp,
            conversationType: item.conversationType,
            targetId: item.targetId,
            groupId: item.groupId,
          ),
        )
        .toList();
  }

  @override
  Future<List<LocationSearchItem>> searchLocations({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  }) async {
    final items = await _remoteDataSource.searchLocations(
      keyword: keyword,
      latitude: latitude,
      longitude: longitude,
      pageSize: pageSize,
    );
    return items
        .map(
          (item) => LocationSearchItem(
            poiId: item.poiId,
            name: item.name,
            address: item.address,
            latitude: item.latitude,
            longitude: item.longitude,
            provider: item.provider,
          ),
        )
        .toList();
  }

  @override
  Future<LocationSearchResult> searchLocationResult({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  }) async {
    final result = await _remoteDataSource.searchLocationResult(
      keyword: keyword,
      latitude: latitude,
      longitude: longitude,
      pageSize: pageSize,
    );
    return LocationSearchResult(
      enabled: result.enabled,
      message: result.message,
      items: result.items
          .map(
            (item) => LocationSearchItem(
              poiId: item.poiId,
              name: item.name,
              address: item.address,
              latitude: item.latitude,
              longitude: item.longitude,
              provider: item.provider,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<int?> forwardMessages({
    required String targetChatId,
    required List<String> messageIds,
    int forwardType = 1,
    String? comment,
  }) async {
    return _remoteDataSource.forwardMessages(
      targetChatId: targetChatId,
      messageIds: messageIds,
      forwardType: forwardType,
      comment: comment,
    );
  }

  @override
  Future<SendMessageResult> sendTextMessage({
    required String chatId,
    required String text,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  }) async {
    final dto = await _remoteDataSource.sendTextMessage(
      chatId: chatId,
      text: text,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
      quoteInfo: quoteInfo,
      atUserIds: atUserIds,
      mentions: mentions,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }

  @override
  Future<SendMessageResult> sendImageMessage({
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
    final dto = await _remoteDataSource.sendImageMessage(
      chatId: chatId,
      fileId: fileId,
      url: url,
      thumbnailUrl: thumbnailUrl,
      width: width,
      height: height,
      size: size,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }

  @override
  Future<SendMessageResult> sendVideoMessage({
    required String chatId,
    required String fileId,
    required String url,
    required String thumbnailUrl,
    required int duration,
    required int width,
    required int height,
    required int size,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final dto = await _remoteDataSource.sendVideoMessage(
      chatId: chatId,
      fileId: fileId,
      url: url,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      width: width,
      height: height,
      size: size,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }

  @override
  Future<SendMessageResult> sendVoiceMessage({
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
    final dto = await _remoteDataSource.sendVoiceMessage(
      chatId: chatId,
      fileId: fileId,
      url: url,
      duration: duration,
      size: size,
      durationMs: durationMs,
      format: format,
      md5: md5,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }

  @override
  Future<SendMessageResult> sendFileMessage({
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
    final dto = await _remoteDataSource.sendFileMessage(
      chatId: chatId,
      fileId: fileId,
      url: url,
      fileName: fileName,
      size: size,
      fileType: fileType,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }

  @override
  Future<SendMessageResult> sendLocationMessage({
    required String chatId,
    required LocationSharePayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final dto = await _remoteDataSource.sendLocationMessage(
      chatId: chatId,
      payload: payload,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }

  @override
  Future<SendMessageResult> sendStickerMessage({
    required String chatId,
    required StickerPayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final dto = await _remoteDataSource.sendStickerMessage(
      chatId: chatId,
      payload: payload,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }

  @override
  Future<SendMessageResult> sendContactCardMessage({
    required String chatId,
    required ContactCardSharePayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  }) async {
    final dto = await _remoteDataSource.sendContactCardMessage(
      chatId: chatId,
      payload: payload,
      clientMessageId: clientMessageId,
      receiverId: receiverId,
      groupId: groupId,
    );
    return SendMessageResult(message: MessageDtoMapper.toEntity(dto));
  }
}
