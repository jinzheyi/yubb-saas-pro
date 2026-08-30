import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/application/im_notification_presentation_policy.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';

class ImNotificationClick {
  const ImNotificationClick(this.event);
  final ImMessageNotificationEvent event;
}

class ImLocalNotificationService {
  ImLocalNotificationService({ImNotificationPresentationPolicy? policy})
    : _plugin = FlutterLocalNotificationsPlugin(),
      _policy = policy ?? const ImNotificationPresentationPolicy();
  final FlutterLocalNotificationsPlugin _plugin;
  final ImNotificationPresentationPolicy _policy;
  final _clicks = StreamController<ImNotificationClick>.broadcast();
  bool _initialized = false;
  ImNotificationClick? _launchClick;
  final Map<String, int> _recentChats = <String, int>{};
  static const _summaryId = 2147483000;
  static const _aggregationWindow = Duration(seconds: 30);
  Stream<ImNotificationClick> get clicks => _clicks.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final raw = response.payload;
        if (raw == null) {
          return;
        }
        try {
          final event = ImNotificationEvent.fromPayload(
            Map<String, Object?>.from(jsonDecode(raw) as Map),
          );
          if (event is ImMessageNotificationEvent) {
            _clicks.add(ImNotificationClick(event));
          }
        } catch (_) {}
      },
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse?.payload != null) {
      _launchClick = _clickFromPayload(launchResponse!.payload!);
    }
    const channel = AndroidNotificationChannel(
      'im_messages',
      'IM 消息',
      description: '即时通讯消息提醒',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    const mentions = AndroidNotificationChannel(
      'im_mentions',
      'IM 提醒',
      description: '@我和重要群消息提醒',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(mentions);
    _initialized = true;
  }

  /// Returns the local-notification tap that launched a terminated app.
  /// Stream listeners are not yet installed while plugin initialization runs.
  ImNotificationClick? takeLaunchClick() {
    final click = _launchClick;
    _launchClick = null;
    return click;
  }

  ImNotificationClick? _clickFromPayload(String raw) {
    try {
      final event = ImNotificationEvent.fromPayload(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      return event is ImMessageNotificationEvent
          ? ImNotificationClick(event)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted && (iosGranted ?? true);
  }

  Future<void> showMessage(ImMessageNotificationEvent event) async {
    await initialize();
    _rememberChat(event.chatId);
    final presentation = _policy.forMessage(event);
    final payload = jsonEncode({
      'v': '1',
      'kind': 'im_message',
      'eventId': event.eventId,
      'tenantId': event.tenantId,
      if (event.recipientUserId != null)
        'recipientUserId': event.recipientUserId,
      'chatId': event.chatId,
      'messageId': event.messageId,
      'sentAt': event.sentAt.toString(),
    });
    await _plugin.show(
      event.chatId.hashCode,
      presentation.title,
      presentation.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          presentation.androidChannelId,
          presentation.androidChannelName,
          channelDescription: '即时通讯消息提醒',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: presentation.groupKey,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
    if (!event.isMention && _recentChats.length > 1) {
      await _plugin.show(
        _summaryId,
        '圣钰科技 IM',
        '你有 ${_recentChats.length} 个会话的新消息',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'im_messages',
            'IM 消息',
            channelDescription: '即时通讯消息提醒',
            groupKey: 'im_messages',
            setAsGroupSummary: true,
            groupAlertBehavior: GroupAlertBehavior.children,
            importance: Importance.defaultImportance,
          ),
        ),
      );
    }
  }

  Future<void> cancelForChat(String chatId) async {
    _recentChats.remove(chatId);
    await _plugin.cancel(chatId.hashCode);
    if (_recentChats.length <= 1) await _plugin.cancel(_summaryId);
  }

  Future<void> cancelAllForUserScope() async {
    _recentChats.clear();
    await _plugin.cancelAll();
  }

  void _rememberChat(String chatId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - _aggregationWindow.inMilliseconds;
    _recentChats.removeWhere((_, seenAt) => seenAt < cutoff);
    _recentChats[chatId] = now;
  }
}
