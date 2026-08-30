import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/firebase_options.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/infrastructure/im_notification_event_store.dart';

/// Enabled only after the matching Firebase client configuration is installed.
const fcmEnabled = bool.fromEnvironment('FCM_ENABLED', defaultValue: false);
// Firebase Console > Cloud Messaging > Web Push certificates. This is a
// public application key, not a service-account secret.
const _webPushVapidKey =
    'BDtSbGBO2yd4h_I8atp4Urn1yiLecIckYIA9QaL2vDTNI4zHZB9u4PpAiT6KVQCRcPZfGdl7Gos-5Cs2Y1S7ai4';

void registerFcmBackgroundHandler() {
  if (fcmEnabled) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!fcmEnabled) return;
  try {
    await _initializeFirebase();
    final event = ImNotificationEvent.fromPayload(
      Map<String, Object?>.from(message.data),
    );
    if (event != null) {
      // The background isolate intentionally does not access Riverpod, HTTP,
      // LiveKit, or any conversation display data.  Foreground bootstrap
      // reconciles business state before it routes this event.
      await ImNotificationEventStore().markIfNew('pending', event.eventId);
      await ImNotificationEventStore().savePending(event);
    }
  } catch (error) {
    debugPrint('[Fcm] background event ignored: $error');
  }
}

class FcmNotificationGateway {
  final _events = StreamController<ImNotificationEvent>.broadcast();
  final _openedEvents = StreamController<ImNotificationEvent>.broadcast();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;

  Stream<ImNotificationEvent> get events => _events.stream;
  /// Events caused by a user tapping an FCM system notification. These must
  /// navigate, not be fed back into the notification presentation policy.
  Stream<ImNotificationEvent> get openedEvents => _openedEvents.stream;
  Stream<String> get tokenRefreshes =>
      FirebaseMessaging.instance.onTokenRefresh;

  Future<void> initialize() async {
    if (_initialized || !fcmEnabled) return;
    try {
      await _initializeFirebase();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _messageSubscription = FirebaseMessaging.onMessage.listen(_emit);
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _emitOpened,
      );
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _emitOpened(initial);
      _initialized = true;
      debugPrint('[Fcm] gateway initialized');
    } catch (error) {
      debugPrint('[Fcm] gateway initialization failed: ${error.runtimeType}');
    }
  }

  Future<String?> currentToken() async {
    if (!_initialized) {
      debugPrint('[Fcm] token unavailable before gateway initialization');
      return null;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? _webPushVapidKey : null,
      );
      debugPrint('[Fcm] token ${token == null || token.isEmpty ? 'unavailable' : 'available'}');
      return token;
    } catch (error) {
      debugPrint('[Fcm] token acquisition failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<String> permissionState() async {
    if (!_initialized) return 'unknown';
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return 'granted';
        case AuthorizationStatus.denied:
        case AuthorizationStatus.deniedPermanently:
          return 'denied';
        case AuthorizationStatus.notDetermined:
          return 'unknown';
      }
    } catch (_) {
      return 'unknown';
    }
  }

  void _emit(RemoteMessage message) {
    final event = ImNotificationEvent.fromPayload(
      Map<String, Object?>.from(message.data),
    );
    if (event != null) _events.add(event);
  }

  void _emitOpened(RemoteMessage message) {
    final event = ImNotificationEvent.fromPayload(
      Map<String, Object?>.from(message.data),
    );
    if (event != null) _openedEvents.add(event);
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _events.close();
    await _openedEvents.close();
  }
}

Future<void> _initializeFirebase() {
  if (Firebase.apps.isNotEmpty) return Future.value();
  // Android and future iOS configuration are read from their native config
  // files. Web has no such file, so it must receive public options explicitly.
  return kIsWeb
      ? Firebase.initializeApp(options: DefaultFirebaseOptions.web)
      : Firebase.initializeApp();
}
