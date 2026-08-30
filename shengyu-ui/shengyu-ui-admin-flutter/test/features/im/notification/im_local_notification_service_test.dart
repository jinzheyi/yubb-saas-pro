import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/application/im_notification_presentation_policy.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';

void main() {
  const policy = ImNotificationPresentationPolicy();

  ImMessageNotificationEvent event({bool mention = false}) {
    return ImMessageNotificationEvent(
      eventId: 'message-1',
      tenantId: 'tenant-1',
      sentAt: 1,
      chatId: 'chat-1',
      messageId: 'message-1',
      isMention: mention,
    );
  }

  test('ordinary messages use a privacy-safe messages channel', () {
    final presentation = policy.forMessage(event());

    expect(presentation.androidChannelId, 'im_messages');
    expect(presentation.body, '你收到一条新消息');
    expect(presentation.isMention, isFalse);
  });

  test('mentions use their separate high-priority channel', () {
    final presentation = policy.forMessage(event(mention: true));

    expect(presentation.androidChannelId, 'im_mentions');
    expect(presentation.body, '你有一条重要群消息');
    expect(presentation.isMention, isTrue);
  });
}
