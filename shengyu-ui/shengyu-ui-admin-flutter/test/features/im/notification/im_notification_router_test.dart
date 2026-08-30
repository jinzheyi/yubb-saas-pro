import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/application/im_notification_router.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

void main() {
  final event = ImMessageNotificationEvent(
    eventId: 'message-1',
    tenantId: 'tenant-1',
    sentAt: 1,
    chatId: 'chat-1',
    messageId: 'message-1',
    recipientUserId: 'user-1',
  );

  test('routes only after resolving trusted conversation metadata', () async {
    ChatEntryArgs? opened;
    final router = ImNotificationRouter(
      resolveChat: (chatId) async => ChatEntryArgs.latest(
        chatId: chatId,
        conversationType: ConversationType.direct,
        targetId: 'user-2',
        title: '可信会话',
      ),
      openChat: (args) => opened = args,
    );

    expect(await router.routeMessage(event), isTrue);
    expect(opened?.chatId, 'chat-1');
    expect(opened?.title, '可信会话');
  });

  test('does not route unknown conversations from payload data', () async {
    var opened = false;
    final router = ImNotificationRouter(
      resolveChat: (_) async => null,
      openChat: (_) => opened = true,
    );

    expect(await router.routeMessage(event), isFalse);
    expect(opened, isFalse);
  });
}
