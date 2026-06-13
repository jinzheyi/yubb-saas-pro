import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_envelope.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_auth_payload_builder.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_inbound_mapper.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_dispatcher.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final socketMessageDispatcherProvider = Provider<SocketMessageDispatcher>((
  ref,
) {
  final dispatcher = SocketMessageDispatcher();
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});

final imSocketClientProvider = Provider<ImSocketClient>((ref) {
  final client = ImSocketClient(
    dispatcher: ref.read(socketMessageDispatcherProvider),
    socketUrl: AppConfig.socketUrl,
    authPayloadBuilder: SocketAuthPayloadBuilder(),
  );
  ref.onDispose(client.dispose);
  return client;
});

typedef SocketChannelFactory = WebSocketChannel Function(Uri uri);

class ImSocketClient {
  ImSocketClient({
    required SocketMessageDispatcher dispatcher,
    required String socketUrl,
    required SocketAuthPayloadBuilder authPayloadBuilder,
    SocketChannelFactory? channelFactory,
  }) : _dispatcher = dispatcher,
       _socketUrl = socketUrl,
       _authPayloadBuilder = authPayloadBuilder,
       _inboundMapper = const SocketInboundMapper(),
       _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final SocketMessageDispatcher _dispatcher;
  final String _socketUrl;
  final SocketAuthPayloadBuilder _authPayloadBuilder;
  final SocketInboundMapper _inboundMapper;
  final SocketChannelFactory _channelFactory;
  final StreamController<ImSocketConnectionState> _stateController =
      StreamController<ImSocketConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _heartbeatTimeoutTimer;
  Timer? _reconnectTimer;
  Future<void>? _reconnectFuture;
  Completer<void>? _authCompleter;
  AuthSession? _activeSession;

  ImSocketConnectionState _state = ImSocketConnectionState.disconnected;
  bool _manualDisconnect = false;
  bool _allowReconnect = true;
  bool _disposed = false;
  int _reconnectAttempts = 0;

  Stream<ImSocketEvent> get events => _dispatcher.stream;
  Stream<ImSocketConnectionState> get states => _stateController.stream;
  ImSocketConnectionState get state => _state;
  bool get canSendBusinessMessage =>
      _channel != null && _state == ImSocketConnectionState.connected;

  Future<void> connect() async {
    if (_disposed) {
      return;
    }
    if (_state == ImSocketConnectionState.connected ||
        _state == ImSocketConnectionState.connecting ||
        _state == ImSocketConnectionState.authenticating ||
        _state == ImSocketConnectionState.reauthenticating) {
      return;
    }

    _manualDisconnect = false;
    _allowReconnect = true;
    await _closeChannel();
    _setState(ImSocketConnectionState.connecting);
    _dispatcher.dispatch(
      ImSocketEvent(
        type: SocketEventTypes.connectRequested,
        payload: {'socketUrl': _socketUrl},
      ),
    );
    final channel = _channelFactory(Uri.parse(_socketUrl));
    _channel = channel;

    // ===== 企业级：等待 WebSocket ready，避免在连接未建立时发送消息 =====
    await channel.ready;

    _channelSubscription = channel.stream.listen(
      _handleInboundFrame,
      onError: _handleTransportError,
      onDone: _handleTransportClosed,
      cancelOnError: true,
    );
    _setState(ImSocketConnectionState.connected);
    _dispatcher.dispatch(const ImSocketEvent(type: SocketEventTypes.connected));
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _allowReconnect = false;
    _activeSession = null;
    _reconnectAttempts = 0;
    _cancelReconnectTimer();
    _clearHeartbeatTimers();
    _completeAuthWithError(StateError('Socket disconnected'));
    await _closeChannel();
    _setState(ImSocketConnectionState.disconnected);
    _dispatcher.dispatch(
      const ImSocketEvent(type: SocketEventTypes.disconnected),
    );
  }

  Future<void> auth(AuthSession session) async {
    if (session.accessToken.isEmpty) {
      return;
    }
    _activeSession = session;
    if (_channel == null) {
      await connect();
    }
    _setState(ImSocketConnectionState.authenticating);
    _authCompleter = Completer<void>();
    _sendEnvelope(_authPayloadBuilder.buildProbeEnvelope(session));
    _dispatcher.dispatch(
      ImSocketEvent(
        type: SocketEventTypes.authRequested,
        payload: _authPayloadBuilder.buildAuthEnvelope(session),
      ),
    );
    _sendEnvelope(_authPayloadBuilder.buildAuthEnvelope(session));
    final success = await _awaitAuthResult();
    if (!success) {
      throw TimeoutException('Socket auth timeout', AppConfig.socketAuthTimeout);
    }
  }

  void handleAuthResponse({
    required bool success,
    int code = 0,
    String message = '',
  }) {
    if (success) {
      _reconnectAttempts = 0;
      _clearHeartbeatTimeout();
      _startHeartbeat();
      _completeAuthSuccessfully();
      _dispatcher.dispatch(
        const ImSocketEvent(type: SocketEventTypes.authSucceeded),
      );
      _setState(ImSocketConnectionState.connected);
      return;
    }

    _clearHeartbeatTimers();
    _completeAuthWithError(
      StateError(message.isEmpty ? 'Socket auth failed' : message),
    );
    _dispatcher.dispatch(
      ImSocketEvent(
        type: SocketEventTypes.authFailed,
        payload: {'code': code, 'message': message},
      ),
    );
    if (code == 401) {
      _dispatcher.dispatch(
        ImSocketEvent(
          type: SocketEventTypes.sessionReauthRequired,
          payload: {'message': message},
        ),
      );
    } else if (code == 400 || code == 403) {
      _dispatcher.dispatch(
        ImSocketEvent(
          type: SocketEventTypes.sessionInvalidated,
          payload: {'message': message},
        ),
      );
    }
    _setState(ImSocketConnectionState.invalidated);
  }

  void handleCloseMessage({
    required String action,
    String message = '',
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    _clearHeartbeatTimers();
    _dispatcher.dispatch(
      ImSocketEvent(
        type: SocketEventTypes.closeByServer,
        payload: {'action': action, 'message': message, ...payload},
      ),
    );

    switch (action) {
      case 'REAUTH_REQUIRED':
        _allowReconnect = false;
        _dispatcher.dispatch(
          ImSocketEvent(
            type: SocketEventTypes.sessionReauthRequired,
            payload: {'message': message, ...payload},
          ),
        );
        _setState(ImSocketConnectionState.invalidated);
        break;
      case 'KICKED':
        _allowReconnect = false;
        _dispatcher.dispatch(
          ImSocketEvent(
            type: SocketEventTypes.sessionKicked,
            payload: {'message': message, ...payload},
          ),
        );
        _setState(ImSocketConnectionState.invalidated);
        break;
      case 'LOGOUT':
        _allowReconnect = false;
        _dispatcher.dispatch(
          ImSocketEvent(
            type: SocketEventTypes.sessionLoggedOut,
            payload: {'message': message, ...payload},
          ),
        );
        _setState(ImSocketConnectionState.invalidated);
        break;
      case 'REVOKED':
        _allowReconnect = false;
        _dispatcher.dispatch(
          ImSocketEvent(
            type: SocketEventTypes.sessionRevoked,
            payload: {'message': message, ...payload},
          ),
        );
        _setState(ImSocketConnectionState.invalidated);
        break;
      default:
        _setState(ImSocketConnectionState.disconnected);
        break;
    }
  }

  void emitConversationHint({required String chatId}) {
    _dispatcher.dispatch(
      ImSocketEvent(type: SocketEventTypes.conversationHint, chatId: chatId),
    );
  }

  void emitMessageReceived({
    required String chatId,
    required Map<String, Object?> payload,
  }) {
    _dispatcher.dispatch(
      ImSocketEvent(
        type: SocketEventTypes.messageReceived,
        chatId: chatId,
        messageId: payload['messageId']?.toString(),
        payload: payload,
      ),
    );
  }

  void emitReadReceiptChanged({
    required String chatId,
    required String messageId,
  }) {
    _dispatcher.dispatch(
      ImSocketEvent(
        type: SocketEventTypes.readReceiptChanged,
        chatId: chatId,
        messageId: messageId,
      ),
    );
  }

  void notifyHeartbeatTimeout() {
    _clearHeartbeatTimers();
    _dispatcher.dispatch(
      const ImSocketEvent(type: SocketEventTypes.heartbeatTimeout),
    );
    _setState(ImSocketConnectionState.reconnectWaiting);
    unawaited(_scheduleReconnect());
  }

  void handleInboundJson(Map<String, dynamic> json) {
    _clearHeartbeatTimeout();
    final envelope = SocketEnvelope.fromJson(json);
    final events = _inboundMapper.map(envelope);
    for (final event in events) {
      _dispatchMappedEvent(event);
    }
  }

  bool handleInboundRaw(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return false;
      }
      handleInboundJson(json);
      return true;
    } on FormatException {
      return false;
    }
  }

  Future<void> reauth(AuthSession session) async {
    if (session.accessToken.isEmpty) {
      return;
    }
    _activeSession = session;
    _setState(ImSocketConnectionState.reauthenticating);
    _dispatcher.dispatch(
      const ImSocketEvent(type: SocketEventTypes.tokenRefreshed),
    );
    _authCompleter = Completer<void>();
    _sendEnvelope(_authPayloadBuilder.buildAuthEnvelope(session));
    final success = await _awaitAuthResult();
    if (!success) {
      throw TimeoutException('Socket auth timeout', AppConfig.socketAuthTimeout);
    }
  }

  Future<void> reconnect() async {
    await _scheduleReconnect(immediate: true);
  }

  Future<bool> sendEnvelope(
    Map<String, Object?> envelope, {
    bool requireAuthenticated = true,
  }) async {
    if (_channel == null) {
      return false;
    }
    if (requireAuthenticated && _state != ImSocketConnectionState.connected) {
      return false;
    }
    _sendEnvelope(envelope);
    return true;
  }

  Future<void> dispose() async {
    _disposed = true;
    _manualDisconnect = true;
    _allowReconnect = false;
    _cancelReconnectTimer();
    _clearHeartbeatTimers();
    _completeAuthWithError(StateError('Socket disposed'));
    await _closeChannel();
    await _stateController.close();
  }

  void _setState(ImSocketConnectionState nextState) {
    _state = nextState;
    if (!_stateController.isClosed) {
      _stateController.add(nextState);
    }
  }

  void _dispatchMappedEvent(ImSocketEvent event) {
    switch (event.type) {
      case SocketEventTypes.authSucceeded:
        handleAuthResponse(success: true);
        break;
      case SocketEventTypes.authFailed:
        handleAuthResponse(
          success: false,
          code: (event.payload['code'] as num?)?.toInt() ?? 0,
          message: event.payload['message']?.toString() ?? '',
        );
        break;
      case SocketEventTypes.closeByServer:
        handleCloseMessage(
          action: event.payload['action']?.toString() ?? '',
          message: event.payload['message']?.toString() ?? '',
          payload: event.payload,
        );
        break;
      default:
        _dispatcher.dispatch(event);
        break;
    }
  }

  Future<bool> _awaitAuthResult() async {
    final completer = _authCompleter;
    if (completer == null) {
      return true;
    }
    try {
      await completer.future.timeout(AppConfig.socketAuthTimeout);
      return true;
    } on TimeoutException {
      _completeAuthWithError(
        TimeoutException('Socket auth timeout', AppConfig.socketAuthTimeout),
      );
      return false;
    } catch (error) {
      return false;
    }
  }

  void _handleInboundFrame(Object? data) {
    if (data is String) {
      handleInboundRaw(data);
      return;
    }
    if (data is List<int>) {
      handleInboundRaw(utf8.decode(data));
    }
  }

  void _handleTransportError(Object error, StackTrace stackTrace) {
    _clearHeartbeatTimers();
    _completeAuthWithError(error);
    _setState(ImSocketConnectionState.reconnectWaiting);
    unawaited(_scheduleReconnect());
  }

  void _handleTransportClosed() {
    _clearHeartbeatTimers();
    if (_authCompleter != null) {
      _completeAuthWithError(StateError('Socket transport closed'));
    }
    if (_manualDisconnect || _disposed) {
      return;
    }
    _setState(ImSocketConnectionState.reconnectWaiting);
    unawaited(_scheduleReconnect());
  }

  Future<void> _scheduleReconnect({bool immediate = false}) async {
    if (!_allowReconnect || _disposed || _manualDisconnect) {
      return;
    }
    final session = _activeSession;
    if (session == null || !session.isAuthenticated) {
      return;
    }
    final inflight = _reconnectFuture;
    if (inflight != null) {
      return inflight;
    }

    final completer = Completer<void>();
    _reconnectFuture = completer.future;
    try {
      final delay = immediate
          ? Duration.zero
          : _nextReconnectDelay(++_reconnectAttempts);
      if (_reconnectAttempts > AppConfig.socketMaxReconnectAttempts &&
          !immediate) {
        _setState(ImSocketConnectionState.disconnected);
        return;
      }
      _setState(ImSocketConnectionState.reconnectWaiting);
      _dispatcher.dispatch(
        const ImSocketEvent(type: SocketEventTypes.reconnecting),
      );
      if (delay > Duration.zero) {
        await _waitReconnectDelay(delay);
      }
      if (_disposed || _manualDisconnect || !_allowReconnect) {
        return;
      }
      await connect();
      try {
        await auth(session);
      } catch (_) {
        // Auth failed during reconnect, _completeAuthWithError already dispatched events
        // Reconnect will be scheduled via _handleTransportError or notifyHeartbeatTimeout
      }
    } finally {
      _reconnectFuture = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Duration _nextReconnectDelay(int attempt) {
    final base = AppConfig.socketReconnectBaseDelay.inMilliseconds;
    final max = AppConfig.socketReconnectMaxDelay.inMilliseconds;
    final exponent = attempt <= 1 ? 0 : attempt - 1;
    final next = base * (1 << exponent.clamp(0, 10));
    final millis = next > max ? max : next;
    return Duration(milliseconds: millis);
  }

  Future<void> _waitReconnectDelay(Duration delay) {
    final completer = Completer<void>();
    _cancelReconnectTimer();
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startHeartbeat() {
    _clearHeartbeatTimers();
    _heartbeatTimer = Timer.periodic(AppConfig.socketHeartbeatInterval, (_) {
      _sendEnvelope(_authPayloadBuilder.buildHeartbeatEnvelope());
      _heartbeatTimeoutTimer?.cancel();
      _heartbeatTimeoutTimer = Timer(
        AppConfig.socketHeartbeatTimeout,
        notifyHeartbeatTimeout,
      );
    });
  }

  void _clearHeartbeatTimers() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _clearHeartbeatTimeout();
  }

  void _clearHeartbeatTimeout() {
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = null;
  }

  Future<void> _closeChannel() async {
    final subscription = _channelSubscription;
    _channelSubscription = null;
    await subscription?.cancel();
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }

  void _sendEnvelope(Map<String, Object?> envelope) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('Socket channel is not connected');
    }
    channel.sink.add(jsonEncode(envelope));
  }

  void _completeAuthSuccessfully() {
    final completer = _authCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _authCompleter = null;
  }

  void _completeAuthWithError(Object error) {
    final completer = _authCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
    _authCompleter = null;
  }
}
