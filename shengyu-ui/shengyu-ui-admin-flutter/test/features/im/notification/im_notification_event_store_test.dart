import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/infrastructure/im_notification_event_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  ImMessageNotificationEvent event({
    required String tenantId,
    required String recipientUserId,
    required String eventId,
  }) => ImMessageNotificationEvent(
    eventId: eventId,
    tenantId: tenantId,
    sentAt: 1,
    chatId: 'chat-$eventId',
    messageId: eventId,
    recipientUserId: recipientUserId,
  );

  test('pending messages are consumed only by their tenant and account scope',
      () async {
    final store = ImNotificationEventStore();
    await store.savePending(
      event(tenantId: 'tenant-a', recipientUserId: 'user-a', eventId: 'm-a'),
    );
    await store.savePending(
      event(tenantId: 'tenant-a', recipientUserId: 'user-b', eventId: 'm-b'),
    );

    final scoped = await store.takePending('tenant-a:user-a');

    expect(scoped.map((item) => item.eventId), <String>['m-a']);
    expect(await store.takePending('tenant-a:user-a'), isEmpty);
    expect(
      (await store.takePending('tenant-a:user-b')).map((item) => item.eventId),
      <String>['m-b'],
    );
  });

  test('clearScope clears both deduplication and pending state', () async {
    final store = ImNotificationEventStore();
    await store.markIfNew('tenant-a:user-a', 'm-a');
    await store.savePending(
      event(tenantId: 'tenant-a', recipientUserId: 'user-a', eventId: 'm-a'),
    );

    await store.clearScope('tenant-a:user-a');

    expect(await store.markIfNew('tenant-a:user-a', 'm-a'), isTrue);
    expect(await store.takePending('tenant-a:user-a'), isEmpty);
  });

  test('pending clicks are isolated from background pending events', () async {
    final store = ImNotificationEventStore();
    final message = event(
      tenantId: 'tenant-a',
      recipientUserId: 'user-a',
      eventId: 'm-click',
    );

    await store.savePending(message);
    await store.savePendingClick(message);

    expect(
      (await store.takePendingClicks('tenant-a:user-a'))
          .map((item) => item.eventId),
      <String>['m-click'],
    );
    expect(
      (await store.takePending('tenant-a:user-a')).map((item) => item.eventId),
      <String>['m-click'],
    );
  });
}
