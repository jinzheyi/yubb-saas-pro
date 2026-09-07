import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/livekit_call_providers.dart';

enum _ServerCallPhase {
  none,
  outgoingRinging,
  incomingRinging,
  connected,
  ended,
}

enum CallEndDisplayReason {
  localCancel,
  localReject,
  localHangup,
  remoteReject,
  remoteCancel,
  remoteHangup,
  noAnswer,
  otherDeviceAccepted,
  networkLost,
  maxDuration,
  groupEnded,
  restoreFailed,
  acceptFailed,
  microphonePermissionDenied,
  mediaPermissionDenied,
  failed,
}

enum CallLaunchFailure { groupMemberBusy, other }

@visibleForTesting
CallLaunchFailure classifyCallLaunchFailure(
  Object error, {
  required bool isGroupCall,
}) {
  if (isGroupCall && error is ApiException && error.code == 1002050003) {
    return CallLaunchFailure.groupMemberBusy;
  }
  return CallLaunchFailure.other;
}

/// 唯一的媒体编排器：业务 HTTP 决定邀请和状态，LiveKit SDK 仅管理媒体连接。
class LiveKitCallController extends ChangeNotifier {
  /// Keep the WebRTC audio device module in communication mode from its first
  /// initialization. On Android this must happen before a Room creates media
  /// tracks; otherwise the platform can retain media-playback routing and its
  /// weaker echo-control behaviour for the lifetime of the process.
  static Future<void>? _liveKitInitialization;

  static const RoomOptions _communicationRoomOptions = RoomOptions(
    defaultAudioCaptureOptions: AudioCaptureOptions(
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true,
      highPassFilter: true,
      voiceIsolation: true,
      typingNoiseDetection: true,
    ),
  );

  LiveKitCallController({
    required Dio dio,
    required DeviceInfoService deviceInfoService,
    required Stream<LiveKitCallEvent> callEvents,
    required this.args,
    this.localUserId = '',
    this.onCallIdChanged,
  }) : _dio = dio,
       _deviceInfoService = deviceInfoService {
    _callEventSubscription = callEvents.listen(_onCallEvent);
  }

  final Dio _dio;
  final DeviceInfoService _deviceInfoService;
  final CallLaunchArgs args;
  final String localUserId;
  final ValueChanged<String>? onCallIdChanged;

  Room? _room;
  String _callId = '';
  bool _connecting = false;
  bool _connected = false;
  bool _microphoneEnabled = true;
  bool _cameraEnabled = false;
  bool _speakerEnabled = false;
  bool _answered = false;
  bool _usingFrontCamera = true;
  bool _reconnecting = false;
  String? _error;
  String? _operationMessage;
  CallEndDisplayReason? _endReason;
  CallLaunchFailure? _launchFailure;
  bool _shouldClose = false;
  int _elapsedSeconds = 0;
  int _lastEventVersion = 0;
  Timer? _ringTimeout;
  Timer? _durationTimer;
  Timer? _reconnectTimeout;
  EventsListener<RoomEvent>? _roomEvents;
  bool _disposed = false;
  bool _disposingRoom = false;
  Future<void>? _finalization;
  Future<void>? _disposeCallFuture;
  _ServerCallPhase _serverPhase = _ServerCallPhase.none;
  late final StreamSubscription<LiveKitCallEvent> _callEventSubscription;

  String get callId => _callId;
  bool get connecting => _connecting;
  bool get connected => _connected;
  bool get microphoneEnabled => _microphoneEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get speakerEnabled => _speakerEnabled;
  bool get answered => _answered;
  bool get reconnecting => _reconnecting;
  int get elapsedSeconds => _elapsedSeconds;
  String? get error => _error;
  String? get operationMessage => _operationMessage;
  CallEndDisplayReason? get endReason => _endReason;
  CallLaunchFailure? get launchFailure => _launchFailure;
  bool get shouldClose => _shouldClose;
  Room? get room => _room;
  bool get hasRemoteParticipant =>
      (_room?.remoteParticipants.isNotEmpty ?? false);
  bool get hasLocalParticipant => _room?.localParticipant != null;
  bool get speakerRoutingSupported => !kIsWeb;
  bool get usingFrontCamera => _usingFrontCamera;

  Future<void> startOutgoing() async {
    if (_connecting || _connected) return;
    try {
      _validateOutgoingArgs();
      await _ensureMediaPermissions();
      final device = await _deviceInfoService.getOrCreate();
      final response = await _dio.post(
        args.isGroupCall
            ? '/system/im/call/group/create-invite'
            : '/system/im/call/create-invite',
        data: args.isGroupCall
            ? {
                'chatId': args.chatId,
                'groupId': args.groupId,
                'callType': args.callType.name,
                'inviteeIds': args.inviteeIds,
                'deviceId': device.deviceId,
              }
            : {
                'chatId': args.chatId,
                'calleeId': args.toUserId,
                'callType': args.callType.name,
                'deviceId': device.deviceId,
              },
      );
      final payload = _data(response.data);
      _callId = payload['callSessionId']?.toString() ?? '';
      if (_callId.isEmpty) throw StateError('服务端未返回 callSessionId');
      _serverPhase = _ServerCallPhase.outgoingRinging;
      onCallIdChanged?.call(_callId);
      _startRingTimeout();
      await _connect(_roomCredentials(payload));
    } catch (error) {
      _launchFailure = classifyCallLaunchFailure(
        error,
        isGroupCall: args.isGroupCall,
      );
      if (_launchFailure == CallLaunchFailure.groupMemberBusy) {
        // 群成员忙线时没有创建出服务端会话，直接把控制权交还成员选择流程。
        await disposeCall();
        rethrow;
      }
      await _terminateFailedMediaSession();
      await _terminateLocally(
        _friendlyFailure(error),
        _failureEndReason(error) ?? CallEndDisplayReason.failed,
      );
      rethrow;
    }
  }

  Future<void> acceptIncoming() async {
    if (_connecting || _connected) return;
    var acceptedOnServer = false;
    try {
      final callId = args.callSessionId;
      if (callId.isEmpty) throw StateError('来电缺少 callSessionId');
      _serverPhase = _ServerCallPhase.incomingRinging;
      await _ensureMediaPermissions();
      final device = await _deviceInfoService.getOrCreate();
      final response = await _dio.post(
        '/system/im/call/accept',
        data: {'callSessionId': callId, 'deviceId': device.deviceId},
      );
      acceptedOnServer = true;
      _serverPhase = _ServerCallPhase.connected;
      _answered = true;
      _callId = callId;
      onCallIdChanged?.call(_callId);
      _ringTimeout?.cancel();
      await _connect(_data(response.data));
    } catch (error) {
      final endpoint = acceptedOnServer
          ? _connectedTerminationEndpoint
          : '/system/im/call/reject';
      await _endServerSessionBestEffort(endpoint);
      _serverPhase = _ServerCallPhase.ended;
      await _terminateLocally(
        _friendlyFailure(error),
        _failureEndReason(error) ?? CallEndDisplayReason.acceptFailed,
      );
      rethrow;
    }
  }

  Future<void> restore() async {
    if (_connecting || _connected) return;
    final callId = args.callSessionId;
    if (callId.isEmpty) {
      await _terminateLocally('恢复通话失败', CallEndDisplayReason.restoreFailed);
      return;
    }
    try {
      final device = await _deviceInfoService.getOrCreate();
      final response = await _dio.post(
        '/system/im/call/connection',
        data: {'callSessionId': callId, 'deviceId': device.deviceId},
      );
      _callId = callId;
      _serverPhase = _ServerCallPhase.connected;
      _answered = true;
      onCallIdChanged?.call(_callId);
      await _connect(_data(response.data));
    } catch (error) {
      if (_serverPhase == _ServerCallPhase.connected) {
        await _endServerSessionBestEffort(_connectedTerminationEndpoint);
      }
      await _terminateLocally('恢复通话失败', CallEndDisplayReason.restoreFailed);
      rethrow;
    }
  }

  Future<void> rejectIncoming() {
    _endReason = CallEndDisplayReason.localReject;
    return _finish('/system/im/call/reject');
  }

  Future<void> hangup() async {
    // 弱网超时等路径会先写入更精确的终态，不能被通用“本人挂断”覆盖。
    _endReason ??= _localEndReason;
    await _finish(_connectedTerminationEndpoint);
  }

  String get _connectedTerminationEndpoint =>
      args.isGroupCall && args.isGroupOwner != true
      ? '/system/im/call/group/leave'
      : '/system/im/call/hangup';

  CallEndDisplayReason get _localEndReason {
    if (args.isGroupCall || hasRemoteParticipant || _answered) {
      return CallEndDisplayReason.localHangup;
    }
    return CallEndDisplayReason.localCancel;
  }

  /// Acquire native media permissions before creating or accepting server-side
  /// call state. Web browsers must request through getUserMedia, which the
  /// LiveKit SDK performs from the user's call action.
  Future<void> _ensureMediaPermissions() async {
    if (kIsWeb) return;
    final permissions = <Permission>[Permission.microphone];
    if (args.callType == CallType.video) permissions.add(Permission.camera);
    final statuses = await permissions.request();
    final microphoneGranted =
        statuses[Permission.microphone]?.isGranted == true;
    final cameraGranted =
        args.callType != CallType.video ||
        statuses[Permission.camera]?.isGranted == true;
    if (!microphoneGranted || !cameraGranted) {
      throw StateError(
        args.callType == CallType.video
            ? '需要麦克风和摄像头权限才能进行视频通话'
            : '需要麦克风权限才能进行语音通话',
      );
    }
  }

  void _validateOutgoingArgs() {
    if (args.chatId.trim().isEmpty) throw StateError('缺少会话信息');
    if (args.isGroupCall) {
      if (args.groupId?.trim().isEmpty != false || args.inviteeIds.isEmpty) {
        throw StateError('群通话参数不完整');
      }
      return;
    }
    if (args.toUserId?.trim().isEmpty != false) {
      throw StateError('联系人信息不完整');
    }
  }

  Future<void> toggleMicrophone() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final next = !_microphoneEnabled;
    try {
      await participant.setMicrophoneEnabled(next);
      _microphoneEnabled = next;
      _operationMessage = null;
    } catch (error) {
      _operationMessage = '麦克风操作失败';
      rethrow;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> toggleCamera() async {
    if (args.callType != CallType.video) return;
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final next = !_cameraEnabled;
    try {
      await participant.setCameraEnabled(next);
      _cameraEnabled = next;
      _operationMessage = null;
    } catch (error) {
      _operationMessage = '摄像头操作失败';
      rethrow;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> toggleSpeaker() async {
    if (kIsWeb || _room?.localParticipant == null) return;
    final next = !_speakerEnabled;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(next);
      _speakerEnabled = next;
      _operationMessage = null;
    } catch (error) {
      _operationMessage = '扬声器操作失败';
      rethrow;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> switchCamera() async {
    if (args.callType != CallType.video || !_cameraEnabled) return;
    final publications = _room?.localParticipant?.videoTrackPublications;
    if (publications == null) return;
    for (final publication in publications) {
      final track = publication.track;
      if (track is LocalVideoTrack) {
        final next = !_usingFrontCamera;
        try {
          await track.setCameraPosition(
            next ? CameraPosition.front : CameraPosition.back,
          );
          _usingFrontCamera = next;
          _operationMessage = null;
        } catch (error) {
          _operationMessage = '摄像头翻转失败';
          rethrow;
        } finally {
          if (!_disposed) notifyListeners();
        }
        return;
      }
    }
  }

  Future<void> _connect(Map<String, dynamic> credentials) async {
    final url = credentials['livekitUrl']?.toString() ?? '';
    final token =
        (credentials['accessToken'] ?? credentials['token'])?.toString() ?? '';
    if (url.isEmpty || token.isEmpty) throw StateError('服务端未返回有效 LiveKit 连接凭据');
    _connecting = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureLiveKitInitialized();
      final room = Room(roomOptions: _communicationRoomOptions);
      _room = room;
      room.addListener(_onRoomChanged);
      _roomEvents = room.createListener()
        ..on<RoomReconnectingEvent>((_) => _onReconnecting())
        ..on<RoomResumingEvent>((_) => _onReconnecting())
        ..on<RoomReconnectedEvent>((_) => _onReconnected())
        ..on<RoomDisconnectedEvent>((_) => _onDisconnected());
      // Browsers can leave getUserMedia / WebSocket setup pending forever when
      // a permission sheet is dismissed or a proxy silently drops the media
      // connection. A call UI must always converge to a terminal state.
      await room.connect(url, token).timeout(const Duration(seconds: 15));
      if (!kIsWeb) {
        // A voice call should start on the earpiece to avoid an acoustic loop
        // in close-range use. Video calls keep the expected hands-free speaker
        // route. `force` remains false so wired/Bluetooth headsets win.
        final preferSpeaker = args.callType == CallType.video;
        await AudioManager.instance.setSpeakerOutputPreferred(preferSpeaker);
        _speakerEnabled = preferSpeaker;
      }
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (args.callType == CallType.video) {
        await room.localParticipant?.setCameraEnabled(true);
        _cameraEnabled = true;
      }
      _room = room;
      _connected = true;
      _reconnecting = false;
      _startDurationTimer();
    } catch (error) {
      _error = _friendlyFailure(error);
      await _disposeRoom();
      rethrow;
    } finally {
      _connecting = false;
      if (!_disposed) notifyListeners();
    }
  }

  static Future<void> _ensureLiveKitInitialized() {
    return _liveKitInitialization ??= LiveKitClient.initialize(
      bypassVoiceProcessing: false,
      // The pinned LiveKit SDK marks platform session options experimental;
      // communication mode is required before Android's WebRTC ADM starts.
      // ignore: experimental_member_use
      initialAudioSessionOptions: const AudioSessionOptions.communication(),
    );
  }

  void _onRoomChanged() {
    if (_disposed) return;
    final room = _room;
    if (room != null && room.connectionState == ConnectionState.disconnected) {
      _connected = false;
    }
    notifyListeners();
  }

  void _onReconnecting() {
    if (_disposed) return;
    _reconnecting = true;
    _reconnectTimeout?.cancel();
    _reconnectTimeout = Timer(const Duration(seconds: 15), () {
      _error = '网络连接中断，通话已结束';
      _endReason = CallEndDisplayReason.networkLost;
      _shouldClose = true;
      notifyListeners();
      unawaited(hangup());
    });
    notifyListeners();
  }

  void _onReconnected() {
    if (_disposed) return;
    _reconnecting = false;
    _reconnectTimeout?.cancel();
    _reconnectTimeout = null;
    notifyListeners();
  }

  void _onDisconnected() {
    if (_disposed) return;
    _connected = false;
    _reconnecting = false;
    _reconnectTimeout?.cancel();
    if (!_disposingRoom && !_shouldClose) {
      _error = '媒体连接已断开，通话已结束';
      _endReason = CallEndDisplayReason.networkLost;
      _shouldClose = true;
      unawaited(hangup());
    }
    notifyListeners();
  }

  Future<void> _finish(String endpoint) {
    final existing = _finalization;
    if (existing != null) return existing;
    final operation = _finishOnce(endpoint);
    _finalization = operation;
    return operation;
  }

  Future<void> _finishOnce(String endpoint) async {
    final id = _callId.isNotEmpty ? _callId : args.callSessionId;
    try {
      if (id.isNotEmpty) {
        await _dio.post(endpoint, data: {'callSessionId': id});
      }
    } finally {
      _serverPhase = _ServerCallPhase.ended;
      // 服务端暂时不可达时也必须立即释放麦克风、相机和 LiveKit 房间。
      // 服务端生命周期任务会依据持久化状态完成最终收敛。
      await disposeCall();
      _shouldClose = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _endServerSessionBestEffort(String endpoint) async {
    final id = _callId.isNotEmpty ? _callId : args.callSessionId;
    if (id.isEmpty) return;
    try {
      await _dio.post(endpoint, data: {'callSessionId': id});
    } catch (error) {
      debugPrint('[LiveKitCallController] 媒体连接失败后的服务端补偿失败: $error');
    }
  }

  /// Media setup can fail after the business state has already advanced.
  /// Terminate according to the last authoritative server transition instead
  /// of guessing from LiveKit participant visibility.
  Future<void> _terminateFailedMediaSession() async {
    final endpoint = switch (_serverPhase) {
      _ServerCallPhase.none || _ServerCallPhase.ended => null,
      _ServerCallPhase.outgoingRinging => '/system/im/call/cancel',
      _ServerCallPhase.incomingRinging => '/system/im/call/reject',
      _ServerCallPhase.connected => _connectedTerminationEndpoint,
    };
    if (endpoint != null) await _endServerSessionBestEffort(endpoint);
    _serverPhase = _ServerCallPhase.ended;
  }

  void reportOperationFailure(Object error) {
    _operationMessage ??= '操作失败，请重试';
    debugPrint('[LiveKitCallController] 操作失败: $error');
    notifyListeners();
  }

  void clearOperationMessage() {
    if (_operationMessage == null) return;
    _operationMessage = null;
    notifyListeners();
  }

  Future<void> disposeCall() {
    final existing = _disposeCallFuture;
    if (existing != null) return existing;
    final operation = _disposeCallOnce();
    _disposeCallFuture = operation;
    return operation;
  }

  Future<void> _disposeCallOnce() async {
    _ringTimeout?.cancel();
    _durationTimer?.cancel();
    _reconnectTimeout?.cancel();
    await _callEventSubscription.cancel();
    await _disposeRoom();
  }

  Future<void> _disposeRoom() async {
    final room = _room;
    _room = null;
    _connected = false;
    _reconnecting = false;
    await _roomEvents?.dispose();
    _roomEvents = null;
    if (room != null) {
      _disposingRoom = true;
      try {
        room.removeListener(_onRoomChanged);
        await room.disconnect();
        await room.dispose();
      } finally {
        _disposingRoom = false;
      }
    }
    if (!_disposed) notifyListeners();
  }

  void _onCallEvent(LiveKitCallEvent event) {
    final expectedCallId = _callId.isNotEmpty ? _callId : args.callSessionId;
    if (event.callId != expectedCallId) return;
    if (event.version > 0 && event.version <= _lastEventVersion) return;
    if (event.version > _lastEventVersion + 1 && _lastEventVersion > 0) {
      unawaited(_reconcileState());
    }
    if (event.version > 0) _lastEventVersion = event.version;
    if (event.type == 'call.accepted' || event.type == 'call.group_join') {
      _serverPhase = _ServerCallPhase.connected;
      _answered = true;
      _ringTimeout?.cancel();
      notifyListeners();
      return;
    }
    if (!event.isTerminal) return;
    _serverPhase = _ServerCallPhase.ended;
    _shouldClose = true;
    _endReason ??= _mapEndReason(event);
    _error = null;
    unawaited(disposeCall());
    notifyListeners();
  }

  Future<void> _reconcileState() async {
    final id = _callId.isNotEmpty ? _callId : args.callSessionId;
    if (id.isEmpty) return;
    try {
      final response = await _dio.get(
        '/system/im/call/state',
        queryParameters: {'callSessionId': id},
      );
      final state = _data(response.data);
      if (state['state']?.toString().toLowerCase() == 'ended') {
        _shouldClose = true;
        _endReason = args.isGroupCall
            ? CallEndDisplayReason.groupEnded
            : CallEndDisplayReason.remoteHangup;
        await disposeCall();
      }
    } catch (error) {
      debugPrint('[LiveKitCallController] 状态对账失败: $error');
    }
  }

  void _startRingTimeout() {
    _ringTimeout?.cancel();
    _ringTimeout = Timer(const Duration(seconds: 30), () async {
      if (hasRemoteParticipant || _shouldClose) return;
      _error = '对方无应答';
      _endReason = CallEndDisplayReason.noAnswer;
      _shouldClose = true;
      notifyListeners();
      try {
        // 主叫端 30 秒自然超时时，立即通知服务端生成 TIMEOUT/MISSED
        // 终态并广播给被叫端停止响铃；生命周期任务仍作为服务端兜底。
        await _endServerSessionBestEffort('/system/im/call/timeout');
        await disposeCall();
      } catch (error) {
        debugPrint('[LiveKitCallController] 通话超时状态对账失败: $error');
      } finally {
        if (!_disposed) notifyListeners();
      }
    });
  }

  Future<void> _terminateLocally(
    String message,
    CallEndDisplayReason reason,
  ) async {
    _error = message;
    _endReason = reason;
    _shouldClose = true;
    await disposeCall();
    if (!_disposed) notifyListeners();
  }

  CallEndDisplayReason _mapEndReason(LiveKitCallEvent event) {
    final reason = event.reason?.toUpperCase();
    if (reason == 'MAX_DURATION') return CallEndDisplayReason.maxDuration;
    if (reason == 'NO_PARTICIPANTS' || event.type == 'call.group_ended') {
      return CallEndDisplayReason.groupEnded;
    }
    if (reason == 'ACCEPTED_OTHER_DEVICE' ||
        reason == 'OTHER_DEVICE_ACCEPTED') {
      return CallEndDisplayReason.otherDeviceAccepted;
    }
    return switch (event.type) {
      'call.rejected' => CallEndDisplayReason.remoteReject,
      'call.cancelled' => CallEndDisplayReason.remoteCancel,
      'call.timeout' => CallEndDisplayReason.noAnswer,
      'call.ended' =>
        args.isGroupCall
            ? CallEndDisplayReason.groupEnded
            : _eventActorIsLocal(event)
            ? CallEndDisplayReason.localHangup
            : CallEndDisplayReason.remoteHangup,
      _ => CallEndDisplayReason.failed,
    };
  }

  bool _eventActorIsLocal(LiveKitCallEvent event) {
    final actorId = event.actorId;
    if (actorId == null || actorId.isEmpty) return false;
    if (localUserId.isNotEmpty) return actorId == localUserId;
    final remoteId = args.entryMode == CallEntryMode.outgoing
        ? args.toUserId
        : args.fromUserId;
    return remoteId != null && actorId != remoteId;
  }

  String _friendlyFailure(Object error) {
    final text = error.toString().toLowerCase();
    if (_isPermissionFailure(text)) {
      return args.callType == CallType.video
          ? '需要摄像头和麦克风权限才能视频通话'
          : '需要麦克风权限才能通话';
    }
    return '通话连接失败，请稍后重试';
  }

  CallEndDisplayReason? _failureEndReason(Object error) {
    if (!_isPermissionFailure(error.toString().toLowerCase())) return null;
    return args.callType == CallType.video
        ? CallEndDisplayReason.mediaPermissionDenied
        : CallEndDisplayReason.microphonePermissionDenied;
  }

  bool _isPermissionFailure(String text) {
    return text.contains('permission') ||
        text.contains('权限') ||
        text.contains('notallowederror') ||
        text.contains('mediadevicefailure');
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (hasRemoteParticipant) {
        _answered = true;
        _serverPhase = _ServerCallPhase.connected;
        _ringTimeout?.cancel();
        _elapsedSeconds++;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disposeCall());
    super.dispose();
  }

  Map<String, dynamic> _roomCredentials(Map<String, dynamic> payload) {
    final raw = payload['rtcRoom'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('服务端未返回 rtcRoom');
  }

  Map<String, dynamic> _data(Object? body) {
    if (body is! Map<String, dynamic>) throw StateError('服务端响应格式错误');
    return ApiResult.fromJson<Map<String, dynamic>>(
      body,
      dataParser: (raw) => Map<String, dynamic>.from(raw as Map),
    ).requireData();
  }
}
