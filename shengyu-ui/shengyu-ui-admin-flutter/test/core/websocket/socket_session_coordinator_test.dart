import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_auth_payload_builder.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_dispatcher.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_session_coordinator.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';

void main() {
  late RecordingSocketClient socketClient;
  late SocketSessionCoordinator coordinator;

  setUp(() {
    socketClient = RecordingSocketClient();
    coordinator = SocketSessionCoordinator(socketClient);
  });

  test(
    'connects and authenticates when session becomes authenticated',
    () async {
      coordinator.onSessionChanged(null, _session(accessToken: 'token-a'));
      await coordinator.waitForIdle();

      expect(socketClient.operations, <String>['connect', 'auth:token-a']);
    },
  );

  test('reauthenticates when access token changes', () async {
    coordinator.onSessionChanged(
      _session(accessToken: 'token-a'),
      _session(accessToken: 'token-b'),
    );
    await coordinator.waitForIdle();

    expect(socketClient.operations, <String>['reauth:token-b']);
  });

  test('disconnects when session becomes anonymous', () async {
    coordinator.onSessionChanged(
      _session(accessToken: 'token-a'),
      AuthSession.anonymous(),
    );
    await coordinator.waitForIdle();

    expect(socketClient.operations, <String>['disconnect']);
  });

  test(
    'force reconnect restores authentication for the current session',
    () async {
      coordinator.onSessionChanged(null, _session(accessToken: 'token-a'));
      await coordinator.waitForIdle();
      socketClient.operations.clear();

      coordinator.forceReconnect();
      await coordinator.waitForIdle();

      expect(socketClient.operations, <String>[
        'disconnect',
        'connect',
        'auth:token-a',
      ]);
    },
  );

  test('force reconnect does not create an anonymous transport', () async {
    coordinator.onSessionChanged(null, AuthSession.anonymous());
    await coordinator.waitForIdle();
    socketClient.operations.clear();

    coordinator.forceReconnect();
    await coordinator.waitForIdle();

    expect(socketClient.operations, isEmpty);
  });
}

class RecordingSocketClient extends ImSocketClient {
  RecordingSocketClient()
    : operations = <String>[],
      super(
        dispatcher: SocketMessageDispatcher(),
        socketUrl: 'ws://127.0.0.1:9000/ws',
        authPayloadBuilder: SocketAuthPayloadBuilder(),
      );

  final List<String> operations;
  ImSocketConnectionState recordedState = ImSocketConnectionState.disconnected;

  @override
  ImSocketConnectionState get state => recordedState;

  @override
  Future<void> connect() async {
    operations.add('connect');
    recordedState = ImSocketConnectionState.connected;
  }

  @override
  Future<void> auth(AuthSession session) async {
    operations.add('auth:${session.accessToken}');
  }

  @override
  Future<void> reauth(AuthSession session) async {
    operations.add('reauth:${session.accessToken}');
  }

  @override
  Future<void> disconnect() async {
    operations.add('disconnect');
    recordedState = ImSocketConnectionState.disconnected;
  }
}

AuthSession _session({required String accessToken}) {
  return AuthSession(
    userId: 'user-1',
    accessToken: accessToken,
    refreshToken: 'refresh-1',
    tenantId: 'tenant-1',
    deviceId: 'device-1',
    deviceType: 1,
    deviceName: 'iPhone',
    clientVersion: '1.0.0',
    locale: 'zh-CN',
  );
}
