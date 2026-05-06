import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:shengyu_ui_admin_im/core/platform/audio_playback_service.dart';
import 'package:shengyu_ui_admin_im/core/platform/audio_recording_service.dart';
import 'package:shengyu_ui_admin_im/core/platform/media_picker_service.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/coordinators/chat_upload_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/chat_location_opener_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/optimistic_message_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/reedit_hint_local_store.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_chat_window_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_older_messages_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/mark_conversation_read_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/open_chat_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_uploaded_message_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_message_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/upload_chat_asset_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/sticker_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/file_http_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/message_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/sticker_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/repositories/file_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/repositories/message_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/repositories/sticker_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_composer_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_message_action_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_media_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_more_panel_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_receipt_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_timeline_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_page_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_timeline_state.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';

class ChatRuntimeNotice {
  const ChatRuntimeNotice({
    required this.chatId,
    required this.message,
    this.code,
    this.redirectToConversations = false,
    required this.token,
  });

  final String chatId;
  final String message;
  final String? code;
  final bool redirectToConversations;
  final int token;
}

class ChatRealtimeSignal {
  const ChatRealtimeSignal({
    required this.chatId,
    required this.action,
    this.payload = const <String, Object?>{},
    required this.token,
  });

  final String chatId;
  final String action;
  final Map<String, Object?> payload;
  final int token;
}

final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((
  ref,
) {
  return MessageRemoteDataSource(dio: ref.read(dioProvider));
});

final fileHttpDataSourceProvider = Provider<FileHttpDataSource>((ref) {
  return FileHttpDataSource(dio: ref.read(dioProvider));
});

final stickerRemoteDataSourceProvider = Provider<StickerRemoteDataSource>((
  ref,
) {
  return StickerRemoteDataSource(dio: ref.read(dioProvider));
});

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return const FilePickerMediaPickerService();
});

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final chatLocationOpenerServiceProvider = Provider<ChatLocationOpenerService>((
  ref,
) {
  return const UrlLauncherChatLocationOpenerService();
});

final reeditHintLocalStoreProvider = Provider<ReeditHintLocalStore>((ref) {
  return const ReeditHintLocalStore(StorageKeyRegistry.reeditHintPrefix);
});

final chatRuntimeNoticeProvider = StateProvider<ChatRuntimeNotice?>((ref) {
  return null;
});

final chatRealtimeSignalProvider = StateProvider<ChatRealtimeSignal?>((ref) {
  return null;
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(ref.read(messageRemoteDataSourceProvider));
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(ref.read(fileHttpDataSourceProvider));
});

final stickerRepositoryProvider = Provider<StickerRepository>((ref) {
  return StickerRepositoryImpl(ref.read(stickerRemoteDataSourceProvider));
});

final loadChatWindowUseCaseProvider = Provider<LoadChatWindowUseCase>((ref) {
  return LoadChatWindowUseCase(ref.read(messageRepositoryProvider));
});

final loadOlderMessagesUseCaseProvider = Provider<LoadOlderMessagesUseCase>((
  ref,
) {
  return LoadOlderMessagesUseCase(ref.read(messageRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(messageRepositoryProvider));
});

final uploadChatAssetUseCaseProvider = Provider<UploadChatAssetUseCase>((ref) {
  return UploadChatAssetUseCase(ref.read(fileRepositoryProvider));
});

final sendUploadedMessageUseCaseProvider = Provider<SendUploadedMessageUseCase>(
  (ref) {
    return SendUploadedMessageUseCase(ref.read(messageRepositoryProvider));
  },
);

final markConversationReadUseCaseProvider =
    Provider<MarkConversationReadUseCase>((ref) {
      return MarkConversationReadUseCase(ref.read(messageRepositoryProvider));
    });

final openChatUseCaseProvider = Provider<OpenChatUseCase>((ref) {
  return OpenChatUseCase(
    ref.read(messageRepositoryProvider),
    ref.read(conversationRepositoryProvider),
  );
});

final chatUploadCoordinatorProvider = Provider<ChatUploadCoordinator>((ref) {
  return ChatUploadCoordinator(
    ref.read(uploadChatAssetUseCaseProvider),
    ref.read(sendUploadedMessageUseCaseProvider),
    const Uuid(),
  );
});

final chatMediaControllerProvider =
    StateNotifierProvider.autoDispose<ChatMediaController, ChatMediaState>((
      ref,
    ) {
      return ChatMediaController(
        ref.read(mediaPickerServiceProvider),
        ref.read(chatUploadCoordinatorProvider),
        ref.read(optimisticMessageFactoryProvider),
        ref.read(messagePreviewFormatterProvider),
        ref.read(conversationListControllerProvider.notifier),
        ref.read(chatTimelineControllerProvider.notifier),
        ref.read(groupSettingsRepositoryProvider),
      );
    });

final chatReceiptControllerProvider = Provider<ChatReceiptController>((ref) {
  return ChatReceiptController();
});

final chatMorePanelControllerProvider =
    Provider.autoDispose<ChatMorePanelController>((ref) {
      return ChatMorePanelController(
        ref.read(chatMediaControllerProvider.notifier),
      );
    });

final chatMessageActionControllerProvider =
    Provider<ChatMessageActionController>((ref) {
      return ChatMessageActionController(
        ref.read(messageRepositoryProvider),
        ref.read(chatTimelineControllerProvider.notifier),
      );
    });

final chatComposerControllerProvider =
    Provider.autoDispose<ChatComposerController>((ref) {
      final controller = ChatComposerController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final chatTimelineControllerProvider =
    StateNotifierProvider<ChatTimelineController, ChatTimelineState>((ref) {
      return ChatTimelineController(
        ref.read(loadChatWindowUseCaseProvider),
        ref.read(loadOlderMessagesUseCaseProvider),
      );
    });

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatPageState>((ref) {
      return ChatController(
        ref.read(openChatUseCaseProvider),
        ref.read(sendMessageUseCaseProvider),
        ref.read(markConversationReadUseCaseProvider),
        ref.read(optimisticMessageFactoryProvider),
        ref.read(messagePreviewFormatterProvider),
        ref.read(conversationListControllerProvider.notifier),
        ref.read(chatTimelineControllerProvider.notifier),
        ref.read(chatReceiptControllerProvider),
      );
    });
