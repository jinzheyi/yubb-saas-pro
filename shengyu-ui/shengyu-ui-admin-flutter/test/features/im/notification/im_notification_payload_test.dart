import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';

void main() {
  test('parses only the minimum v1 message routing payload', () {
    final event = ImNotificationEvent.fromPayload(const {
      'v': '1',
      'kind': 'im_message',
      'eventId': 'm-1',
      'tenantId': 't-1',
      'chatId': 'c-1',
      'messageId': 'm-1',
      'recipientUserId': 'u-1',
      'sentAt': '123',
    });

    expect(event, isA<ImMessageNotificationEvent>());
    expect((event! as ImMessageNotificationEvent).chatId, 'c-1');
    expect((event as ImMessageNotificationEvent).recipientUserId, 'u-1');
  });

  test('rejects unknown versions and incomplete payloads', () {
    expect(ImNotificationEvent.fromPayload(const {'v': '2'}), isNull);
    expect(
      ImNotificationEvent.fromPayload(const {'v': '1', 'kind': 'im_message'}),
      isNull,
    );
  });

  test('requires the explicit version and call event version', () {
    expect(
      ImNotificationEvent.fromPayload(const {
        'kind': 'im_message',
        'eventId': 'm-1',
        'tenantId': 't-1',
        'chatId': 'c-1',
      }),
      isNull,
    );
    expect(
      ImNotificationEvent.fromPayload(const {
        'v': '1',
        'kind': 'call_invite',
        'eventId': 'call-1:1',
        'tenantId': 't-1',
        'callId': 'call-1',
      }),
      isNull,
    );
  });
}
