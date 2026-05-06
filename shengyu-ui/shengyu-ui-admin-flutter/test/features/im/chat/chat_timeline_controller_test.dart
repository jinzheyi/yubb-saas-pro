import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_media_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_chat_window_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_older_messages_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_detail_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_timeline_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/search/domain/entities/message_search_item.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

void main() {
  late ChatTimelineController controller;

  setUp(() {
    final repository = _FakeMessageRepository();
    controller = ChatTimelineController(
      LoadChatWindowUseCase(repository),
      LoadOlderMessagesUseCase(repository),
    );
  });

  test('replaceSingleMessage swaps optimistic message by clientMessageId', () {
    controller.appendSingleMessage(
      _message(messageId: 'c-1', clientMessageId: 'c-1'),
    );

    controller.replaceSingleMessage(
      clientMessageId: 'c-1',
      message: _message(
        messageId: 'm-100',
        clientMessageId: 'c-1',
        status: MessageStatus.sent,
        sequence: '100',
      ),
    );

    expect(controller.state.messages, hasLength(1));
    expect(controller.state.messages.single.messageId, 'm-100');
    expect(controller.state.messages.single.clientMessageId, 'c-1');
    expect(controller.state.messages.single.status, MessageStatus.sent);
  });

  test('markFailedByClientMessageId marks optimistic message as failed', () {
    controller.appendSingleMessage(
      _message(messageId: 'c-2', clientMessageId: 'c-2'),
    );

    controller.markFailedByClientMessageId(clientMessageId: 'c-2');

    expect(controller.state.messages.single.status, MessageStatus.failed);
  });

  test(
    'applyRecalledMessage keeps original sequence and merges reedit info',
    () {
      controller.appendSingleMessage(
        _message(
          messageId: 'm-1',
          status: MessageStatus.sent,
          sequence: '10',
          content: 'original',
        ),
      );

      controller.applyRecalledMessage(
        _message(
          messageId: 'm-1',
          status: MessageStatus.read,
          type: MessageType.system,
          content: '你撤回了一条消息',
          extra: const MessageExtra(
            reeditContent: 'original',
            reeditDeadlineTs: 123456,
          ),
        ),
      );

      expect(controller.state.messages, hasLength(1));
      expect(controller.state.messages.single.type, MessageType.system);
      expect(controller.state.messages.single.content, '你撤回了一条消息');
      expect(controller.state.messages.single.sequence, '10');
      expect(controller.state.messages.single.extra.reeditContent, 'original');
      expect(controller.state.messages.single.extra.reeditDeadlineTs, 123456);
    },
  );

  test('applyWindow keeps recalled final state over stale text payload', () {
    controller.appendSingleMessage(
      _message(
        messageId: 'm-2',
        status: MessageStatus.read,
        type: MessageType.system,
        content: '你撤回了一条消息',
        sequence: '20',
        extra: const MessageExtra(
          reeditContent: 'original text',
          reeditDeadlineTs: 999999,
        ),
      ),
    );

    controller.applyWindow(
      ChatWindowResult(
        messages: <Message>[
          _message(
            messageId: 'm-2',
            status: MessageStatus.sent,
            type: MessageType.text,
            content: 'stale text',
            sequence: '20',
          ),
        ],
        viewportState: const ChatViewportState(
          anchorMessageId: null,
          hasMoreBefore: false,
          hasMoreAfter: false,
        ),
      ),
    );

    expect(controller.state.messages.single.type, MessageType.system);
    expect(controller.state.messages.single.content, '你撤回了一条消息');
    expect(
      controller.state.messages.single.extra.reeditContent,
      'original text',
    );
  });
}

class _FakeMessageRepository implements MessageRepository {
  @override
  Future<Message> getMessageDetail({required String messageId}) {
    throw UnimplementedError();
  }

  @override
  Future<ChatWindowResult> getMessageWindow(OpenChatCommand command) async {
    return const ChatWindowResult(
      messages: <Message>[],
      viewportState: ChatViewportState(
        anchorMessageId: null,
        hasMoreBefore: false,
        hasMoreAfter: false,
      ),
    );
  }

  @override
  Future<ChatWindowResult> getOlderMessages({
    required String chatId,
    required String? beforeSequence,
  }) async {
    return const ChatWindowResult(
      messages: <Message>[],
      viewportState: ChatViewportState(
        anchorMessageId: null,
        hasMoreBefore: false,
        hasMoreAfter: false,
      ),
    );
  }

  @override
  Future<void> markConversationRead({required String chatId}) async {}

  @override
  Future<LocationSearchResult> searchLocationResult({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  }) async {
    return const LocationSearchResult(
      enabled: true,
      message: '',
      items: <LocationSearchItem>[],
    );
  }

  @override
  Future<void> addFavorite({required String messageId}) async {}

  @override
  Future<void> markVoicePlayed({required String messageId}) async {}

  @override
  Future<void> markVoicePlayedBatch({required List<String> messageIds}) async {}

  @override
  Future<List<String>> getVoicePlayedStatus({
    required String chatId,
    required List<String> messageIds,
  }) async {
    return const <String>[];
  }

  @override
  Future<int> getRecallWindowSeconds() async => 120;

  @override
  Future<void> recallMessage({required String messageId}) async {}

  @override
  Future<void> deleteMessage({required String messageId}) async {}

  @override
  Future<void> clearConversationHistory({required String chatId}) async {}

  @override
  Future<List<ChatMediaItem>> getChatMedia({
    required String chatId,
    String? fileType,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    return const <ChatMediaItem>[];
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
    return const <ChatHistoryItem>[];
  }

  @override
  Future<List<MessageSearchItem>> searchMessages({
    required String keyword,
    String? chatId,
    String? category,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    return const <MessageSearchItem>[];
  }

  @override
  Future<int?> forwardMessages({
    required String targetChatId,
    required List<String> messageIds,
    int forwardType = 1,
    String? comment,
  }) async => null;

  @override
  Future<SendMessageResult> sendTextMessage({
    required String chatId,
    required String text,
    required String clientMessageId,
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  }) async {
    throw UnimplementedError();
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
  }) async {
    throw UnimplementedError();
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
  }) async {
    throw UnimplementedError();
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
  }) async {
    throw UnimplementedError();
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SendMessageResult> sendContactCardMessage({
    required String chatId,
    required ContactCardSharePayload payload,
    required String clientMessageId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SendMessageResult> sendLocationMessage({
    required String chatId,
    required LocationSharePayload payload,
    required String clientMessageId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SendMessageResult> sendStickerMessage({
    required String chatId,
    required StickerPayload payload,
    required String clientMessageId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReadReceiptSummary?> getReadReceiptSummary({
    required String messageId,
  }) async {
    return null;
  }

  @override
  Future<List<ReadReceiptDetailItem>> getReadReceiptDetail({
    required String messageId,
    required String status,
    int pageNo = 1,
    int pageSize = 100,
  }) async {
    return const <ReadReceiptDetailItem>[];
  }

  @override
  Future<List<LocationSearchItem>> searchLocations({
    required String keyword,
    double? latitude,
    double? longitude,
    int pageSize = 20,
  }) async {
    return const <LocationSearchItem>[];
  }
}

Message _message({
  required String messageId,
  String? clientMessageId,
  MessageStatus status = MessageStatus.sending,
  String? sequence,
  MessageType type = MessageType.text,
  String content = 'hello',
  MessageExtra extra = const MessageExtra(),
}) {
  return Message(
    messageId: messageId,
    clientMessageId: clientMessageId,
    chatId: 'chat-1',
    senderId: 'user-1',
    senderName: 'sender',
    type: type,
    status: status,
    content: content,
    sentAt: DateTime.parse('2026-04-30T10:00:00Z'),
    isOutgoing: true,
    sequence: sequence,
    extra: extra,
  );
}
