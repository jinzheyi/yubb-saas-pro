import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_dispatcher.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';

class GroupMemberRealtimeSignal {
  const GroupMemberRealtimeSignal({
    required this.groupId,
    required this.action,
    required this.payload,
    required this.token,
  });

  final String groupId;
  final String action;
  final Map<String, Object?> payload;
  final int token;
}

final groupMemberRealtimeSignalProvider =
    StateProvider<GroupMemberRealtimeSignal?>((ref) => null);

final groupSettingsRealtimeBindingProvider =
    Provider.autoDispose.family<void, String>((ref, groupId) {
  final StreamSubscription<ImSocketEvent> subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleGroupSocketEvent(ref, groupId, event));
  ref.onDispose(() => subscription.cancel());
});

void _handleGroupSocketEvent(
  Ref ref,
  String groupId,
  ImSocketEvent event,
) {
  if (event.type != SocketEventTypes.systemNotify) {
    return;
  }
  final payload = event.payload;
  final action = payload['action']?.toString() ?? '';
  if (action != 'group_member_added' &&
      action != 'group_member_removed' &&
      action != 'group_member_mute_changed' &&
      action != 'group_mute_all_changed' &&
      action != 'group_owner_transferred') {
    return;
  }
  final eventGroupId =
      payload['groupId']?.toString() ?? payload['chatId']?.toString() ?? '';
  if (eventGroupId.isEmpty || eventGroupId != groupId) {
    return;
  }
  ref.read(groupMemberRealtimeSignalProvider.notifier).state =
      GroupMemberRealtimeSignal(
    groupId: groupId,
    action: action,
    payload: payload,
    token: DateTime.now().microsecondsSinceEpoch,
  );
}
