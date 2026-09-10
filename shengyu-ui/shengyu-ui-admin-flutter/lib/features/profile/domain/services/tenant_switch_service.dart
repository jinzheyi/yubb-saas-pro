import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/tenant_list_item_dto.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/im_database.dart';

/// 租户切换状态
class TenantSwitchState {
  const TenantSwitchState({
    required this.switchStatus,
    required this.tenantList,
    this.loadedForUserId = '',
    this.errorMessage = '',
  });

  final TenantSwitchStatus switchStatus;
  final List<TenantListItemDto> tenantList;

  /// 列表所属 SaaS 用户，避免账号切换后复用上一个账号的企业数据。
  final String loadedForUserId;
  final String errorMessage;

  static final TenantSwitchState initial = TenantSwitchState(
    switchStatus: TenantSwitchStatus.idle,
    tenantList: const [],
  );

  TenantSwitchState copyWith({
    TenantSwitchStatus? switchStatus,
    List<TenantListItemDto>? tenantList,
    String? loadedForUserId,
    String? errorMessage,
  }) {
    return TenantSwitchState(
      switchStatus: switchStatus ?? this.switchStatus,
      tenantList: tenantList ?? this.tenantList,
      loadedForUserId: loadedForUserId ?? this.loadedForUserId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum TenantSwitchStatus { idle, loading, success, failed }

/// 切换结果
class TenantSwitchResult {
  const TenantSwitchResult({required this.success, this.message = ''});

  final bool success;
  final String message;

  factory TenantSwitchResult.success() =>
      const TenantSwitchResult(success: true);

  factory TenantSwitchResult.failure(String message) =>
      TenantSwitchResult(success: false, message: message);
}

/// 租户切换服务
class TenantSwitchService extends StateNotifier<TenantSwitchState> {
  TenantSwitchService({
    required this.ref,
    required this.remoteDataSource,
    required this.imSocketClient,
  }) : super(TenantSwitchState.initial);

  final Ref ref;
  final AuthRemoteDataSource remoteDataSource;
  final ImSocketClient imSocketClient;

  String get currentTenantId => ref.read(authSessionProvider).tenantId;

  /// 加载租户列表
  Future<void> loadTenantList() async {
    final session = ref.read(authSessionProvider);
    if (!session.isAuthenticated) {
      state = TenantSwitchState.initial;
      return;
    }
    final requestedUserId = session.userId;
    try {
      // 先清空上一次账号的数据；网络返回前页面只能展示当前账号的加载态。
      state = TenantSwitchState(
        switchStatus: TenantSwitchStatus.loading,
        tenantList: const [],
        loadedForUserId: requestedUserId,
      );
      final list = await remoteDataSource.getMyTenantList();
      // 登录账号在请求期间发生变化时，丢弃旧请求结果，避免异步回写串号。
      if (ref.read(authSessionProvider).userId != requestedUserId) {
        return;
      }
      state = state.copyWith(
        switchStatus: TenantSwitchStatus.idle,
        tenantList: list,
      );
    } catch (e) {
      if (ref.read(authSessionProvider).userId != requestedUserId) {
        return;
      }
      debugPrint('[TenantSwitchService] 加载租户列表失败: $e');
      state = state.copyWith(
        switchStatus: TenantSwitchStatus.failed,
        errorMessage: '加载租户列表失败: $e',
      );
    }
  }

  /// 切换租户
  Future<TenantSwitchResult> switchTenant({
    required String targetTenantId,
  }) async {
    // 互斥锁：防止并发切换
    if (state.switchStatus == TenantSwitchStatus.loading) {
      return TenantSwitchResult.failure('正在切换中，请稍候');
    }

    final oldSession = ref.read(authSessionProvider);
    if (!oldSession.isAuthenticated) {
      return TenantSwitchResult.failure('未登录');
    }

    // 校验：不能切换到当前租户
    if (targetTenantId == oldSession.tenantId) {
      return TenantSwitchResult.failure('已在当前企业');
    }

    // 校验：目标租户必须可切换
    final targetTenant = state.tenantList.firstWhere(
      (t) => t.id == targetTenantId,
      orElse: () => TenantListItemDto(id: '', tenantName: '', status: '1'),
    );
    if (!targetTenant.isSwitchable) {
      return TenantSwitchResult.failure('该企业不可切换');
    }

    state = state.copyWith(switchStatus: TenantSwitchStatus.loading);

    try {
      // [1] 调用后端接口切换租户
      final tokenDto = await remoteDataSource.toTenant(
        tenantId: targetTenantId,
      );

      // [2] 构造新的 AuthSession（使用 copyWith 保留设备信息）
      final newSession = oldSession.copyWith(
        accessToken: tokenDto.accessToken,
        refreshToken: tokenDto.refreshToken,
        tenantId: targetTenantId,
        tenantName: tokenDto.tenantName,
      );

      // [3] 清理旧租户数据
      await _clearTenantScopedData(oldSession);

      // [4] 保存新 session
      await ref.read(authSessionProvider.notifier).saveSession(newSession);

      // [5] 重新连接 WebSocket
      await _reconnectWebSocket(newSession);

      // [6] 刷新 Provider 状态
      _invalidateProviders();

      state = state.copyWith(switchStatus: TenantSwitchStatus.success);

      return TenantSwitchResult.success();
    } catch (e) {
      state = state.copyWith(
        switchStatus: TenantSwitchStatus.failed,
        errorMessage: e.toString(),
      );

      // 区分 401 错误，引导用户重新登录
      if (e.toString().contains('401')) {
        return TenantSwitchResult.failure('登录已过期，请重新登录');
      }

      return TenantSwitchResult.failure('切换失败: $e');
    }
  }

  /// 清理租户作用域数据
  Future<void> _clearTenantScopedData(AuthSession oldSession) async {
    // [0] 清理本地数据库（关键：防止跨租户数据泄露）
    try {
      final database = ImDatabase.instance;
      await database.clearAllTables();
      debugPrint('[TenantSwitchService] 本地数据库已清理');
    } catch (e) {
      debugPrint('[TenantSwitchService] 清理本地数据库失败: $e');
    }

    // [1] 清空内存缓存
    try {
      final cacheManager = ref.read(unifiedCacheManagerProvider);
      cacheManager.clearMemoryCacheForUser(oldSession.userId);
      debugPrint('[TenantSwitchService] 内存缓存已清理');
    } catch (e) {
      debugPrint('[TenantSwitchService] 清理内存缓存失败: $e');
    }

    // [2] 清理 SharedPreferences（保留设备信息）
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        StorageKeyRegistry.imBadgeSnapshot,
        StorageKeyRegistry.conversationCursorVersion,
      ];

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      debugPrint('[TenantSwitchService] SharedPreferences 已清理');
    } catch (e) {
      debugPrint('[TenantSwitchService] 清理 SharedPreferences 失败: $e');
    }

    // [3] 重置角标服务
    try {
      ref.read(badgeServiceProvider.notifier).reset();
      debugPrint('[TenantSwitchService] 角标服务已重置');
    } catch (e) {
      debugPrint('[TenantSwitchService] 重置角标服务失败: $e');
    }

    // [4] 重置 ActiveConversationService
    try {
      ref.read(activeConversationServiceProvider.notifier).deactivateChat();
      debugPrint('[TenantSwitchService] ActiveConversationService 已重置');
    } catch (e) {
      debugPrint('[TenantSwitchService] 重置 ActiveConversationService 失败: $e');
    }

    // [5] 断开 WebSocket
    try {
      await imSocketClient.disconnect();
      debugPrint('[TenantSwitchService] WebSocket 已断开');
    } catch (e) {
      debugPrint('[TenantSwitchService] 断开 WebSocket 失败: $e');
    }
  }

  /// 重新连接 WebSocket
  Future<void> _reconnectWebSocket(AuthSession newSession) async {
    try {
      await imSocketClient.connect();
      await imSocketClient.auth(newSession);
      debugPrint('[TenantSwitchService] WebSocket 已重连');
    } catch (e) {
      debugPrint('[TenantSwitchService] WebSocket 重连失败: $e');
    }
  }

  /// 刷新 Provider 状态
  ///
  /// 注意：必须与 SessionCleanupService._clearAllUserScopes() 保持一致
  void _invalidateProviders() {
    // ========== 用户资料 ==========
    ref.invalidate(currentUserProfileProvider);

    // ========== 会话相关 ==========
    ref.invalidate(conversationListControllerProvider);
    ref.invalidate(conversationRealtimeBindingProvider);

    // ========== 聊天相关 ==========
    // family-scoped provider 需要 invalidate 整个 family
    ref.invalidate(chatControllerProvider);
    ref.invalidate(chatTimelineControllerProvider);
    ref.invalidate(chatMediaControllerProvider);
    ref.invalidate(chatMessageActionControllerProvider);
    ref.invalidate(chatRuntimeNoticeProvider);
    ref.invalidate(chatRealtimeSignalProvider);
    ref.invalidate(chatReceiptLastVisibleChatIdProvider);

    // ========== 通讯录相关 ==========
    ref.invalidate(contactsPageControllerProvider);
    ref.invalidate(myDepartmentTreeProvider);
    ref.invalidate(organizationTreeProvider);
    ref.invalidate(starContactsProvider);
    ref.invalidate(myGroupsProvider);

    // ========== 群组设置相关 ==========
    ref.invalidate(groupSettingsRepositoryProvider);
    ref.invalidate(groupMemberRemovedSignalProvider);

    // ========== 角标相关 ==========
    ref.invalidate(badgeServiceProvider);
    ref.read(badgeServiceProvider.notifier).reset();

    debugPrint('[TenantSwitchService] Provider 状态已刷新');
  }
}

// ============================================================
// Riverpod Provider
// ============================================================

final tenantSwitchServiceProvider =
    StateNotifierProvider<TenantSwitchService, TenantSwitchState>((ref) {
      return TenantSwitchService(
        ref: ref,
        remoteDataSource: ref.watch(authRemoteDataSourceProvider),
        imSocketClient: ref.watch(imSocketClientProvider),
      );
    });
