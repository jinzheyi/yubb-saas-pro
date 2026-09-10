import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

final groupMemberRemovedSignalProvider =
    StateProvider<GroupMemberRemovedSignal?>((ref) => null);

class GroupMemberRemovedSignal {
  const GroupMemberRemovedSignal({
    required this.groupId,
    required this.reason,
    required this.token,
  });
  final String groupId;
  final String reason;
  final int token;
}

/// 会话实时绑定：在整个应用生命周期中保持活跃，不随Tab切换而销毁
/// 移除 autoDispose 确保 websocket 订阅在 Tab 切换时保持连接
final conversationRealtimeBindingProvider = Provider<void>((ref) {
  // 启动定期清理任务（仅首次初始化）
  _startMapCleanupTimers();

  final StreamSubscription<ImSocketEvent> subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleConversationSocketEvent(ref, event));
  ref.onDispose(() {
    subscription.cancel();
    // 注意：不清理 Timer，因为是全局的，需要跟随整个应用生命周期
  });
});

/// 会话同步节流器：避免高频 WebSocket 事件触发频繁同步
/// 【泄漏修复】定期清理过期条目，限制最大容量
final Map<String, int> _syncThrottleTimestamps = <String, int>{};
const int _syncThrottleIntervalMs = 1000;
const int _syncThrottleMaxEntries = 500;
Timer? _syncThrottleCleanupTimer;

/// 本地会话更新时间记录：避免发送消息后 WebSocket 推送触发多余 sync
/// key: chatId, value: {time: 更新时间戳 (毫秒), isSelf: 是否自己发的消息}
/// 【泄漏修复】定期清理过期条目，限制最大容量
final Map<String, Map<String, dynamic>> _localConversationUpdateTimes =
    <String, Map<String, dynamic>>{};
const int _localUpdateCooldownMs = 3000; // 3 秒冷却期
const int _localUpdateMaxEntries = 500;
Timer? _localUpdateCleanupTimer;

/// 清空旧账号的同步节流与本地更新时间记录。
void clearConversationRealtimeEphemeralState() {
  _syncThrottleTimestamps.clear();
  _localConversationUpdateTimes.clear();
}

/// 启动定期清理任务（在 Provider 首次创建时调用）
void _startMapCleanupTimers() {
  // 清理节流器 Map：每 5 分钟清理一次超过最大容量的条目
  _syncThrottleCleanupTimer ??= Timer.periodic(
    const Duration(minutes: 5),
    (_) => _cleanupSyncThrottleMap(),
  );

  // 清理本地更新记录：每 3 分钟清理一次过期条目
  _localUpdateCleanupTimer ??= Timer.periodic(
    const Duration(minutes: 3),
    (_) => _cleanupLocalUpdateMap(),
  );
}

/// 清理节流器 Map 中超过最大容量的条目
void _cleanupSyncThrottleMap() {
  if (_syncThrottleTimestamps.length <= _syncThrottleMaxEntries) {
    return;
  }
  // 保留最新的 N 个条目
  final entries = _syncThrottleTimestamps.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  _syncThrottleTimestamps.clear();
  for (int i = 0; i < _syncThrottleMaxEntries; i++) {
    _syncThrottleTimestamps[entries[i].key] = entries[i].value;
  }
  debugPrint(
    '[ConversationRealtime] Cleaned sync throttle map: ${_syncThrottleTimestamps.length} entries',
  );
}

/// 清理本地更新 Map 中过期条目（超过冷却期的条目）
void _cleanupLocalUpdateMap() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final keysToRemove = <String>[];

  for (final entry in _localConversationUpdateTimes.entries) {
    final updateTime = entry.value['time'] as int? ?? 0;
    // 超过冷却期两倍的条目可以安全清理
    if (now - updateTime > _localUpdateCooldownMs * 2) {
      keysToRemove.add(entry.key);
    }
  }

  for (final key in keysToRemove) {
    _localConversationUpdateTimes.remove(key);
  }

  // 如果仍然超过最大容量，强制清理最旧的条目
  if (_localConversationUpdateTimes.length > _localUpdateMaxEntries) {
    final entries = _localConversationUpdateTimes.entries.toList()
      ..sort(
        (a, b) => ((b.value['time'] as int? ?? 0).compareTo(
          a.value['time'] as int? ?? 0,
        )),
      );
    _localConversationUpdateTimes.clear();
    for (int i = 0; i < _localUpdateMaxEntries; i++) {
      _localConversationUpdateTimes[entries[i].key] = entries[i].value;
    }
  }

  if (keysToRemove.isNotEmpty) {
    debugPrint(
      '[ConversationRealtime] Cleaned local update map: ${keysToRemove.length} expired entries',
    );
  }
}

/// 记录本地更新（由 upsertLocalMessage 调用）
void markLocalConversationUpdate(String chatId, {bool isSelf = false}) {
  _localConversationUpdateTimes[chatId] = {
    'time': DateTime.now().millisecondsSinceEpoch,
    'isSelf': isSelf,
  };
}

/// 检查是否应该跳过 sync（因为近期有本地更新）
/// 只有自己发的消息才需要跳过，对方的消息应触发 sync
bool _shouldSkipSyncForLocalUpdate(String chatId) {
  final updateRecord = _localConversationUpdateTimes[chatId];
  if (updateRecord == null) {
    return false;
  }

  // 如果本地更新是自己发的消息，则跳过 sync（因为本地已更新）
  final wasSelfUpdate = updateRecord['isSelf'] as bool? ?? false;
  if (!wasSelfUpdate) {
    return false;
  }

  final updateTime = updateRecord['time'] as int? ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  return now - updateTime < _localUpdateCooldownMs;
}

bool _shouldThrottleSync(String key) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final lastSync = _syncThrottleTimestamps[key] ?? 0;
  if (now - lastSync < _syncThrottleIntervalMs) {
    return true;
  }
  _syncThrottleTimestamps[key] = now;
  return false;
}

void _handleConversationSocketEvent(Ref ref, ImSocketEvent event) {
  switch (event.type) {
    case SocketEventTypes.conversationHint:
    case SocketEventTypes.conversationUpdated:
    case SocketEventTypes.conversationDeleted:
      // 优化：如果该会话近期有本地更新（自己发的消息），跳过 sync
      // 因为本地已通过 upsertLocalMessage 更新了会话列表
      // 注意：对方发来的消息（isSelf=false）不会跳过 sync
      final chatId = event.chatId?.trim() ?? '';
      if (chatId.isNotEmpty && _shouldSkipSyncForLocalUpdate(chatId)) {
        debugPrint(
          '[ConversationRealtime] Skipping sync for recently updated chat (self message): $chatId',
        );
        break;
      }

      // 优化：如果用户当前正在查看该会话的聊天页面，跳过 sync
      // 因为用户已在聊天页面，会话列表的更新不是关键路径
      // 离开聊天页面时会重新加载会话列表
      if (chatId.isNotEmpty && _isCurrentlyViewingChat(ref, chatId)) {
        debugPrint(
          '[ConversationRealtime] Skipping sync for active chat: $chatId',
        );
        break;
      }

      // 严格节流：避免高频事件触发频繁同步
      if (!_shouldThrottleSync('conversation_sync')) {
        ref
            .read(conversationListControllerProvider.notifier)
            .syncIncrementally();
      }
      break;
    case SocketEventTypes.reconnecting:
      // 优化：重连事件不触发 sync，等待 authSucceeded 后再处理
      // 避免在重连期间发送多余的请求
      debugPrint('[ConversationRealtime] Skipping sync on reconnecting event');
      break;
    case SocketEventTypes.authSucceeded:
      // 认证成功：仅初始化角标，不触发会话列表同步
      // 原因：
      // 1. 发送消息 → 本地已通过 upsertLocalMessage 更新会话列表
      // 2. 接收消息 → WebSocket 的 conversationHint/Updated 事件已处理 sync
      // 3. 首次进入应用 → 初始化时已经 load 过完整列表
      // 4. 避免每次 authSucceeded 都触发不必要的 sync 请求风暴
      _initBadgeFromServer(ref);
      break;
    case SocketEventTypes.badgeUpdated:
      _handleBadgeUpdated(ref, event);
      break;
    case SocketEventTypes.userAvatarChanged:
      _handleUserAvatarChanged(ref, event);
      break;
    case SocketEventTypes.systemNotify:
      _handleConversationSystemNotify(ref, event);
      break;
    default:
      break;
  }
}

/// 认证成功时通过 HTTP API 初始化角标数据
Future<void> _initBadgeFromServer(Ref ref) async {
  final dio = ref.read(dioProvider);
  await ref.read(badgeServiceProvider.notifier).initBadgeData(dio);
}

/// 用户头像变更事件处理
/// 刷新当前用户的个人资料（自己改头像时）
void _handleUserAvatarChanged(Ref ref, ImSocketEvent event) {
  final payload = event.payload;
  final action = payload['action']?.toString() ?? '';
  if (action != 'user_avatar_changed') {
    return;
  }

  final currentUserId = ref.read(authSessionProvider).userId;
  final changedUserId = payload['userId']?.toString() ?? '';
  if (changedUserId.isEmpty || changedUserId != currentUserId) {
    return;
  }

  // 1. 获取旧头像 URL
  final oldProfile = ref.read(currentUserProfileProvider).valueOrNull;
  final oldAvatarUrl = oldProfile?.avatarUrl ?? '';

  // 2. 清理旧头像的磁盘缓存
  if (oldAvatarUrl.isNotEmpty) {
    unawaited(ImCacheManager.instance.removeFile(oldAvatarUrl));
  }

  // 3. 清理 Flutter ImageCache 内存缓存
  // 注意：这会清理所有图片缓存，但头像变更是低频操作，影响可接受
  PaintingBinding.instance.imageCache.clear();

  // 4. 刷新当前用户资料（触发重新请求新头像）
  ref.invalidate(currentUserProfileProvider);

  // 5. 刷新会话列表（包含当前用户头像的会话）
  ref.invalidate(conversationListControllerProvider);

  // 6. 刷新技术通讯录（包含当前用户头像）
  ref.invalidate(contactsPageControllerProvider);
}

void _handleBadgeUpdated(Ref ref, ImSocketEvent event) {
  final payload = event.payload;

  // 1. 同步到全局角标服务（驱动 Tab 栏角标）
  ref.read(badgeServiceProvider.notifier).applyWebSocketPayload(payload);

  // 2. 同步到会话列表控制器（驱动会话列表中的角标）
  final rawBadges = payload['conversationBadges'];
  if (rawBadges is! List) {
    // 优化：不触发完整 sync，仅记录日志
    // 原因：payload 格式异常时，应等待下一次正常推送，避免频繁请求
    debugPrint(
      '[ConversationRealtime] badgeUpdated: conversationBadges not a list, skipping sync',
    );
    return;
  }
  final badges = <String, int>{};
  for (final item in rawBadges) {
    if (item is! Map) {
      continue;
    }
    // 兼容 HTTP (chatId) 和 WebSocket (conversationId) 两种字段名
    final chatId =
        (item['chatId'] ?? item['conversationId'])?.toString().trim() ?? '';
    if (chatId.isEmpty || chatId == '0') {
      continue;
    }
    final unreadCount = int.tryParse('${item['unreadCount'] ?? 0}') ?? 0;
    badges[chatId] = unreadCount < 0 ? 0 : unreadCount;
  }
  ref
      .read(conversationListControllerProvider.notifier)
      .applyBadgeSnapshot(badges);
}

void _handleConversationSystemNotify(Ref ref, ImSocketEvent event) {
  final payload = event.payload;
  final action = payload['action']?.toString().trim() ?? '';

  // 优化：群生命周期事件需要特殊处理，不受当前查看状态影响
  if (_isGroupLifecycleAction(action)) {
    _handleGroupLifecycleAction(ref, action, payload);
    return;
  }
  if (action == 'group_info_updated') {
    _handleGroupInfoUpdatedAction(ref, action, payload);
    return;
  }
  if (_isJoinRequestAction(action)) {
    final groupId = payload['groupId']?.toString().trim() ?? '';
    if (groupId.isNotEmpty && groupId != '0') {
      ref
          .read(groupJoinRequestSignalProvider.notifier)
          .state = GroupJoinRequestSignal(
        groupId: groupId,
        action: action,
        payload: payload,
        token: DateTime.now().microsecondsSinceEpoch,
      );
    }
  }
  if (_isConversationIrrelevantAction(action)) {
    return;
  }

  final snapshot = payload['conversationSnapshot'];
  if (snapshot is Map) {
    final snapshotMap = snapshot.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final timestamp = _parseDateTime(
      snapshotMap['lastMessageTime'] ?? payload['lastMessageTime'],
    );
    final currentUserId = ref.read(authSessionProvider).userId;
    ref
        .read(conversationListControllerProvider.notifier)
        .upsertFromSnapshot(
          snapshot: snapshotMap,
          lastMessage: snapshotMap['lastMessageContent']?.toString() ?? '',
          updatedAt: timestamp ?? DateTime.now(),
          messageSequence: snapshotMap['lastMessageSequence']?.toString(),
          currentUserId: currentUserId,
        );
    return;
  }

  final content = payload['content']?.toString().trim() ?? '';
  if (content.isEmpty ||
      content == 'CONVERSATION_UPSERT' ||
      content == 'CONVERSATION_DELETE' ||
      content == 'BADGE_UPDATE' ||
      content == 'MESSAGE_SEND_DENIED' ||
      content == 'GROUP_MEMBER_MUTE_CHANGED' ||
      content == 'GROUP_MUTE_ALL_CHANGED' ||
      content == 'GROUP_MEMBER_ADDED' ||
      content == 'GROUP_MEMBER_REMOVED' ||
      content == 'GROUP_OWNER_TRANSFERRED' ||
      content == 'GROUP_DISBANDED' ||
      content == 'GROUP_INFO_UPDATED') {
    // 优化：如果用户当前正在查看某个会话，跳过 sync
    // 离开聊天页面时会重新加载会话列表
    final activeState = ref.read(activeConversationServiceProvider);
    if (activeState.isViewing) {
      debugPrint(
        '[ConversationRealtime] Skipping sync in systemNotify for active chat',
      );
      return;
    }
    ref.read(conversationListControllerProvider.notifier).syncIncrementally();
  }
}

void _handleGroupInfoUpdatedAction(
  Ref ref,
  String action,
  Map<String, Object?> payload,
) {
  final chatId = payload['chatId']?.toString().trim() ?? '';
  final groupId = payload['groupId']?.toString().trim() ?? '';
  final newName = payload['newName']?.toString().trim() ?? '';
  if (newName.isEmpty) {
    return;
  }
  if (chatId.isNotEmpty && chatId != '0') {
    ref
        .read(conversationListControllerProvider.notifier)
        .patchConversationTitle(
          chatId: chatId,
          title: newName,
          targetId: groupId.isNotEmpty ? groupId : null,
          conversationType: ConversationType.group,
        );
  } else if (groupId.isNotEmpty && groupId != '0') {
    ref
        .read(conversationListControllerProvider.notifier)
        .patchConversationTitle(
          chatId: '',
          title: newName,
          targetId: groupId,
          conversationType: ConversationType.group,
        );
  }
}

void _handleGroupLifecycleAction(
  Ref ref,
  String action,
  Map<String, Object?> payload,
) {
  final groupId = payload['groupId']?.toString().trim() ?? '';
  if (groupId.isEmpty || groupId == '0') {
    return;
  }

  if (action == 'group_disbanded') {
    ref
        .read(groupMemberRemovedSignalProvider.notifier)
        .state = GroupMemberRemovedSignal(
      groupId: groupId,
      reason: 'group_disbanded',
      token: DateTime.now().microsecondsSinceEpoch,
    );
    ref.read(conversationListControllerProvider.notifier).syncIncrementally();
    return;
  }

  if (action == 'group_member_removed') {
    final removedUserId =
        payload['userId']?.toString() ??
        payload['memberId']?.toString() ??
        payload['removedUserId']?.toString() ??
        '';
    final currentUserId = ref.read(authSessionProvider).userId;
    if (removedUserId.isNotEmpty && removedUserId == currentUserId) {
      ref
          .read(groupMemberRemovedSignalProvider.notifier)
          .state = GroupMemberRemovedSignal(
        groupId: groupId,
        reason: 'kicked_from_group',
        token: DateTime.now().microsecondsSinceEpoch,
      );
      ref.read(conversationListControllerProvider.notifier).syncIncrementally();
    }
    return;
  }

  if (action == 'group_member_added') {
    ref.read(conversationListControllerProvider.notifier).syncIncrementally();
    return;
  }

  if (action == 'group_owner_transferred') {
    ref.read(conversationListControllerProvider.notifier).syncIncrementally();
    return;
  }
}

bool _isGroupLifecycleAction(String action) {
  switch (action) {
    case 'group_disbanded':
    case 'group_member_removed':
    case 'group_member_added':
    case 'group_owner_transferred':
      return true;
    default:
      return false;
  }
}

bool _isConversationIrrelevantAction(String action) {
  switch (action) {
    case 'reedit_after_recall':
    case 'voice_played':
    case 'group_join_request_created':
    case 'group_join_request_admin_refresh':
    case 'group_join_request_processed':
      return true;
    default:
      return false;
  }
}

bool _isJoinRequestAction(String action) {
  switch (action) {
    case 'group_join_request_created':
    case 'group_join_request_admin_refresh':
    case 'group_join_request_processed':
      return true;
    default:
      return false;
  }
}

DateTime? _parseDateTime(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is DateTime) {
    return raw;
  }
  if (raw is num) {
    final value = raw.toInt();
    if (value <= 0) {
      return null;
    }
    final millis = value < 100000000000 ? value * 1000 : value;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  final text = raw.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  final asInt = int.tryParse(text);
  if (asInt != null) {
    final millis = text.length <= 10 ? asInt * 1000 : asInt;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return DateTime.tryParse(text);
}

/// 检查用户当前是否正在查看指定的会话
bool _isCurrentlyViewingChat(Ref ref, String chatId) {
  final activeState = ref.read(activeConversationServiceProvider);
  return activeState.isViewing && activeState.currentChatId == chatId;
}
