import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_signal_event_dto.dart';

class CallSocketDataSource {
  CallSocketDataSource(Stream<ImSocketEvent> socketEvents)
    : _controller = StreamController<CallSignalEventDto>.broadcast() {
    _subscription = socketEvents.listen(
      _onSocketEvent,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[CallSocketDataSource] 流监听错误: $error');
      },
    );
  }

  final StreamController<CallSignalEventDto> _controller;
  StreamSubscription<ImSocketEvent>? _subscription;

  Stream<CallSignalEventDto> watchEvents() {
    return _controller.stream;
  }

  void _onSocketEvent(ImSocketEvent event) {
    if (event.type != SocketEventTypes.systemNotify) {
      return;
    }
    final dto = _toCallSignalEvent(event.payload);
    if (dto == null || _controller.isClosed) {
      return;
    }
    debugPrint(
      '[CallSocketDataSource] 收到通话信令: type=${dto.type}, '
      'callSessionId=${dto.callSessionId}',
    );
    // 防护性添加，避免在 controller 关闭后 add 导致 StateError
    try {
      _controller.add(dto);
    } catch (e) {
      debugPrint('[CallSocketDataSource] 添加事件失败: $e');
    }
  }

  CallSignalEventDto? _toCallSignalEvent(Map<String, Object?> payload) {
    // 兼容多种事件类型字段名
    final eventType =
        payload['type']?.toString() ??
        payload['action']?.toString() ??      // 兼容后端 action 字段
        payload['eventType']?.toString() ??
        payload['event']?.toString() ??
        '';
    if (!eventType.startsWith('call.')) {
      return null;
    }

    // 兼容多种会话ID字段名
    final callSessionId =
        payload['callSessionId']?.toString() ??
        payload['callId']?.toString() ??      // 兼容后端 callId 字段
        payload['sessionId']?.toString() ??
        '';
    if (callSessionId.isEmpty) {
      return null;
    }

    // 合并嵌套的 payload 数据
    final nestedPayload = payload['payload'];
    final mergedPayload = <String, Object?>{
      ...payload,
      if (nestedPayload is Map<String, dynamic>) ...nestedPayload,
      if (nestedPayload is Map<Object?, Object?>)
        for (final entry in nestedPayload.entries)
          if (entry.key is String) entry.key as String: entry.value,
    };

    return CallSignalEventDto(
      type: eventType,
      callSessionId: callSessionId,
      payload: mergedPayload,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
