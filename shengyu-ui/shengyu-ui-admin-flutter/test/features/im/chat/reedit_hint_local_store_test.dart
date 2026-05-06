import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/reedit_hint_local_store.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

void main() {
  const store = ReeditHintLocalStore('im.reedit_hint');

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persist and getByCandidates restores reedit hint', () async {
    await store.persist(
      tenantId: 't1',
      userId: 'u1',
      chatId: 'c1',
      messageId: 'm1',
      content: 'hello',
      deadlineTs: 123,
    );

    final hint = await store.getByCandidates(
      tenantId: 't1',
      userId: 'u1',
      chatId: 'c1',
      messageIds: const <String>['m2', 'm1'],
    );

    expect(hint, isNotNull);
    expect(hint!.content, 'hello');
    expect(hint.deadlineTs, 123);
  });

  test('rehydrateMessages patches outgoing recalled message', () async {
    await store.persist(
      tenantId: 't1',
      userId: 'u1',
      chatId: 'c1',
      messageId: 'm1',
      content: 'restored text',
      deadlineTs: 456,
    );

    final messages = await store.rehydrateMessages(
      tenantId: 't1',
      userId: 'u1',
      chatId: 'c1',
      messages: <Message>[
        Message(
          messageId: 'm1',
          chatId: 'c1',
          senderId: 'u1',
          senderName: 'me',
          type: MessageType.system,
          status: MessageStatus.read,
          content: '你撤回了一条消息',
          sentAt: DateTime.parse('2026-05-01T00:00:00Z'),
          isOutgoing: true,
          extra: const MessageExtra(),
        ),
      ],
    );

    expect(messages.single.extra.reeditContent, 'restored text');
    expect(messages.single.extra.reeditDeadlineTs, 456);
  });
}
