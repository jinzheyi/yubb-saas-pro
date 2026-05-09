import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_media_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_detail_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';
import 'package:shengyu_ui_admin_im/features/im/search/domain/entities/message_search_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';

abstract class MessageRepository {
  Future<ChatWindowResult> getMessageWindow(OpenChatCommand command);

  Future<ChatWindowResult> getOlderMessages({
    required String chatId,
    required String? beforeSequence,
  });

  Future<Message> getMessageDetail({required String messageId});

  Future<SendMessageResult> sendTextMessage({
    required String chatId,
    required String text,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  });

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
  });

  Future<SendMessageResult> sendVideoMessage({
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
  });

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
  });

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
  });

  Future<SendMessageResult> sendContactCardMessage({
    required String chatId,
    required ContactCardSharePayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  });

  Future<SendMessageResult> sendLocationMessage({
    required String chatId,
    required LocationSharePayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  });

  Future<SendMessageResult> sendStickerMessage({
    required String chatId,
    required StickerPayload payload,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
  });

  Future<void> markConversationRead({required String chatId});

  Future<void> addFavorite({required String messageId});

  Future<void> markVoicePlayed({required String messageId});

  Future<void> markVoicePlayedBatch({required List<String> messageIds});

  Future<List<String>> getVoicePlayedStatus({
    required String chatId,
    required List<String> messageIds,
  });

  Future<int> getRecallWindowSeconds();

  Future<void> recallMessage({required String messageId});

  Future<void> deleteMessage({required String messageId});

  Future<void> clearConversationHistory({required String chatId});

  Future<ReadReceiptSummary?> getReadReceiptSummary({
    required String messageId,
  });

  Future<List<ReadReceiptDetailItem>> getReadReceiptDetail({
    required String messageId,
    required String status,
    int pageNo = 1,
    int pageSize = 100,
  });

  Future<List<ChatMediaItem>> getChatMedia({
    required String chatId,
    String? fileType,
    int pageNo = 1,
    int pageSize = 50,
  });

  Future<List<ChatHistoryItem>> searchChatHistory({
    required String chatId,
    required String keyword,
    String? category,
    String? startTime,
    String? endTime,
    int pageNo = 1,
    int pageSize = 50,
  });

  Future<List<MessageSearchItem>> searchMessages({
    required String keyword,
    String? chatId,
    String? category,
    int pageNo = 1,
    int pageSize = 20,
  });

  Future<List<LocationSearchItem>> searchLocations({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  });

  Future<LocationSearchResult> searchLocationResult({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  });

  Future<int?> forwardMessages({
    required String targetChatId,
    required List<String> messageIds,
    int forwardType = 1,
    String? comment,
  });
}
