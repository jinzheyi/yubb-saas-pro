import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_auth_payload_builder.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_dispatcher.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_type.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test(
    'auth sends probe and auth envelopes then completes on auth response',
    () async {
      final channel = FakeWebSocketChannel();
      final client = ImSocketClient(
        dispatcher: SocketMessageDispatcher(),
        socketUrl: 'ws://127.0.0.1:9000/ws',
        authPayloadBuilder: SocketAuthPayloadBuilder(),
        channelFactory: (_) => channel,
      );

      await client.connect();
      final authFuture = client.auth(_session());

      expect(channel.sentFrames, hasLength(2));
      final probeFrame =
          jsonDecode(channel.sentFrames.first as String)
              as Map<String, dynamic>;
      final authFrame =
          jsonDecode(channel.sentFrames.last as String) as Map<String, dynamic>;
      expect(probeFrame['header']['messageType'], SocketMessageType.probe);
      expect(authFrame['header']['messageType'], SocketMessageType.authReq);

      channel.emit(<String, dynamic>{
        'header': {
          'messageId': 'auth-1',
          'messageType': SocketMessageType.authResp,
        },
        'body': {'success': true},
      });

      await authFuture;
      expect(client.state.name, 'connected');
      await client.dispose();
    },
  );

  test(
    'transport close emits reconnecting after authenticated session exists',
    () async {
      final firstChannel = FakeWebSocketChannel();
      final events = <String>[];
      final dispatcher = SocketMessageDispatcher();
      final subscription = dispatcher.stream.listen(
        (event) => events.add(event.type),
      );
      final client = ImSocketClient(
        dispatcher: dispatcher,
        socketUrl: 'ws://127.0.0.1:9000/ws',
        authPayloadBuilder: SocketAuthPayloadBuilder(),
        channelFactory: (_) => firstChannel,
      );

      await client.connect();
      final authFuture = client.auth(_session());
      firstChannel.emit(<String, dynamic>{
        'header': {
          'messageId': 'auth-1',
          'messageType': SocketMessageType.authResp,
        },
        'body': {'success': true},
      });
      await authFuture;

      await firstChannel.closeTransport();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events, contains(SocketEventTypes.reconnecting));
      expect(client.state.name, 'reconnectWaiting');

      await subscription.cancel();
      await client.dispose();
    },
  );
}

class FakeWebSocketChannel extends StreamChannelMixin
    implements WebSocketChannel {
  FakeWebSocketChannel();

  final StreamChannelController<Object?> _controller =
      StreamChannelController<Object?>(sync: true, allowForeignErrors: false);
  final List<Object?> sentFrames = <Object?>[];
  final Completer<void> _readyCompleter = Completer<void>()..complete();

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  late final WebSocketSink sink = FakeWebSocketSink(
    _controller.foreign.sink,
    onAdd: sentFrames.add,
  );

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Stream<Object?> get stream => _controller.foreign.stream;

  void emit(Map<String, dynamic> json) {
    _controller.local.sink.add(jsonEncode(json));
  }

  Future<void> closeTransport() async {
    await _controller.local.sink.close();
  }
}

class FakeWebSocketSink extends DelegatingStreamSink implements WebSocketSink {
  FakeWebSocketSink(super.destinationSink, {required this.onAdd});

  final void Function(Object?) onAdd;
  bool _isClosed = false;

  @override
  void add(Object? data) {
    if (_isClosed) {
      throw StateError('sink is closed');
    }
    onAdd(data);
    super.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<Object?> stream) async {
    await for (final value in stream) {
      add(value);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
  }
}

AuthSession _session() {
  return const AuthSession(
    userId: 'user-1',
    accessToken: 'token-1',
    refreshToken: 'refresh-1',
    tenantId: 'tenant-1',
    deviceId: 'device-1',
    deviceType: 1,
    deviceName: 'iPhone',
    clientVersion: '1.0.0',
    locale: 'zh-CN',
  );
}
