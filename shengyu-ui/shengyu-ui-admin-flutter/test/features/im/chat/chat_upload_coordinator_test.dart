import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/coordinators/chat_upload_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_uploaded_message_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/upload_chat_asset_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_upload_input.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_media_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_detail_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task_status.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/uploaded_file.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';
import 'package:shengyu_ui_admin_im/features/im/search/domain/entities/message_search_item.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('uploadImage emits stable task state transitions', () async {
    final coordinator = ChatUploadCoordinator(
      UploadChatAssetUseCase(_FakeFileRepository()),
      SendUploadedMessageUseCase(_FakeMessageRepository()),
      const Uuid(),
    );
    final events = <UploadTask>[];

    final result = await coordinator.uploadImage(
      input: const ChatUploadInput(
        purpose: UploadPurpose.chatImage,
        scope: UploadScope.directChat(chatId: 'chat-1'),
        localUri: '/tmp/image.png',
        displayName: 'image.png',
        mimeType: 'image/png',
        fileSize: 1024,
      ),
      onTaskChanged: events.add,
      width: 200,
      height: 100,
    );

    expect(events.map((e) => e.status), <UploadTaskStatus>[
      UploadTaskStatus.queued,
      UploadTaskStatus.preparing,
      UploadTaskStatus.uploading,
      UploadTaskStatus.uploaded,
      UploadTaskStatus.sending,
      UploadTaskStatus.sent,
    ]);
    expect(result.task.uploadedFileId, 'f-1');
    expect(result.task.progress, 100);
    expect(result.message.clientMessageId, isNotEmpty);
  });
}

class _FakeFileRepository implements FileRepository {
  @override
  Future<FilePreviewDescriptor> getFilePreviewDescriptor(
    FilePreviewArgs args,
  ) async {
    return FilePreviewDescriptor(
      fileId: args.fileId,
      fileName: args.fileName,
      mimeType: args.mimeType,
      extension: 'png',
      fileSize: args.fileSize,
      renderStrategy: FileRenderStrategy.nativeImage,
      previewUrl: 'https://example.com/f-1.png',
    );
  }

  @override
  Future<Uri> getPresignedGetUrl({
    required String fileId,
    int expirationSeconds = 600,
  }) async {
    return Uri.parse('https://example.com/$fileId');
  }

  @override
  Future<UploadResult> uploadAndCreateFile({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
  }) async {
    return UploadResult(
      taskId: taskId,
      purpose: purpose,
      scope: scope,
      file: const UploadedFile(
        fileId: 'f-1',
        url: 'https://example.com/f-1.png',
        name: 'image.png',
        size: 1024,
        mimeType: 'image/png',
        md5: 'md5-1',
      ),
    );
  }
}

class _FakeMessageRepository implements MessageRepository {
  @override
  Future<Message> getMessageDetail({required String messageId}) {
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
    return SendMessageResult(
      message: _message(
        clientMessageId: clientMessageId,
        type: MessageType.file,
      ),
    );
  }

  @override
  Future<ChatWindowResult> getMessageWindow(dynamic command) {
    throw UnimplementedError();
  }

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
  Future<ChatWindowResult> getOlderMessages({
    required String chatId,
    required String? beforeSequence,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markConversationRead({required String chatId}) async {}

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
    return SendMessageResult(
      message: _message(
        clientMessageId: clientMessageId,
        type: MessageType.image,
      ),
    );
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
    return SendMessageResult(
      message: _message(
        clientMessageId: clientMessageId,
        type: MessageType.video,
      ),
    );
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
    return SendMessageResult(
      message: _message(
        clientMessageId: clientMessageId,
        type: MessageType.voice,
      ),
    );
  }

  @override
  Future<SendMessageResult> sendTextMessage({
    required String chatId,
    required String text,
    required String clientMessageId,
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  }) {
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
    return SendMessageResult(
      message: _message(
        clientMessageId: clientMessageId,
        type: MessageType.sticker,
      ),
    );
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

  Message _message({
    required String clientMessageId,
    required MessageType type,
  }) {
    return Message(
      messageId: clientMessageId,
      chatId: 'chat-1',
      senderId: 'u-1',
      senderName: 'tester',
      type: type,
      status: MessageStatus.sent,
      content: '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(0),
      isOutgoing: true,
      clientMessageId: clientMessageId,
    );
  }
}
