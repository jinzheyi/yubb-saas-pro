import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';

/// Small persistent deduplication window. It stores event ids only, never a
/// message preview, token, or credential.
class ImNotificationEventStore {
  static const _seenKey = 'im.notification.seen.v1';
  static const _pendingKey = 'im.notification.pending.v1';
  static const _pendingClickKey = 'im.notification.pending-click.v1';
  static const _maxEvents = 300;

  Future<bool> markIfNew(String scope, String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_seenKey) ?? <String>[];
    final key = '$scope:$eventId';
    if (values.contains(key)) return false;
    values.add(key);
    await prefs.setStringList(
      _seenKey,
      values.length > _maxEvents
          ? values.sublist(values.length - _maxEvents)
          : values,
    );
    return true;
  }

  Future<void> clearScope(String scope) async {
    final parts = scope.split(':');
    if (parts.length != 2) return;
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_seenKey) ?? <String>[];
    await prefs.setStringList(
      _seenKey,
      values.where((value) => !value.startsWith('$scope:')).toList(),
    );
    await _clearScopedPayloads(prefs, _pendingKey, parts);
    await _clearScopedPayloads(prefs, _pendingClickKey, parts);
  }

  Future<void> _clearScopedPayloads(
    SharedPreferences prefs,
    String key,
    List<String> parts,
  ) async {
    final pending = prefs.getStringList(key) ?? <String>[];
    await prefs.setStringList(
      key,
      pending.where((raw) {
        final payload = _decode(raw);
        return payload == null ||
            payload['tenantId'] != parts[0] ||
            payload['recipientUserId'] != parts[1];
      }).toList(),
    );
  }

  /// Background isolates can persist only recipient-scoped routing data. Call
  /// events intentionally lack recipient ids and are reconciled from /active
  /// after authentication instead of being routed across accounts.
  Future<void> savePending(ImNotificationEvent event) async {
    if (event is ImMessageNotificationEvent) {
      await _savePendingEvent(event, _pendingKey);
    }
  }

  Future<List<ImMessageNotificationEvent>> takePending(String scope) async {
    return _takeScopedEvents(scope, _pendingKey);
  }

  Future<void> savePendingClick(ImMessageNotificationEvent event) async {
    await _savePendingEvent(event, _pendingClickKey);
  }

  Future<List<ImMessageNotificationEvent>> takePendingClicks(String scope) {
    return _takeScopedEvents(scope, _pendingClickKey);
  }

  Future<void> _savePendingEvent(
    ImMessageNotificationEvent event,
    String key,
  ) async {
    if (event.recipientUserId == null || event.recipientUserId!.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(key) ?? <String>[];
    final payload = jsonEncode({
      'v': '1',
      'kind': 'im_message',
      'eventId': event.eventId,
      'tenantId': event.tenantId,
      'recipientUserId': event.recipientUserId,
      'chatId': event.chatId,
      'messageId': event.messageId,
      'sentAt': event.sentAt.toString(),
      'isMention': event.isMention.toString(),
    });
    if (!pending.any((raw) => _decode(raw)?['eventId'] == event.eventId)) {
      pending.add(payload);
      await prefs.setStringList(
        key,
        pending.length > _maxEvents
            ? pending.sublist(pending.length - _maxEvents)
            : pending,
      );
    }
  }

  Future<List<ImMessageNotificationEvent>> _takeScopedEvents(
    String scope,
    String key,
  ) async {
    final parts = scope.split(':');
    if (parts.length != 2) return const <ImMessageNotificationEvent>[];
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(key) ?? <String>[];
    final events = <ImMessageNotificationEvent>[];
    final retained = <String>[];
    for (final raw in pending) {
      final payload = _decode(raw);
      final event = payload == null ? null : ImNotificationEvent.fromPayload(payload);
      if (event is ImMessageNotificationEvent &&
          event.tenantId == parts[0] &&
          event.recipientUserId == parts[1]) {
        events.add(event);
      } else {
        retained.add(raw);
      }
    }
    await prefs.setStringList(key, retained);
    return events;
  }

  Map<String, Object?>? _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, Object?>.from(value) : null;
    } catch (_) {
      return null;
    }
  }
}
