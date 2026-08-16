import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Janus 连接状态
enum JanusConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Janus Gateway 客户端
/// 
/// 负责与 Janus 服务器建立 WebSocket 连接，处理信令交互。
/// 支持 videoroom 插件的发布/订阅模式。
/// 
/// 企业级特性：
/// - 心跳保活机制（每 30 秒发送 keep-alive）
/// - 指数退避重连策略（最多 5 次重试）
/// - 连接状态监听
/// - 事务超时处理
class JanusClient {
  JanusClient({
    required this.janusUrl,
    required this.turnUrls,
    this.turnUsername = '',
    this.turnCredential = '',
    this.token = '',
    this.heartbeatIntervalSeconds = 30,
    this.maxReconnectAttempts = 5,
  });

  final String janusUrl;
  final List<String> turnUrls;
  final String turnUsername;
  final String turnCredential;
  final String token;
  final int heartbeatIntervalSeconds;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  /// WebSocket 订阅（用于取消监听）
  StreamSubscription<dynamic>? _channelSubscription;
  String? _sessionId;
  String? _handleId;
  String? _subscriberHandleId;
  int _transactionCounter = 0;
  
  JanusConnectionState _connectionState = JanusConnectionState.disconnected;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  
  final Map<String, Completer<Map<String, dynamic>>> _pendingTransactions = {};
  final StreamController<Map<String, dynamic>> _eventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<JanusConnectionState> _connectionStateController =
      StreamController<JanusConnectionState>.broadcast();
  
  Stream<Map<String, dynamic>> get events => _eventController.stream;
  
  /// 连接状态变化流
  Stream<JanusConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// 当前连接状态
  JanusConnectionState get connectionState => _connectionState;
  
  /// 是否已连接
  bool get isConnected => _connectionState == JanusConnectionState.connected;
  
  /// 连接到 Janus 服务器
  Future<void> connect() async {
    try {
      _updateConnectionState(JanusConnectionState.connecting);
      
      // Janus WebSocket transport requires the `janus-protocol` subprotocol.
      // Without it Janus closes the TCP connection before the browser receives
      // a WebSocket upgrade response, which surfaces as a generic handshake error.
      _channel = WebSocketChannel.connect(
        Uri.parse(janusUrl),
        protocols: const <String>['janus-protocol'],
      );

      // WebSocketChannel.connect returns before the browser/native socket has
      // completed its handshake. Wait here so the first Janus `create` request
      // cannot be written to a channel that has already been rejected.
      await _channel!.ready;
      
      // 关键修复：存储订阅引用，防止内存泄漏
      _channelSubscription = _channel!.stream.listen(
        (data) => _onMessage(data),
        onError: (error) {
          debugPrint('[JanusClient] WebSocket 错误: $error');
          _eventController.addError(error);
          _handleConnectionLost();
        },
        onDone: () {
          debugPrint('[JanusClient] WebSocket 连接关闭');
          _handleConnectionLost();
        },
      );
      
      // 创建会话
      final createResponse = await _sendRequest({
        'janus': 'create',
        'transaction': _nextTransactionId(),
      });
      
      if (createResponse['janus'] == 'success') {
        _sessionId = createResponse['data']['id']?.toString();
      } else {
        throw Exception('Failed to create Janus session: ${createResponse['error']}');
      }
      
      // 附加 videoroom 插件
      final attachResponse = await _sendRequest({
        'janus': 'attach',
        'session_id': int.parse(_sessionId!),
        'plugin': 'janus.plugin.videoroom',
        'transaction': _nextTransactionId(),
      });
      
      if (attachResponse['janus'] == 'success') {
        _handleId = attachResponse['data']['id']?.toString();
      } else {
        throw Exception('Failed to attach videoroom plugin: ${attachResponse['error']}');
      }
      
      // 连接成功，启动心跳
      _updateConnectionState(JanusConnectionState.connected);
      _startHeartbeat();
      _reconnectAttempts = 0;
      
      debugPrint('[JanusClient] 连接成功, sessionId=$_sessionId, handleId=$_handleId');
    } catch (e) {
      await _cleanupOldConnection();
      _updateConnectionState(JanusConnectionState.disconnected);
      throw Exception('Failed to connect to Janus: $e');
    }
  }
  
  /// 启动心跳保活
  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: heartbeatIntervalSeconds),
      (_) => _sendKeepAlive(),
    );
    
    debugPrint('[JanusClient] 心跳已启动, 间隔=$heartbeatIntervalSeconds秒');
  }
  
  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  /// 发送 keep-alive 消息
  Future<void> _sendKeepAlive() async {
    if (_sessionId == null) return;
    
    try {
      await _sendRequest({
        'janus': 'keepalive',
        'session_id': int.parse(_sessionId!),
        'transaction': _nextTransactionId(),
      });
      debugPrint('[JanusClient] 心跳发送成功');
    } catch (e) {
      debugPrint('[JanusClient] 心跳发送失败: $e');
      _handleConnectionLost();
    }
  }
  
  /// 处理连接丢失
  void _handleConnectionLost() {
    if (_connectionState == JanusConnectionState.disconnected) return;
    
    debugPrint('[JanusClient] 连接丢失, 尝试重连...');
    _stopHeartbeat();
    _updateConnectionState(JanusConnectionState.reconnecting);
    
    _attemptReconnect();
  }
  
  /// 尝试重连（指数退避策略）
  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('[JanusClient] 重连次数已达上限 ($maxReconnectAttempts)');
      _updateConnectionState(JanusConnectionState.disconnected);
      _eventController.addError(Exception('重连失败: 已达最大重试次数'));
      return;
    }
    
    _reconnectAttempts++;
    
    // 指数退避: 1s, 2s, 4s, 8s, 16s
    final delaySeconds = _calculateBackoffDelay(_reconnectAttempts);
    debugPrint('[JanusClient] $delaySeconds秒后进行第 $_reconnectAttempts 次重连');
    
    await Future.delayed(Duration(seconds: delaySeconds));
    
    try {
      // 关键修复：重连前先清理旧的连接资源，防止资源泄漏
      await _cleanupOldConnection();
      await connect();
      debugPrint('[JanusClient] 重连成功');
    } catch (e) {
      debugPrint('[JanusClient] 重连失败: $e');
      _attemptReconnect();
    }
  }
  
  /// 清理旧的连接资源（重连前调用）
  Future<void> _cleanupOldConnection() async {
    debugPrint('[JanusClient] 清理旧的连接资源');
    
    // 取消旧的 WebSocket 订阅
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    
    // 关闭旧的 WebSocket 连接
    await _channel?.sink.close();
    _channel = null;
    
    // 清理会话 ID
    _sessionId = null;
    _handleId = null;
    _subscriberHandleId = null;
    
    // 清理所有待处理的事务（避免内存泄漏）
    for (final completer in _pendingTransactions.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Connection cleanup during reconnect'));
      }
    }
    _pendingTransactions.clear();
  }
  
  /// 计算指数退避延迟
  int _calculateBackoffDelay(int attempt) {
    // 指数退避: 2^(attempt-1) 秒，最大 30 秒
    final delay = (1 << (attempt - 1)).clamp(1, 30);
    return delay;
  }
  
  /// 更新连接状态
  void _updateConnectionState(JanusConnectionState newState) {
    if (_connectionState == newState) return;
    
    _connectionState = newState;
    _connectionStateController.add(newState);
    debugPrint('[JanusClient] 连接状态变更: $newState');
  }

  /// 加入房间（发布模式）
  Future<Map<String, dynamic>> joinRoom({
    required int roomId,
    required String displayName,
    required MediaStream localStream,
  }) async {
    if (_sessionId == null || _handleId == null) {
      throw Exception('Janus not connected');
    }

    // 创建 RTCPeerConnection
    final peerConnection = await _createPeerConnection(localStream);
    
    // 监听 ICE 候选
    peerConnection.onIceCandidate = (candidate) {
      _sendTrickle(candidate);
    };

    // 发送 join 请求
    final joinResponse = await _sendRequest({
      'janus': 'message',
      'session_id': int.parse(_sessionId!),
      'handle_id': int.parse(_handleId!),
      'body': {
        'request': 'join',
        'ptype': 'publisher',
        'room': roomId,
        'display': displayName,
      },
      'transaction': _nextTransactionId(),
    });

    if (joinResponse['janus'] != 'event' ||
        _videoRoomData(joinResponse)['videoroom'] != 'joined') {
      throw Exception('Failed to join room: ${joinResponse['error']}');
    }

    // 创建 offer
    final offer = await peerConnection.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });

    await peerConnection.setLocalDescription(offer);

    // 发送 JSEP offer
    final publishResponse = await _sendRequest({
      'janus': 'message',
      'session_id': int.parse(_sessionId!),
      'handle_id': int.parse(_handleId!),
      'body': {
        'request': 'publish',
        // 不要为纯语音通话声明视频发布；否则不同平台的 SDP 协商会出现
        // 无实际 video track 却要求 video m-line 的不一致。
        'audio': localStream.getAudioTracks().isNotEmpty,
        'video': localStream.getVideoTracks().isNotEmpty,
      },
      'jsep': {
        'type': 'offer',
        'sdp': offer.sdp,
      },
      'transaction': _nextTransactionId(),
    });

    if (publishResponse['janus'] != 'event') {
      throw Exception('Failed to publish: ${publishResponse['error']}');
    }

    // Janus 的异步插件响应会携带同一 transaction；_sendRequest 已等待到该
    // event，不能再从事件流二次等待，否则会错过响应而超时。
    final answerSdp = publishResponse['jsep']?['sdp'] as String?;
    if (answerSdp == null || publishResponse['jsep']?['type'] != 'answer') {
      throw Exception('Janus publish 未返回 SDP answer');
    }
    await peerConnection.setRemoteDescription(RTCSessionDescription(answerSdp, 'answer'));

    return {
      'peerConnection': peerConnection,
      'roomId': roomId,
      'publisherId': _handleId,
      'publishers': _videoRoomData(joinResponse)['publishers'] ?? const <dynamic>[],
    };
  }

  /// 订阅远端流
  Future<RTCPeerConnection> subscribeToFeed({
    required int roomId,
    required String feedId,
    void Function(MediaStream stream)? onRemoteStream,
  }) async {
    if (_sessionId == null || _handleId == null) {
      throw Exception('Janus not connected');
    }

    final peerConnection = await _createPeerConnection(null);
    // VideoRoom 中 publisher 与 subscriber 必须使用不同 handle；复用发布
    // handle 会被 Janus 拒绝为 already in a room。
    _subscriberHandleId ??= await _attachVideoRoomHandle();
    peerConnection.onIceCandidate = (candidate) {
      _sendTrickle(candidate, handleId: _subscriberHandleId);
    };
    // 远端 track 可能在 setRemoteDescription 期间就到达，不能交给调用方在
    // subscribeToFeed 返回后再注册，否则会错过第一帧/首段音频。
    peerConnection.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        onRemoteStream?.call(event.streams.first);
      }
    };

    // 发送 join 请求（订阅者模式）
    final joinResponse = await _sendRequest({
      'janus': 'message',
      'session_id': int.parse(_sessionId!),
      'handle_id': int.parse(_subscriberHandleId!),
      'body': {
        'request': 'join',
        'ptype': 'subscriber',
        'room': roomId,
        'feed': int.parse(feedId),
      },
      'transaction': _nextTransactionId(),
    });

    if (joinResponse['janus'] != 'event') {
      throw Exception('Failed to subscribe: ${joinResponse['error']}');
    }

    final offerSdp = joinResponse['jsep']?['sdp'] as String?;
    if (offerSdp == null || joinResponse['jsep']?['type'] != 'offer') {
      throw Exception('Janus subscribe 未返回 SDP offer');
    }
    await peerConnection.setRemoteDescription(RTCSessionDescription(offerSdp, 'offer'));

    // 创建 answer
    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    // 发送 answer
    await _sendRequest({
      'janus': 'message',
      'session_id': int.parse(_sessionId!),
      'handle_id': int.parse(_subscriberHandleId!),
      'body': {
        'request': 'start',
      },
      'jsep': {
        'type': 'answer',
        'sdp': answer.sdp,
      },
      'transaction': _nextTransactionId(),
    });

    return peerConnection;
  }

  /// 离开房间
  Future<void> leaveRoom({required int roomId}) async {
    if (_sessionId == null || _handleId == null) return;

    await _sendRequest({
      'janus': 'message',
      'session_id': int.parse(_sessionId!),
      'handle_id': int.parse(_handleId!),
      'body': {
        'request': 'leave',
        'room': roomId,
      },
      'transaction': _nextTransactionId(),
    });
  }

  /// 销毁会话
  Future<void> destroy() async {
    _stopHeartbeat();
    _updateConnectionState(JanusConnectionState.disconnected);
    
    if (_sessionId != null) {
      try {
        await _sendRequest({
          'janus': 'destroy',
          'session_id': int.parse(_sessionId!),
          'transaction': _nextTransactionId(),
        });
      } catch (e) {
        debugPrint('[JanusClient] 销毁会话失败: $e');
      }
    }
    
    // 关键修复：取消 WebSocket 订阅，防止内存泄漏
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    
    await _channel?.sink.close();
    _channel = null;
    _sessionId = null;
    _handleId = null;
    _subscriberHandleId = null;
    
    // 清理所有待的事务
    for (final completer in _pendingTransactions.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Connection destroyed'));
      }
    }
    _pendingTransactions.clear();
    
    // 关键修复：检查 StreamController 是否已关闭，避免重复关闭
    if (!_connectionStateController.isClosed) {
      await _connectionStateController.close();
    }
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(MediaStream? localStream) async {
    final config = <String, dynamic>{
      'iceServers': [
        if (turnUrls.isNotEmpty) {
          {
            'urls': turnUrls,
            'username': turnUsername,
            'credential': turnCredential,
          },
        },
      ],
    };

    final peerConnection = await createPeerConnection(config);

    if (localStream != null) {
      for (final track in localStream.getTracks()) {
        await peerConnection.addTrack(track, localStream);
      }
    }

    return peerConnection;
  }

  Future<String> _attachVideoRoomHandle() async {
    final response = await _sendRequest({
      'janus': 'attach',
      'session_id': int.parse(_sessionId!),
      'plugin': 'janus.plugin.videoroom',
      'transaction': _nextTransactionId(),
    });
    final handleId = response['data']?['id']?.toString();
    if (response['janus'] != 'success' || handleId == null) {
      throw Exception('Failed to attach subscriber handle: ${response['error']}');
    }
    return handleId;
  }

  Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> request) async {
    final transaction = request['transaction'] as String;
    final completer = Completer<Map<String, dynamic>>();
    _pendingTransactions[transaction] = completer;

    _channel!.sink.add(jsonEncode(request));

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingTransactions.remove(transaction);
        throw Exception('Request timeout: $transaction');
      },
    );
  }

  void _sendTrickle(RTCIceCandidate candidate, {String? handleId}) {
    if (_sessionId == null || _channel == null) return;
    final candidatePayload = candidate.candidate == null || candidate.candidate!.isEmpty
        ? <String, dynamic>{'completed': true}
        : <String, dynamic>{
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          };
    // Janus 对 trickle 只返回 ack；它不是需要等待 plugin event 的事务。
    // 若复用 _sendRequest，Future 会在 10 秒后无监听超时并污染下一次通话。
    _channel!.sink.add(jsonEncode({
      'janus': 'trickle',
      'session_id': int.parse(_sessionId!),
      'handle_id': int.parse(handleId ?? _handleId!),
      'candidate': candidatePayload,
      'transaction': _nextTransactionId(),
    }));
  }

  void _onMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      
      // 处理事务响应
      final transaction = message['transaction'] as String?;
      if (transaction != null && _pendingTransactions.containsKey(transaction)) {
        // plugin message 先返回 ack，随后才返回带相同 transaction 的 event。
        // ack 不是业务完成态，若在此完成 Future，后续 event 会被遗漏。
        if (message['janus'] != 'ack') {
          _pendingTransactions.remove(transaction)?.complete(message);
        }
      }
      
      // 处理事件
      if (message['janus'] == 'event') {
        _eventController.add(message);
      }
    } catch (e) {
      _eventController.addError(e);
    }
  }

  Map<String, dynamic> _videoRoomData(Map<String, dynamic> message) {
    final pluginData = message['plugindata'];
    if (pluginData is! Map) return const <String, dynamic>{};
    final data = pluginData['data'];
    return data is Map<String, dynamic> ? data : const <String, dynamic>{};
  }

  String _nextTransactionId() {
    _transactionCounter++;
    return 'tx_$_transactionCounter';
  }
}
