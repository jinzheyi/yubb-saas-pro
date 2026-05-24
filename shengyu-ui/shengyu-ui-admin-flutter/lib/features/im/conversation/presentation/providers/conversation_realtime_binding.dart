import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';

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
    case SocketEventTypes.authSucceeded:
      ref.read(conversationListControllerProvider.notifier).syncIncrementally();
      break;
    case SocketEventTypes.badgeUpdated:
      _handleBadgeUpdated(ref, event);
      break;
    case SocketEventTypes.systemNotify:
      _handleConversationSystemNotify(ref, event);
      break;
    default:
      break;
  }
}

void _handleBadgeUpdated(Ref ref, ImSocketEvent event) {
  final payload = event.payload;
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
    final chatId = item['chatId']?.toString().trim() ?? '';
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
    ref
        .read(conversationListControllerProvider.notifier)
        .upsertFromSnapshot(
          snapshot: snapshotMap,
          lastMessage: snapshotMap['lastMessageContent']?.toString() ?? '',
          updatedAt: timestamp ?? DateTime.now(),
          messageSequence: snapshotMap['lastMessageSequence']?.toString(),
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
      content == 'GROUP_MUTE_ALL_CHANGED') {
    ref.read(conversationListControllerProvider.notifier).syncIncrementally();
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
