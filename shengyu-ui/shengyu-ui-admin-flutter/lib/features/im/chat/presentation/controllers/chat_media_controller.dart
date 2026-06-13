import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/core/platform/local_uri_bytes_loader.dart';
import 'package:shengyu_ui_admin_im/core/platform/media_picker_service.dart';
import 'package:shengyu_ui_admin_im/core/platform/picked_file.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/coordinators/chat_upload_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_upload_execution_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/optimistic_message_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_upload_input.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_timeline_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/repositories/group_settings_repository.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart'
    show ConversationPreviewFormatter;

class ChatMediaController extends StateNotifier<ChatMediaState> {
  ChatMediaController(
    this._mediaPickerService,
    this._chatUploadCoordinator,
    this._optimisticMessageFactory,
    this._messagePreviewFormatter,
    this._conversationListController,
    this._timelineController,
    this._groupSettingsRepository,
  ) : super(const ChatMediaState());

  final MediaPickerService _mediaPickerService;
  final ChatUploadCoordinator _chatUploadCoordinator;
  final OptimisticMessageFactory _optimisticMessageFactory;
  final ConversationPreviewFormatter _messagePreviewFormatter;
  final ConversationListController _conversationListController;
  final ChatTimelineController _timelineController;
  final GroupSettingsRepository _groupSettingsRepository;

  Future<void> pickAndUploadImage({
    required ChatEntryArgs entryArgs,
    required String chatTitle,
  }) {
    return _pickAndUpload(
      entryArgs: entryArgs,
      chatTitle: chatTitle,
      picker: _mediaPickerService.pickImage,
      purpose: UploadPurpose.chatImage,
      upload: (input, onTaskChanged, clientMessageId) {
        return _chatUploadCoordinator.uploadImage(
          input: input,
          onTaskChanged: onTaskChanged,
          clientMessageId: clientMessageId,
        );
      },
    );
  }

  Future<void> captureAndUploadImage({
    required ChatEntryArgs entryArgs,
    required String chatTitle,
  }) {
    return _pickAndUpload(
      entryArgs: entryArgs,
      chatTitle: chatTitle,
      picker: _mediaPickerService.captureImage,
      purpose: UploadPurpose.chatImage,
      upload: (input, onTaskChanged, clientMessageId) {
        return _chatUploadCoordinator.uploadImage(
          input: input,
          onTaskChanged: onTaskChanged,
          clientMessageId: clientMessageId,
        );
      },
    );
  }

  Future<void> pickAndUploadFile({
    required ChatEntryArgs entryArgs,
    required String chatTitle,
  }) {
    return _pickAndUpload(
      entryArgs: entryArgs,
      chatTitle: chatTitle,
      picker: _mediaPickerService.pickFile,
      purpose: UploadPurpose.chatFile,
      upload: (input, onTaskChanged, clientMessageId) {
        return _chatUploadCoordinator.uploadFile(
          input: input,
          onTaskChanged: onTaskChanged,
          clientMessageId: clientMessageId,
        );
      },
    );
  }

  Future<void> pickAndUploadVideo({
    required ChatEntryArgs entryArgs,
    required String chatTitle,
  }) {
    return _pickAndUpload(
      entryArgs: entryArgs,
      chatTitle: chatTitle,
      picker: _mediaPickerService.pickVideo,
      purpose: UploadPurpose.chatVideo,
      upload: (input, onTaskChanged, clientMessageId) {
        return _chatUploadCoordinator.uploadVideo(
          input: input,
          onTaskChanged: onTaskChanged,
          clientMessageId: clientMessageId,
        );
      },
    );
  }

  Future<bool> retryFailedMessage({
    required Message failedMessage,
    required ChatEntryArgs entryArgs,
    required String chatTitle,
  }) async {
    if (failedMessage.status != MessageStatus.failed) {
      return false;
    }
    final localPath = failedMessage.extra.localPath;
    if (localPath == null || localPath.isEmpty) {
      return false;
    }

    final purpose = switch (failedMessage.type) {
      MessageType.image => UploadPurpose.chatImage,
      MessageType.video => UploadPurpose.chatVideo,
      MessageType.file => UploadPurpose.chatFile,
      _ => null,
    };
    if (purpose == null) {
      return false;
    }

    final retryKey = failedMessage.clientMessageId ?? failedMessage.messageId;
    _timelineController.markSendingByClientMessageId(clientMessageId: retryKey);
    _patchConversation(
      message: failedMessage.copyWith(status: MessageStatus.sending),
      chatTitle: chatTitle,
      entryArgs: entryArgs,
    );

    state = state.copyWith(isPicking: true, error: null);
    try {
      final execution = await _uploadExistingMessage(
        message: failedMessage,
        entryArgs: entryArgs,
        purpose: purpose,
        onTaskChanged: (task) =>
            _applyUploadTaskToLocalMessage(retryKey, failedMessage, task),
      );
      final resolvedMessage = _resolveUploadedMessage(
        base: failedMessage,
        incoming: execution.message,
        uploadedFileId: execution.task.uploadedFileId,
        uploadedUrl: execution.task.uploadedUrl,
        checksum: execution.task.checksum,
      );
      _timelineController.replaceSingleMessage(
        clientMessageId: retryKey,
        message: resolvedMessage,
      );
      _patchConversation(
        message: resolvedMessage,
        chatTitle: chatTitle,
        entryArgs: entryArgs,
      );
      state = state.copyWith(isPicking: false, error: null);
      return true;
    } catch (error, stackTrace) {
      _timelineController.markFailedByClientMessageId(
        clientMessageId: retryKey,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: failedMessage.chatId,
        messageId: retryKey,
        status: MessageStatus.failed,
      );
      state = state.copyWith(
        isPicking: false,
        error: AppErrorMapper.map(error, stackTrace),
      );
      return false;
    }
  }

  Future<void> _pickAndUpload({
    required ChatEntryArgs entryArgs,
    required String chatTitle,
    required Future<PickedFile?> Function() picker,
    required UploadPurpose purpose,
    required Future<ChatUploadExecutionResult> Function(
      ChatUploadInput input,
      void Function(dynamic task) onTaskChanged,
      String? clientMessageId,
    )
    upload,
  }) async {
    state = state.copyWith(isPicking: true, error: null);
    Message? optimisticMessage;
    try {
      final picked = await picker();
      if (picked == null) {
        state = state.copyWith(isPicking: false, error: null);
        return;
      }

      final resolvedPurpose = _resolveUploadPurpose(picked, fallback: purpose);
      optimisticMessage = _createOptimisticMessage(
        chatId: entryArgs.chatId,
        picked: picked,
        purpose: resolvedPurpose,
      );
      final localOptimisticMessage = optimisticMessage;
      final optimisticKey =
          localOptimisticMessage.clientMessageId ??
          localOptimisticMessage.messageId;
      _timelineController.appendSingleMessage(localOptimisticMessage);
      _patchConversation(
        message: localOptimisticMessage,
        chatTitle: chatTitle,
        entryArgs: entryArgs,
      );

      final execution = await _uploadByPurpose(
        purpose: resolvedPurpose,
        _buildUploadInput(
          purpose: resolvedPurpose,
          scope: _resolveScope(entryArgs),
          path: picked.path,
          displayName: _displayNameForPickedFile(picked, resolvedPurpose),
          mimeType: _mimeTypeForPickedFile(picked, resolvedPurpose),
          fileSize: picked.size,
          bytes: picked.bytes,
        ),
        (task) => _applyUploadTaskToLocalMessage(
          optimisticKey,
          localOptimisticMessage,
          task,
        ),
        optimisticKey,
      );
      final resolvedMessage = _resolveUploadedMessage(
        base: localOptimisticMessage,
        incoming: execution.message,
        uploadedFileId: execution.task.uploadedFileId,
        uploadedUrl: execution.task.uploadedUrl,
        checksum: execution.task.checksum,
      );
      _timelineController.replaceSingleMessage(
        clientMessageId: optimisticKey,
        message: resolvedMessage,
      );
      _patchConversation(
        message: resolvedMessage,
        chatTitle: chatTitle,
        entryArgs: entryArgs,
      );
      await _saveGroupFileIfNeeded(entryArgs: entryArgs, picked: picked);
      state = state.copyWith(isPicking: false, error: null);
    } catch (error, stackTrace) {
      if (optimisticMessage != null) {
        final retryKey =
            optimisticMessage.clientMessageId ?? optimisticMessage.messageId;
        _timelineController.markFailedByClientMessageId(
          clientMessageId: retryKey,
        );
        _conversationListController.patchLastMessageStatus(
          chatId: optimisticMessage.chatId,
          messageId: retryKey,
          status: MessageStatus.failed,
        );
      }
      state = state.copyWith(
        isPicking: false,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  Message _createOptimisticMessage({
    required String chatId,
    required PickedFile picked,
    required UploadPurpose purpose,
  }) {
    return switch (purpose) {
      UploadPurpose.chatImage => _optimisticMessageFactory.createImage(
        chatId: chatId,
        fileName: picked.name,
        fileSize: picked.size,
        mimeType: picked.mimeType,
        localPath: picked.path,
      ),
      UploadPurpose.chatVideo => _optimisticMessageFactory.createVideo(
        chatId: chatId,
        fileName: picked.name,
        fileSize: picked.size,
        mimeType: picked.mimeType,
        localPath: picked.path,
      ),
      _ => _optimisticMessageFactory.createFile(
        chatId: chatId,
        fileName: picked.name,
        fileSize: picked.size,
        mimeType: picked.mimeType,
        localPath: picked.path,
      ),
    };
  }

  UploadScope _resolveScope(ChatEntryArgs entryArgs) {
    return switch (entryArgs.conversationType) {
      ConversationType.group => UploadScope.groupChat(
        groupId: entryArgs.targetId ?? entryArgs.chatId,
        chatId: entryArgs.chatId,
      ),
      _ => UploadScope.directChat(
        chatId: entryArgs.chatId,
        targetUserId: entryArgs.targetId ?? '',
      ),
    };
  }

  Future<ChatUploadExecutionResult> _uploadExistingMessage({
    required Message message,
    required ChatEntryArgs entryArgs,
    required UploadPurpose purpose,
    required void Function(dynamic task) onTaskChanged,
  }) async {
    final scope = _resolveScope(entryArgs);
    final retryBytes = await _resolveRetryBytes(message.extra.localPath);
    final input = _buildUploadInput(
      purpose: purpose,
      scope: scope,
      path: message.extra.localPath ?? '',
      displayName: _displayNameFor(message),
      mimeType: _mimeTypeFor(message),
      fileSize: message.extra.fileSize ?? 0,
      bytes: retryBytes,
    );
    return switch (purpose) {
      UploadPurpose.chatImage => _chatUploadCoordinator.uploadImage(
        input: input,
        onTaskChanged: onTaskChanged,
      ),
      UploadPurpose.chatVideo => _chatUploadCoordinator.uploadVideo(
        input: input,
        onTaskChanged: onTaskChanged,
      ),
      _ => _chatUploadCoordinator.uploadFile(
        input: input,
        onTaskChanged: onTaskChanged,
      ),
    };
  }

  Future<void> _saveGroupFileIfNeeded({
    required ChatEntryArgs entryArgs,
    required PickedFile picked,
  }) async {
    if (entryArgs.conversationType != ConversationType.group) {
      return;
    }
    final groupId = entryArgs.targetId ?? entryArgs.chatId;
    if (groupId.isEmpty) {
      return;
    }
    try {
      await _groupSettingsRepository.uploadGroupFile(
        groupId: groupId,
        filePath: picked.path,
        fileName: picked.name,
      );
    } catch (_) {
      // 老项目这里是附加链路，失败不影响消息发送。
    }
  }

  UploadPurpose _resolveUploadPurpose(
    PickedFile picked, {
    required UploadPurpose fallback,
  }) {
    final mimeType = picked.mimeType.toLowerCase();
    final name = picked.name.toLowerCase();
    if (fallback == UploadPurpose.chatFile &&
        (mimeType.startsWith('video/') ||
            name.endsWith('.mp4') ||
            name.endsWith('.mov') ||
            name.endsWith('.m4v') ||
            name.endsWith('.avi') ||
            name.endsWith('.mkv') ||
            name.endsWith('.webm'))) {
      return UploadPurpose.chatVideo;
    }
    return fallback;
  }

  Future<ChatUploadExecutionResult> _uploadByPurpose(
    ChatUploadInput input,
    void Function(dynamic task) onTaskChanged,
    String? clientMessageId, {
    required UploadPurpose purpose,
  }) {
    return switch (purpose) {
      UploadPurpose.chatImage => _chatUploadCoordinator.uploadImage(
        input: input,
        onTaskChanged: onTaskChanged,
        clientMessageId: clientMessageId,
      ),
      UploadPurpose.chatVideo => _chatUploadCoordinator.uploadVideo(
        input: input,
        onTaskChanged: onTaskChanged,
        clientMessageId: clientMessageId,
      ),
      _ => _chatUploadCoordinator.uploadFile(
        input: input,
        onTaskChanged: onTaskChanged,
        clientMessageId: clientMessageId,
      ),
    };
  }

  ChatUploadInput _buildUploadInput({
    required UploadPurpose purpose,
    required UploadScope scope,
    required String path,
    required String displayName,
    required String mimeType,
    required int fileSize,
    Uint8List? bytes,
  }) {
    return ChatUploadInput(
      purpose: purpose,
      scope: scope,
      localUri: path,
      displayName: displayName,
      mimeType: mimeType,
      fileSize: fileSize,
      bytes: bytes,
    );
  }

  Future<Uint8List?> _resolveRetryBytes(String? localPath) async {
    final normalized = localPath?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (!normalized.startsWith('blob:') && !normalized.startsWith('data:')) {
      return null;
    }
    try {
      return await loadLocalUriBytes(normalized);
    } catch (_) {
      return null;
    }
  }

  String _displayNameFor(Message message) {
    final fileName = message.extra.fileName?.trim() ?? '';
    if (fileName.isNotEmpty) {
      return fileName;
    }
    final content = message.content.trim();
    if (content.isNotEmpty) {
      return content;
    }
    return message.type == MessageType.image ? 'image' : 'file';
  }

  String _mimeTypeFor(Message message) {
    final mimeType = message.extra.fileType?.trim() ?? '';
    if (mimeType.isNotEmpty) {
      return mimeType;
    }
    final fileName = _displayNameFor(message).toLowerCase();
    if (message.type == MessageType.image ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.webp') ||
        fileName.endsWith('.gif')) {
      return 'image/*';
    }
    if (fileName.endsWith('.mp4') ||
        fileName.endsWith('.mov') ||
        fileName.endsWith('.m4v') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mkv') ||
        fileName.endsWith('.webm')) {
      return 'video/*';
    }
    return 'application/octet-stream';
  }

  String _displayNameForPickedFile(PickedFile picked, UploadPurpose purpose) {
    final name = picked.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return switch (purpose) {
      UploadPurpose.chatImage => 'image',
      UploadPurpose.chatVideo => 'video',
      _ => 'file',
    };
  }

  String _mimeTypeForPickedFile(PickedFile picked, UploadPurpose purpose) {
    final mimeType = picked.mimeType.trim();
    if (mimeType.isNotEmpty) {
      return mimeType;
    }
    final fileName = _displayNameForPickedFile(picked, purpose).toLowerCase();
    if (purpose == UploadPurpose.chatImage ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.webp') ||
        fileName.endsWith('.gif')) {
      return 'image/*';
    }
    if (purpose == UploadPurpose.chatVideo ||
        fileName.endsWith('.mp4') ||
        fileName.endsWith('.mov') ||
        fileName.endsWith('.m4v') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mkv') ||
        fileName.endsWith('.webm')) {
      return 'video/*';
    }
    return 'application/octet-stream';
  }

  Message _resolveUploadedMessage({
    required Message base,
    required Message incoming,
    String? uploadedFileId,
    String? uploadedUrl,
    String? checksum,
  }) {
    final resolvedStatus = incoming.status == MessageStatus.sending
        ? MessageStatus.sent
        : incoming.status;
    final resolvedContent = incoming.content.trim().isNotEmpty
        ? incoming.content
        : (uploadedUrl?.trim().isNotEmpty == true
              ? uploadedUrl!.trim()
              : base.content);
    final fallbackThumbnailUrl = base.type == MessageType.video
        ? base.extra.thumbnailUrl
        : uploadedUrl;
    return incoming.copyWith(
      chatId: incoming.chatId.isNotEmpty ? incoming.chatId : base.chatId,
      senderId: incoming.senderId.isNotEmpty
          ? incoming.senderId
          : base.senderId,
      senderName: incoming.senderName.isNotEmpty
          ? incoming.senderName
          : base.senderName,
      sentAt: incoming.sentAt.millisecondsSinceEpoch > 0
          ? incoming.sentAt
          : base.sentAt,
      isOutgoing: incoming.isOutgoing || base.isOutgoing,
      clientMessageId: incoming.clientMessageId ?? base.clientMessageId,
      status: resolvedStatus,
      content: resolvedContent,
      extra: base.extra.copyWith(
        fileId: incoming.extra.fileId?.trim().isNotEmpty == true
            ? incoming.extra.fileId
            : uploadedFileId,
        fileUrl: incoming.extra.fileUrl?.trim().isNotEmpty == true
            ? incoming.extra.fileUrl
            : uploadedUrl,
        thumbFileId: incoming.extra.thumbFileId?.trim().isNotEmpty == true
            ? incoming.extra.thumbFileId
            : base.extra.thumbFileId,
        thumbnailUrl: incoming.extra.thumbnailUrl?.trim().isNotEmpty == true
            ? incoming.extra.thumbnailUrl
            : fallbackThumbnailUrl,
        md5: incoming.extra.md5?.trim().isNotEmpty == true
            ? incoming.extra.md5
            : checksum,
        fileName: incoming.extra.fileName?.trim().isNotEmpty == true
            ? incoming.extra.fileName
            : base.extra.fileName,
        fileType: incoming.extra.fileType?.trim().isNotEmpty == true
            ? incoming.extra.fileType
            : base.extra.fileType,
        fileSize: (incoming.extra.fileSize ?? 0) > 0
            ? incoming.extra.fileSize
            : base.extra.fileSize,
        width: (incoming.extra.width ?? 0) > 0
            ? incoming.extra.width
            : base.extra.width,
        height: (incoming.extra.height ?? 0) > 0
            ? incoming.extra.height
            : base.extra.height,
      ),
    );
  }

  void _applyUploadTaskToLocalMessage(
    String clientMessageId,
    Message fallbackMessage,
    UploadTask task,
  ) {
    if (clientMessageId.trim().isEmpty) {
      return;
    }
    final uploadedFileId = task.uploadedFileId?.toString().trim() ?? '';
    final uploadedUrl = task.uploadedUrl?.toString().trim() ?? '';
    final checksum = task.checksum?.toString().trim() ?? '';
    if (uploadedFileId.isEmpty && uploadedUrl.isEmpty && checksum.isEmpty) {
      return;
    }
    final current =
        _timelineController.findByAnyMessageId(clientMessageId) ??
        fallbackMessage;
    final currentContent = current.content.trim();
    final nextContent =
        uploadedUrl.isNotEmpty && currentContent.startsWith('blob:')
        ? uploadedUrl
        : current.content;
    final nextThumbnailUrl = current.type == MessageType.video
        ? current.extra.thumbnailUrl
        : (uploadedUrl.isNotEmpty ? uploadedUrl : current.extra.thumbnailUrl);
    _timelineController.replaceSingleMessage(
      clientMessageId: clientMessageId,
      message: current.copyWith(
        content: nextContent,
        extra: current.extra.copyWith(
          fileId: uploadedFileId.isNotEmpty
              ? uploadedFileId
              : current.extra.fileId,
          fileUrl: uploadedUrl.isNotEmpty ? uploadedUrl : current.extra.fileUrl,
          thumbFileId: current.extra.thumbFileId,
          thumbnailUrl: nextThumbnailUrl,
          md5: checksum.isNotEmpty ? checksum : current.extra.md5,
        ),
      ),
    );
  }

  void _patchConversation({
    required Message message,
    required String chatTitle,
    required ChatEntryArgs entryArgs,
  }) {
    _conversationListController.upsertLocalMessage(
      chatId: message.chatId,
      title: chatTitle,
      conversationType: entryArgs.conversationType,
      targetId: entryArgs.targetId,
      messageId: message.messageId,
      messageSequence: message.sequence,
      preview: _messagePreviewFormatter(
        type: message.type,
        content: message.content,
        customType: message.extra.customType,
        fileName: message.extra.fileName,
        systemEventKey: message.extra.systemEventKey,
        conversationType: entryArgs.conversationType,
        isSelf: message.isOutgoing,
        senderName: message.senderName,
      ),
      messageType: message.type,
      senderName: message.senderName,
      isSelf: message.isOutgoing,
      customType: message.extra.customType,
      fileName: message.extra.fileName,
      systemEventKey: message.extra.systemEventKey,
      messageStatus: message.status,
      updatedAt: message.sentAt,
      resetUnread: true,
    );
  }
}
