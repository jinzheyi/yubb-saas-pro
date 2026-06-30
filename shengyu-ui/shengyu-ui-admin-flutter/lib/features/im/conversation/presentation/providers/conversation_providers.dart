import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/coordinators/conversation_sync_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/load_conversation_list_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/sync_conversations_incrementally_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/datasources/conversation_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/repositories/conversation_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/states/conversation_list_state.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/unified_cache_manager.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/cursor_version_store.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/memory_cache_manager.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/disk_cache_manager.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final currentUserId = ref.read(authSessionProvider).userId;
  return ConversationRepositoryImpl(
    ConversationRemoteDataSource(
      dio: ref.read(dioProvider),
      currentUserId: currentUserId,
    ),
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
      final currentUserId = ref.watch(authSessionProvider).userId;
      return ConversationListController(
        ref.read(conversationSyncCoordinatorProvider),
        ref.read(syncConversationsIncrementallyUseCaseProvider),
        ref.read(conversationRepositoryProvider),
        ref.read(activeConversationServiceProvider.notifier),
        ref.read(unifiedCacheManagerProvider),
        ref.read(cursorVersionStoreProvider),
        currentUserId,
      );
    });

/// 游标版本存储 Provider
final cursorVersionStoreProvider = Provider<CursorVersionStore>((ref) {
  return CursorVersionStore();
});

/// 统一缓存管理器 Provider
final unifiedCacheManagerProvider = Provider<UnifiedCacheManager>((ref) {
  return UnifiedCacheManager(
    memoryCache: MemoryCacheManager(),
    diskCache: DiskCacheManager(),
    cursorVersionStore: ref.watch(cursorVersionStoreProvider),
  );
});

/// 未读消息统计汇总（一次遍历，避免重复计算）
class UnreadCountSummary {
  final int total;
  final int mutedTotal;
  const UnreadCountSummary({required this.total, required this.mutedTotal});
}

final unreadCountSummaryProvider = Provider<UnreadCountSummary>((ref) {
  // 精确订阅：仅监听 conversations 字段变化
  final conversations = ref.watch(conversationListControllerProvider.select((state) => state.conversations));
  int total = 0;
  int mutedTotal = 0;
  for (final c in conversations) {
    total += c.unreadCount;
    if (c.isMuted) mutedTotal += c.unreadCount;
  }
  return UnreadCountSummary(total: total, mutedTotal: mutedTotal);
});

/// @deprecated 使用 unreadCountSummaryProvider 替代
@Deprecated('Use unreadCountSummaryProvider instead')
final totalUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountSummaryProvider).total;
});

/// @deprecated 使用 unreadCountSummaryProvider 替代
@Deprecated('Use unreadCountSummaryProvider instead')
final totalMutedUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountSummaryProvider).mutedTotal;
});
