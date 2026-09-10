import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/message_cache_queue_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/read_receipt_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/upload_progress_tracker.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/device/presentation/providers/device_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/providers/favorite_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/services/tenant_switch_service.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/features/update/presentation/providers/update_providers.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/conversation_preview_cache.dart';

/// 会话清理服务
///
/// 职责：
/// 1. 监听 authSessionProvider 变化，当用户切换时自动清理所有业务缓存
/// 2. 提供手动清理接口供 Profile 页面登出按钮调用
/// 3. 确保切换用户后所有 FutureProvider/StateNotifierProvider 都被 invalidate
///
/// 清理顺序说明：
/// - 先清理所有业务 controller（会话、个人资料、通讯录等）
/// - 再清理 realtime binding（触发 WebSocket 订阅重建）
/// - 最后重置 badge 状态
///
/// 修复说明：
/// - 使用 previous.userId 而非内部 _lastUserId 判断，避免登出后登录无法触发清理
/// - 只要 previous 和 next 的 userId 不同，就执行清理
final sessionCleanupServiceProvider = Provider<SessionCleanupService>((ref) {
  final service = SessionCleanupService(ref);
  ref.listen<AuthSession>(authSessionProvider, (previous, next) {
    service._onSessionChanged(previous, next);
  });
  return service;
});

class SessionCleanupService {
  SessionCleanupService(this._ref);

  final Ref _ref;

  void _onSessionChanged(AuthSession? previous, AuthSession next) {
    // 关键修复：使用 previous.userId 而非内部状态
    final previousUserId = previous?.userId ?? '';
    final currentUserId = next.userId;

    // 用户未变化，无需清理
    if (previousUserId == currentUserId) {
      return;
    }

    // 只要 userId 发生变化（包括登出→登录、用户A→用户B），都执行清理
    _clearAllUserScopes(previousUserId);
  }

  void _clearAllUserScopes([String? previousUserId]) {
    // ========== Phase 6.1: 清空内存缓存 ==========
    // 在 invalidate providers 之前，先清空旧用户的内存缓存
    // 这样可以确保下次登录时不会显示旧用户的缓存数据
    if (previousUserId != null && previousUserId.isNotEmpty) {
      try {
        final cacheManager = _ref.read(unifiedCacheManagerProvider);
        cacheManager.clearMemoryCacheForUser(previousUserId);
      } catch (e) {
        // 静默失败，不影响主流程
      }
    }
    // ========== Phase 6.1 结束 ==========

    // 离线消息队列是进程单例。账号切换后必须取消旧账号待发消息，
    // 不能在网络恢复时携带新 Token 重试旧账号业务。
    try {
      _ref.read(messageCacheQueueProvider).dispose();
    } catch (_) {
      // 队列尚未初始化时无需处理。
    }
    _ref.read(activeConversationServiceProvider.notifier).deactivateChat();
    clearChatRealtimeEphemeralState();
    clearConversationRealtimeEphemeralState();
    ConversationPreviewCache.instance.evictAll();

    // 会话数据源会在创建时读取当前用户编号，因此要先重建其依赖图。
    _ref.invalidate(conversationRepositoryProvider);
    _ref.invalidate(loadConversationListUseCaseProvider);
    _ref.invalidate(syncConversationsIncrementallyUseCaseProvider);
    _ref.invalidate(conversationSyncCoordinatorProvider);
    _ref.invalidate(currentUserProfileProvider);
    _ref.invalidate(avatarUploadStateProvider);
    _ref.invalidate(conversationListControllerProvider);
    // family-scoped provider 需要 invalidate 整个 family
    _ref.invalidate(chatControllerProvider);
    _ref.invalidate(chatTimelineControllerProvider);
    _ref.invalidate(chatMediaControllerProvider);
    _ref.invalidate(chatMessageActionControllerProvider);
    _ref.invalidate(chatComposerControllerProvider);
    _ref.invalidate(chatRuntimeNoticeProvider);
    _ref.invalidate(chatRealtimeSignalProvider);
    _ref.invalidate(chatReceiptLastVisibleChatIdProvider);
    _ref.invalidate(uploadProgressTrackerProvider);
    _ref.invalidate(readReceiptSummaryStoreProvider);
    _ref.invalidate(readReceiptControllerProvider);
    _ref.invalidate(messageCacheQueueProvider);
    _ref.invalidate(messageCacheQueueInitBindingProvider);
    _ref.invalidate(contactsPageControllerProvider);
    _ref.invalidate(contactsRemoteDataSourceProvider);
    _ref.invalidate(contactsRepositoryProvider);
    _ref.invalidate(contactProfileProvider);
    _ref.invalidate(myDepartmentTreeProvider);
    _ref.invalidate(organizationTreeProvider);
    _ref.invalidate(departmentMembersProvider);
    _ref.invalidate(starContactsProvider);
    _ref.invalidate(myGroupsProvider);
    _ref.invalidate(contactSearchProvider);
    _ref.invalidate(directConversationProvider);
    _ref.invalidate(contactSelectionControllerProvider);
    _ref.invalidate(favoritesControllerProvider);
    _ref.invalidate(deviceListProvider);
    _ref.invalidate(groupSettingsRepositoryProvider);
    _ref.invalidate(groupSettingsRemoteDataSourceProvider);
    _ref.invalidate(groupSettingsControllerProvider);
    _ref.invalidate(groupMembersControllerProvider);
    _ref.invalidate(groupMembersFutureProvider);
    _ref.invalidate(groupJoinRequestSignalProvider);
    _ref.invalidate(groupMemberRealtimeSignalProvider);
    _ref.invalidate(groupSettingsRealtimeBindingProvider);
    _ref.invalidate(groupMemberRemovedSignalProvider);
    _ref.invalidate(tenantSwitchServiceProvider);
    _ref.invalidate(updateControllerProvider);
    _ref.invalidate(updateDownloadProgressProvider);
    _ref.invalidate(badgeServiceProvider);

    final badgeService = _ref.read(badgeServiceProvider.notifier);
    badgeService.reset();

    _ref.invalidate(conversationRealtimeBindingProvider);
  }

  Future<void> clearAndRedirectToLogin({
    required void Function() onCleared,
  }) async {
    await _ref.read(authSessionProvider.notifier).clearSession();

    _clearAllUserScopes();

    onCleared();
  }

  void forceClearAllUserScopes() {
    _clearAllUserScopes(_ref.read(authSessionProvider).userId);
  }
}
