import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/lifecycle/app_lifecycle_manager.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/livekit_call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/application/im_notification_router.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/application/push_device_registration_service.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/infrastructure/fcm_notification_gateway.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/infrastructure/im_local_notification_service.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/infrastructure/im_notification_event_store.dart';

final imLocalNotificationServiceProvider = Provider<ImLocalNotificationService>(
  (ref) => ImLocalNotificationService(),
);
final imNotificationEventStoreProvider = Provider<ImNotificationEventStore>(
  (ref) => ImNotificationEventStore(),
);
final fcmNotificationGatewayProvider = Provider<FcmNotificationGateway>((ref) {
  final gateway = FcmNotificationGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});
final pushDeviceRegistrationServiceProvider =
    Provider<PushDeviceRegistrationService>(
      (ref) => PushDeviceRegistrationService(
        ref.read(dioProvider),
        ref.read(fcmNotificationGatewayProvider),
        () => ref.read(authSessionProvider),
      ),
    );

/// Root-level subscription: routing must not decide whether a message gets a
/// notification, because chat pages are disposable.
final globalImNotificationBindingProvider =
    Provider<StreamSubscription<ImSocketEvent>>((ref) {
      final service = ref.read(imLocalNotificationServiceProvider);
      final fcm = ref.read(fcmNotificationGatewayProvider);
      final clickSubscription = service.clicks.listen(
        (click) => _routeClick(ref, click),
      );
      final fcmSubscription = fcm.events.listen(
        (event) => unawaited(_handleFcmEvent(ref, event)),
      );
      final fcmOpenedSubscription = fcm.openedEvents.listen((event) {
        if (event is ImMessageNotificationEvent) {
          unawaited(_routeClick(ref, ImNotificationClick(event)));
        }
      });
      unawaited(_initializeNotificationTransports(ref, service, fcm));
      ref.listen(authSessionProvider, (previous, next) {
        if (previous?.userId.isNotEmpty == true &&
            (previous!.userId != next.userId ||
                previous.tenantId != next.tenantId)) {
          // This request is deliberately best effort.  It must use the old
          // authenticated session before local logout clears its credentials.
          unawaited(
            ref
                .read(pushDeviceRegistrationServiceProvider)
                .unregisterSessionDevice(previous),
          );
          unawaited(service.cancelAllForUserScope());
          unawaited(
            ref
                .read(imNotificationEventStoreProvider)
                .clearScope('${previous.tenantId}:${previous.userId}'),
          );
        }
        if (next.isAuthenticated &&
            (previous == null || previous.userId != next.userId)) {
          unawaited(
            ref
                .read(pushDeviceRegistrationServiceProvider)
                .registerCurrentDevice(),
          );
          unawaited(_consumePendingEvents(ref, next.tenantId, next.userId));
        }
      }, fireImmediately: true);
      final subscription = ref
          .read(socketMessageDispatcherProvider)
          .stream
          .listen((event) => _handle(ref, event));
      ref.onDispose(() {
        subscription.cancel();
        clickSubscription.cancel();
        fcmSubscription.cancel();
        fcmOpenedSubscription.cancel();
      });
      return subscription;
    });

Future<void> _initializeNotificationTransports(
  Ref ref,
  ImLocalNotificationService service,
  FcmNotificationGateway fcm,
) async {
  try {
    await service.initialize();
    final launchClick = service.takeLaunchClick();
    if (launchClick != null) {
      await _routeClick(ref, launchClick);
    }
  } catch (error) {
    // Local presentation must not prevent FCM token registration or routing.
    debugPrint('[Fcm] local notification initialization failed: ${error.runtimeType}');
  }
  await fcm.initialize();
  final session = ref.read(authSessionProvider);
  if (!session.isAuthenticated) {
    // No account identity is logged; this only explains why registration is
    // deferred until the next successful login.
    debugPrint('[Fcm] registration deferred: no authenticated session');
    return;
  }
  debugPrint('[Fcm] registering current authenticated device');
  await ref
      .read(pushDeviceRegistrationServiceProvider)
      .registerCurrentDevice();
  await _consumePendingEvents(ref, session.tenantId, session.userId);
}

Future<void> _handle(Ref ref, ImSocketEvent socketEvent) async {
  if (socketEvent.type == SocketEventTypes.sessionKicked ||
      socketEvent.type == SocketEventTypes.sessionLoggedOut) {
    await ref.read(imLocalNotificationServiceProvider).cancelAllForUserScope();
    return;
  }
  if (socketEvent.type != SocketEventTypes.messageReceived) {
    return;
  }
  final session = ref.read(authSessionProvider);
  if (!session.isAuthenticated) {
    return;
  }
  final payload = <String, Object?>{
    ...socketEvent.payload,
    'v': '1',
    'kind': 'im_message',
    'eventId': socketEvent.messageId ?? socketEvent.payload['messageId'],
    'messageId': socketEvent.messageId ?? socketEvent.payload['messageId'],
    'chatId': socketEvent.chatId ?? socketEvent.payload['chatId'],
    'tenantId': session.tenantId,
    'recipientUserId': session.userId,
    'sentAt':
        socketEvent.payload['sentAt'] ?? DateTime.now().millisecondsSinceEpoch,
  };
  final event = ImNotificationEvent.fromPayload(payload);
  if (event is! ImMessageNotificationEvent) {
    return;
  }
  if (DateTime.now().millisecondsSinceEpoch - event.sentAt >
      const Duration(hours: 24).inMilliseconds) {
    return;
  }
  await _handleNotificationEvent(ref, event);
}

Future<void> _handleFcmEvent(Ref ref, ImNotificationEvent event) async {
  final session = ref.read(authSessionProvider);
  if (!session.isAuthenticated) {
    await ref.read(imNotificationEventStoreProvider).savePending(event);
    return;
  }
  if (event is ImMessageNotificationEvent) {
    await _handleNotificationEvent(ref, event);
  } else if (event is ImCallNotificationEvent) {
    // The FCM payload has no caller display fields or media token.  The call
    // binding re-queries /active and only then renders incoming UI.
    await ref
        .read(liveKitCallInvitationBindingProvider)
        .reconcileFcmInvite(event.callId);
  }
}

Future<void> _consumePendingEvents(Ref ref, String tenantId, String userId) async {
  final pendingClicks = await ref
      .read(imNotificationEventStoreProvider)
      .takePendingClicks('$tenantId:$userId');
  for (final event in pendingClicks) {
    await _routeClick(ref, ImNotificationClick(event));
  }
  final pending = await ref
      .read(imNotificationEventStoreProvider)
      .takePending('$tenantId:$userId');
  for (final event in pending) {
    await _handleNotificationEvent(ref, event);
  }
}

Future<void> _handleNotificationEvent(
  Ref ref,
  ImMessageNotificationEvent event,
) async {
  final session = ref.read(authSessionProvider);
  if (!session.isAuthenticated ||
      session.tenantId != event.tenantId ||
      (event.recipientUserId != null &&
          event.recipientUserId != session.userId)) {
    return;
  }
  final active = ref.read(activeConversationServiceProvider);
  if (AppLifecycleManager().isResumed &&
      active.isViewing &&
      active.currentChatId == event.chatId) {
    return;
  }
  final scope = '${session.tenantId}:${session.userId}';
  if (!await ref
      .read(imNotificationEventStoreProvider)
      .markIfNew(scope, event.eventId)) {
    return;
  }
  await ref.read(imLocalNotificationServiceProvider).showMessage(event);
}

Future<void> _routeClick(Ref ref, ImNotificationClick click) async {
  final session = ref.read(authSessionProvider);
  if (!session.isAuthenticated) {
    await ref.read(imNotificationEventStoreProvider).savePendingClick(click.event);
    return;
  }
  if (session.tenantId != click.event.tenantId ||
      (click.event.recipientUserId != null &&
          click.event.recipientUserId != session.userId)) {
    return;
  }
  final router = ImNotificationRouter(
    resolveChat: (chatId) async {
      final controller = ref.read(conversationListControllerProvider.notifier);
      await controller.load();
      final matches = ref
          .read(conversationListControllerProvider)
          .conversations
          .where((item) => item.chatId == chatId);
      if (matches.isEmpty) return null;
      final conversation = matches.first;
      return ChatEntryArgs.latest(
        chatId: conversation.chatId,
        conversationType: conversation.conversationType,
        targetId: conversation.targetId,
        title: conversation.title,
      );
    },
    openChat: (args) => ref.read(appRouterProvider).goNamed(
      RouteNames.chat,
      extra: args,
    ),
  );
  await router.routeMessage(click.event);
}
