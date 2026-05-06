import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/core/platform/media_picker_service.dart';
import 'package:shengyu_ui_admin_im/core/platform/picked_file.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/coordinators/chat_upload_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_upload_execution_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/optimistic_message_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_upload_input.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_timeline_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/repositories/group_settings_repository.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';

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
  final MessagePreviewFormatter _messagePreviewFormatter;
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
      upload: (input, onTaskChanged) {
        return _chatUploadCoordinator.uploadImage(
          input: input,
          onTaskChanged: onTaskChanged,
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
      upload: (input, onTaskChanged) {
        return _chatUploadCoordinator.uploadImage(
          input: input,
          onTaskChanged: onTaskChanged,
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
      upload: (input, onTaskChanged) {
        return _chatUploadCoordinator.uploadFile(
          input: input,
          onTaskChanged: onTaskChanged,
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
      upload: (input, onTaskChanged) {
        return _chatUploadCoordinator.uploadVideo(
          input: input,
          onTaskChanged: onTaskChanged,
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
      final result = await _uploadExistingMessage(
        message: failedMessage,
        entryArgs: entryArgs,
        purpose: purpose,
      );
      final merged = result.message.copyWith(
        clientMessageId: retryKey,
        extra: result.message.extra.copyWith(
          localPath: failedMessage.extra.localPath,
          fileUrl: result.message.extra.fileUrl ?? failedMessage.extra.fileUrl,
          thumbnailUrl:
              result.message.extra.thumbnailUrl ??
              failedMessage.extra.thumbnailUrl,
          fileName:
              result.message.extra.fileName ?? failedMessage.extra.fileName,
          fileType:
              result.message.extra.fileType ?? failedMessage.extra.fileType,
          fileSize:
              result.message.extra.fileSize ?? failedMessage.extra.fileSize,
        ),
      );
      _timelineController.replaceSingleMessage(
        clientMessageId: retryKey,
        message: merged,
      );
      _patchConversationForDeliveredMessage(
        clientMessageId: retryKey,
        fallback: merged,
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
      _timelineController.appendSingleMessage(optimisticMessage);
      _patchConversation(
        message: optimisticMessage,
        chatTitle: chatTitle,
        entryArgs: entryArgs,
      );

      final result = await _uploadByPurpose(
        purpose: resolvedPurpose,
        _buildUploadInput(
          purpose: resolvedPurpose,
          scope: _resolveScope(entryArgs),
          path: picked.path,
          displayName: _displayNameForPickedFile(picked, resolvedPurpose),
          mimeType: _mimeTypeForPickedFile(picked, resolvedPurpose),
          fileSize: picked.size,
        ),
        (_) {},
      );
      await _saveGroupFileIfNeeded(entryArgs: entryArgs, picked: picked);

      final merged = result.message.copyWith(
        clientMessageId:
            optimisticMessage.clientMessageId ?? optimisticMessage.messageId,
        extra: result.message.extra.copyWith(
          fileId: result.message.extra.fileId,
          fileUrl:
              result.message.extra.fileUrl ?? optimisticMessage.extra.fileUrl,
          thumbnailUrl:
              result.message.extra.thumbnailUrl ??
              optimisticMessage.extra.thumbnailUrl,
          fileName:
              result.message.extra.fileName ?? optimisticMessage.extra.fileName,
          fileType:
              result.message.extra.fileType ?? optimisticMessage.extra.fileType,
          fileSize:
              result.message.extra.fileSize ?? optimisticMessage.extra.fileSize,
        ),
      );
      _timelineController.replaceSingleMessage(
        clientMessageId:
            optimisticMessage.clientMessageId ?? optimisticMessage.messageId,
        message: merged,
      );
      _patchConversationForDeliveredMessage(
        clientMessageId:
            optimisticMessage.clientMessageId ?? optimisticMessage.messageId,
        fallback: merged,
        chatTitle: chatTitle,
        entryArgs: entryArgs,
      );
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
      _ => UploadScope.directChat(chatId: entryArgs.chatId),
    };
  }

  Future<ChatUploadExecutionResult> _uploadExistingMessage({
    required Message message,
    required ChatEntryArgs entryArgs,
    required UploadPurpose purpose,
  }) {
    final scope = _resolveScope(entryArgs);
    final input = _buildUploadInput(
      purpose: purpose,
      scope: scope,
      path: message.extra.localPath ?? '',
      displayName: _displayNameFor(message),
      mimeType: _mimeTypeFor(message),
      fileSize: message.extra.fileSize ?? 0,
    );
    return switch (purpose) {
      UploadPurpose.chatImage => _chatUploadCoordinator.uploadImage(
        input: input,
        onTaskChanged: (_) {},
      ),
      UploadPurpose.chatVideo => _chatUploadCoordinator.uploadVideo(
        input: input,
        onTaskChanged: (_) {},
      ),
      _ => _chatUploadCoordinator.uploadFile(
        input: input,
        onTaskChanged: (_) {},
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
    void Function(dynamic task) onTaskChanged, {
    required UploadPurpose purpose,
  }) {
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

  ChatUploadInput _buildUploadInput({
    required UploadPurpose purpose,
    required UploadScope scope,
    required String path,
    required String displayName,
    required String mimeType,
    required int fileSize,
  }) {
    return ChatUploadInput(
      purpose: purpose,
      scope: scope,
      localUri: path,
      displayName: displayName,
      mimeType: mimeType,
      fileSize: fileSize,
    );
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

  void _patchConversation({
    required Message message,
    required String chatTitle,
    required ChatEntryArgs entryArgs,
  }) {
    _conversationListController.upsertLocalMessage(
      chatId: message.chatId,
      title: chatTitle,
      conversationType: entryArgs.conversationType,
      messageId: message.messageId,
      messageSequence: message.sequence,
      preview: _messagePreviewFormatter.formatConversationPreview(
        type: message.type,
        content: message.content,
        fileName: message.extra.fileName,
        systemEventKey: message.extra.systemEventKey,
        conversationType: entryArgs.conversationType,
        isSelf: message.isOutgoing,
        senderName: message.senderName,
      ),
      messageType: message.type,
      messageStatus: message.status,
      updatedAt: message.sentAt,
      resetUnread: true,
    );
  }

  void _patchConversationForDeliveredMessage({
    required String clientMessageId,
    required Message fallback,
    required String chatTitle,
    required ChatEntryArgs entryArgs,
  }) {
    final effective =
        _timelineController.findByAnyMessageId(clientMessageId) ?? fallback;
    _patchConversation(
      message: effective,
      chatTitle: chatTitle,
      entryArgs: entryArgs,
    );
  }
}
