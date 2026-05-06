import 'dart:async';

import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_signal_event_dto.dart';

class CallSocketDataSource {
  CallSocketDataSource(Stream<ImSocketEvent> socketEvents)
    : _controller = StreamController<CallSignalEventDto>.broadcast() {
    _subscription = socketEvents.listen(_onSocketEvent);
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
    _controller.add(dto);
  }

  CallSignalEventDto? _toCallSignalEvent(Map<String, Object?> payload) {
    final eventType =
        payload['type']?.toString() ??
        payload['eventType']?.toString() ??
        payload['event']?.toString() ??
        '';
    if (!eventType.startsWith('call.')) {
      return null;
    }

    final callSessionId =
        payload['callSessionId']?.toString() ??
        payload['sessionId']?.toString() ??
        '';
    if (callSessionId.isEmpty) {
      return null;
    }

    final nestedPayload = payload['payload'];
    final mergedPayload = <String, Object?>{
      ...payload,
      if (nestedPayload is Map<String, dynamic>) ...nestedPayload,
      if (nestedPayload is Map<Object?, Object?>)
        ...nestedPayload.cast<String, Object?>(),
    };

    return CallSignalEventDto(
      type: eventType,
      callSessionId: callSessionId,
      payload: mergedPayload,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
