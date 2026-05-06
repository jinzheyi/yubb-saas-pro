import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/coordinators/conversation_sync_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/load_conversation_list_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/sync_conversations_incrementally_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/datasources/conversation_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/repositories/conversation_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/states/conversation_list_state.dart';

final conversationRemoteDataSourceProvider =
    Provider<ConversationRemoteDataSource>((ref) {
      return ConversationRemoteDataSource(dio: ref.read(dioProvider));
    });

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(
    ref.read(conversationRemoteDataSourceProvider),
  );
});

final loadConversationListUseCaseProvider =
    Provider<LoadConversationListUseCase>((ref) {
      return LoadConversationListUseCase(
        ref.read(conversationRepositoryProvider),
      );
    });

final syncConversationsIncrementallyUseCaseProvider =
    Provider<SyncConversationsIncrementallyUseCase>((ref) {
      return SyncConversationsIncrementallyUseCase(
        ref.read(conversationRepositoryProvider),
      );
    });

final conversationSyncCoordinatorProvider =
    Provider<ConversationSyncCoordinator>((ref) {
      return ConversationSyncCoordinator(
        ref.read(loadConversationListUseCaseProvider),
        ref.read(syncConversationsIncrementallyUseCaseProvider),
      );
    });

final conversationListControllerProvider =
    StateNotifierProvider<ConversationListController, ConversationListState>((
      ref,
    ) {
      return ConversationListController(
        ref.read(conversationSyncCoordinatorProvider),
        ref.read(syncConversationsIncrementallyUseCaseProvider),
        ref.read(conversationRepositoryProvider),
      );
    });
