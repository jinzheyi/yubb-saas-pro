import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
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
  final StreamSubscription<ImSocketEvent> subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleConversationSocketEvent(ref, event));
  ref.onDispose(subscription.cancel);
});

void _handleConversationSocketEvent(Ref ref, ImSocketEvent event) {
  switch (event.type) {
    case SocketEventTypes.conversationHint:
    case SocketEventTypes.conversationUpdated:
    case SocketEventTypes.conversationDeleted:
    case SocketEventTypes.reconnecting:
      ref.read(conversationListControllerProvider.notifier).syncIncrementally();
      break;
    case SocketEventTypes.authSucceeded:
      // 认证成功：同步会话列表 + 初始化角标（从后端 HTTP API）
      ref.read(conversationListControllerProvider.notifier).syncIncrementally();
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

  // 仅处理自己的头像变更：刷新个人资料
  ref.invalidate(currentUserProfileProvider);
}

void _handleBadgeUpdated(Ref ref, ImSocketEvent event) {
  final payload = event.payload;

  // 1. 同步到全局角标服务（驱动 Tab 栏角标）
  ref.read(badgeServiceProvider.notifier).applyWebSocketPayload(payload);

  // 2. 同步到会话列表控制器（驱动会话列表中的角标）
  final rawBadges = payload['conversationBadges'];
  if (rawBadges is! List) {
    ref.read(conversationListControllerProvider.notifier).syncIncrementally();
    return;
  }
  final badges = <String, int>{};
  for (final item in rawBadges) {
    if (item is! Map) {
      continue;
    }
    // 兼容 HTTP (chatId) 和 WebSocket (conversationId) 两种字段名
    final chatId = (item['chatId'] ?? item['conversationId'])?.toString().trim() ?? '';
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
    ref.read(groupMemberRemovedSignalProvider.notifier).state =
        GroupMemberRemovedSignal(
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
      ref.read(groupMemberRemovedSignalProvider.notifier).state =
          GroupMemberRemovedSignal(
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
