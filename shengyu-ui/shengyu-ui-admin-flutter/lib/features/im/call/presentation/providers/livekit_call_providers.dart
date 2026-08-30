import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/call_audio_cue_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/call_screen_awake_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/native_call_ui_gateway.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';

/// 进程内的通话占用注册器。
///
/// 这个状态只用于在客户端拦截重复发起，业务 API 仍是忙线裁决的权威来源。
/// 它故意不使用 StateProvider：通话页面需要在 initState/dispose 中成对地
/// 占用和释放，这不应触发 Riverpod 的组件树更新。
final liveKitCallActivityProvider = Provider<LiveKitCallActivityRegistry>((
  ref,
) {
  final registry = LiveKitCallActivityRegistry();
  ref.onDispose(registry.clear);
  return registry;
});

class LiveKitCallActivityRegistry {
  final Map<Object, String> _leases = <Object, String>{};

  bool get isActive => _leases.isNotEmpty;

  /// 空字符串代表页面正在创建去电，尚未拿到服务端 callSessionId。
  /// 不能把它当成没有通话，否则这段窗口内的新来电会穿透占用保护。
  String? get activeCallId {
    for (final callId in _leases.values) {
      if (callId.isNotEmpty) return callId;
    }
    return null;
  }

  Object acquire([String callId = '']) {
    final lease = Object();
    _leases[lease] = callId;
    return lease;
  }

  void update(Object lease, String callId) {
    if (_leases.containsKey(lease)) _leases[lease] = callId;
  }

  void release(Object lease) => _leases.remove(lease);

  void clear() => _leases.clear();
}

final liveKitCallEventBusProvider = Provider<LiveKitCallEventBus>((ref) {
  final bus = LiveKitCallEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final callAudioCueServiceProvider = Provider<CallAudioCueService>((ref) {
  final service = CallAudioCueService();
  ref.onDispose(service.dispose);
  return service;
});

final callScreenAwakeServiceProvider = Provider<CallScreenAwakeService>((ref) {
  final service = CallScreenAwakeService();
  ref.onDispose(service.clear);
  return service;
});

final nativeCallUiGatewayProvider = Provider<NativeCallUiGateway>((ref) {
  final gateway = NativeCallUiGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

class LiveKitCallEvent {
  const LiveKitCallEvent({
    required this.type,
    required this.callId,
    this.version = 0,
    this.reason,
    this.actorId,
  });
  final String type;
  final String callId;
  final int version;
  final String? reason;
  final String? actorId;

  bool get isTerminal => const {
    'call.rejected',
    'call.cancelled',
    'call.ended',
    'call.timeout',
    'call.group_ended',
  }.contains(type);
}

class LiveKitCallEventBus {
  final _controller = StreamController<LiveKitCallEvent>.broadcast();
  Stream<LiveKitCallEvent> get stream => _controller.stream;
  void publish(LiveKitCallEvent event) => _controller.add(event);
  void dispose() => _controller.close();
}

@visibleForTesting
CallLaunchArgs callLaunchArgsFromPayload({
  required Map<dynamic, dynamic> raw,
  required String type,
  required String currentUserId,
  String? Function(String chatId)? conversationTitleByChatId,
}) {
  final callId = (raw['callSessionId'] ?? raw['callId'])?.toString() ?? '';
  final callType =
      raw['callType']?.toString() == 'video' ||
          raw['callType']?.toString() == '2'
      ? CallType.video
      : CallType.audio;
  final recoveredState = raw['_recoveredState']?.toString().toLowerCase();
  final recoveredIncoming = raw['_recoveredIncoming'] == true;
  final entryMode = recoveredState == null
      ? CallEntryMode.incoming
      : recoveredIncoming && recoveredState == 'ringing'
      ? CallEntryMode.incoming
      : CallEntryMode.restore;
  final isGroupCall = type == 'call.group_invite';
  final profile = raw['callerProfile'];
  final profileMap = profile is Map ? profile : const <dynamic, dynamic>{};
  final callerId = (raw['callerId'] ?? profileMap['userId'])?.toString();
  final callerName = (raw['callerName'] ?? profileMap['displayName'])
      ?.toString();
  final callerAvatar = (raw['callerAvatar'] ?? profileMap['avatarUrl'])
      ?.toString();
  final chatId = raw['chatId']?.toString() ?? '';
  final payloadConversationTitle =
      (raw['groupName'] ?? raw['conversationTitle'])?.toString();
  final invitees = raw['inviteeIds'];
  return CallLaunchArgs(
    callSessionId: callId,
    chatId: chatId,
    callType: callType,
    entryMode: entryMode,
    fromUserId: callerId,
    title: callerName ?? '来电',
    conversationTitle: payloadConversationTitle?.trim().isNotEmpty == true
        ? payloadConversationTitle!.trim()
        : isGroupCall
        ? conversationTitleByChatId?.call(chatId)
        : callerName,
    callerName: callerName,
    callerAvatarUrl: callerAvatar,
    callerId: callerId,
    isGroupOwner: isGroupCall
        ? entryMode == CallEntryMode.restore
              ? callerId != null && callerId == currentUserId
              : false
        : null,
    isGroupCall: isGroupCall,
    groupId: raw['groupId']?.toString(),
    inviteeIds: invitees is List
        ? invitees
              .whereType<Object>()
              .map((value) => value.toString())
              .toList(growable: false)
        : const <String>[],
  );
}

/// 只消费业务来电事件，绝不承载媒体协商数据或媒体令牌。
final liveKitCallInvitationBindingProvider =
    Provider<LiveKitCallInvitationBinding>((ref) {
      final binding = LiveKitCallInvitationBinding(
        // appRouterProvider 会在登录态变化时重建 GoRouter。来电绑定的生命
        // 周期比单个路由实例长，因此必须延迟读取当前路由，不能缓存启动时的实例。
        router: () => ref.read(appRouterProvider),
        events: ref.read(socketMessageDispatcherProvider).stream,
        eventBus: ref.read(liveKitCallEventBusProvider),
        nativeUi: ref.read(nativeCallUiGatewayProvider),
        screenAwake: ref.read(callScreenAwakeServiceProvider),
        dio: ref.read(dioProvider),
        callActivity: ref.read(liveKitCallActivityProvider),
        currentUserId: () => ref.read(authSessionProvider).userId,
        conversationTitleByChatId: (chatId) {
          for (final conversation
              in ref.read(conversationListControllerProvider).conversations) {
            if (conversation.chatId == chatId &&
                conversation.title.trim().isNotEmpty) {
              return conversation.title.trim();
            }
          }
          return null;
        },
      );
      ref.onDispose(binding.dispose);
      return binding;
    });

class LiveKitCallInvitationBinding with WidgetsBindingObserver {
  LiveKitCallInvitationBinding({
    required dynamic Function() router,
    required Stream<dynamic> events,
    required LiveKitCallEventBus eventBus,
    required NativeCallUiGateway nativeUi,
    required CallScreenAwakeService screenAwake,
    required dynamic dio,
    required LiveKitCallActivityRegistry callActivity,
    required String Function() currentUserId,
    required String? Function(String chatId) conversationTitleByChatId,
  }) : _router = router,
       _eventBus = eventBus,
       _nativeUi = nativeUi,
       _screenAwake = screenAwake,
       _dio = dio,
       _callActivity = callActivity,
       _currentUserId = currentUserId,
       _conversationTitleByChatId = conversationTitleByChatId {
    _subscription = events.listen(
      _onEvent,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[LiveKitCallInvitationBinding] WebSocket error: $error');
      },
    );
    _nativeActionSubscription = nativeUi.actions.listen(_onNativeAction);
    WidgetsBinding.instance.addObserver(this);
  }

  final dynamic Function() _router;
  final LiveKitCallEventBus _eventBus;
  final NativeCallUiGateway _nativeUi;
  final CallScreenAwakeService _screenAwake;
  final dynamic _dio;
  final LiveKitCallActivityRegistry _callActivity;
  final String Function() _currentUserId;
  final String? Function(String chatId) _conversationTitleByChatId;
  final Set<String> _seenInviteIds = <String>{};
  final Map<String, int> _lastVersions = <String, int>{};
  final Map<String, Object> _nativeIncomingScreenLeases = <String, Object>{};
  StreamSubscription<dynamic>? _subscription;
  StreamSubscription<NativeCallAction>? _nativeActionSubscription;
  Future<void>? _reconcileFuture;
  bool _disposed = false;

  void _onEvent(dynamic event) {
    if (event.type == SocketEventTypes.authSucceeded) {
      unawaited(_reconcileActiveCall());
      return;
    }
    if (event.type != SocketEventTypes.systemNotify) return;
    final payload = event.payload;
    if (payload is! Map) return;
    final Map<dynamic, dynamic> envelope = payload;
    final nested = envelope['payload'];
    final Map<dynamic, dynamic> raw = nested is Map ? nested : envelope;
    _handlePayload(raw);
  }

  /// FCM contains only a call id.  Resolve the authoritative active-call
  /// state before creating any native or Flutter incoming-call UI.
  Future<void> reconcileFcmInvite(String callId) async {
    if (callId.isEmpty || _disposed) return;
    try {
      final response = await _dio.get('/system/im/call/active');
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (data is! Map || data['callSessionId']?.toString() != callId) return;
      final state = data['state']?.toString().toLowerCase() ?? '';
      if (!const {'ringing', 'connecting', 'connected'}.contains(state)) return;
      _handlePayload(<dynamic, dynamic>{
        ...data,
        'type': data['groupId'] == null ? 'call.invite' : 'call.group_invite',
        'callId': callId,
        'callerProfile': <String, dynamic>{
          'userId': data['callerId'],
          'displayName': data['callerName'],
          'avatarUrl': data['callerAvatar'],
        },
      });
    } catch (error) {
      debugPrint('[LiveKitCallInvitationBinding] FCM 通话状态核验失败: $error');
    }
  }

  void _handlePayload(Map<dynamic, dynamic> raw) {
    final type = raw['type']?.toString() ?? '';
    final callId = (raw['callSessionId'] ?? raw['callId'])?.toString() ?? '';
    if (callId.isNotEmpty) {
      final version = _intValue(raw['eventVersion'] ?? raw['version']);
      final previous = _lastVersions[callId] ?? 0;
      if (version > 0 && version <= previous) return;
      if (version > 0) _lastVersions[callId] = version;
      _eventBus.publish(
        LiveKitCallEvent(
          type: type,
          callId: callId,
          version: version,
          reason: raw['reason']?.toString(),
          actorId: raw['actorId']?.toString(),
        ),
      );
      if (const {
        'call.rejected',
        'call.cancelled',
        'call.ended',
        'call.timeout',
        'call.group_ended',
      }.contains(type)) {
        _seenInviteIds.remove(callId);
        _lastVersions.remove(callId);
        _releaseNativeIncomingScreen(callId);
        unawaited(_nativeUi.end(callId));
      }
    }
    if (type != 'call.invite' && type != 'call.group_invite') return;
    if (callId.isEmpty || !_seenInviteIds.add(callId)) return;
    unawaited(_handleInvite(raw, type, callId));
  }

  Future<void> _handleInvite(
    Map<dynamic, dynamic> raw,
    String type,
    String callId,
  ) async {
    // 不再因为一个遗留的通话页静默吞掉来电。先用服务端状态核验该页：
    // 已结束则关闭它并展示新来电；确有另一通进行中的电话则明确拒绝为忙线。
    if (_callActivity.isActive &&
        !await _releaseStaleActivityForIncoming(callId)) {
      await _rejectAsBusy(callId);
      return;
    }
    final args = callLaunchArgsFromPayload(
      raw: raw,
      type: type,
      currentUserId: _currentUserId(),
      conversationTitleByChatId: _conversationTitleByChatId,
    );
    debugPrint(
      '[LiveKitCallInvitationBinding] 收到来电: callId=$callId, '
      'type=$type, entryMode=${args.entryMode.name}',
    );
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        !_nativeUi.supported) {
      unawaited(_openCallPage(args));
    } else {
      _nativeIncomingScreenLeases[callId] ??= _screenAwake.acquire();
      unawaited(_nativeUi.showIncoming(args));
    }
  }

  Future<bool> _releaseStaleActivityForIncoming(String incomingCallId) async {
    final activeCallId = _callActivity.activeCallId;
    if (activeCallId == incomingCallId) return false;
    // 去电页尚未拿到 callId 时，不能误判为遗留页并弹出第二个通话界面。
    if (activeCallId == null || activeCallId.isEmpty) return false;
    try {
      final response = await _dio.get(
        '/system/im/call/state',
        queryParameters: {'callSessionId': activeCallId},
      );
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final state = data is Map ? data['state']?.toString().toLowerCase() : '';
      if (const {'ringing', 'connecting', 'connected'}.contains(state)) {
        debugPrint(
          '[LiveKitCallInvitationBinding] 拒绝并发来电 $incomingCallId：'
          '当前通话 $activeCallId 仍处于 $state',
        );
        return false;
      }
    } catch (error) {
      // 无法完成状态核验时宁可按忙线处理，避免两个页面争用同一套媒体资源。
      debugPrint('[LiveKitCallInvitationBinding] 通话占用状态核验失败: $error');
      return false;
    }

    debugPrint(
      '[LiveKitCallInvitationBinding] 关闭遗留通话页 $activeCallId，展示来电 $incomingCallId',
    );
    _eventBus.publish(
      LiveKitCallEvent(
        type: 'call.ended',
        callId: activeCallId,
        reason: '通话已结束',
      ),
    );
    for (var attempt = 0; attempt < 10 && _callActivity.isActive; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return !_callActivity.isActive;
  }

  Future<void> _rejectAsBusy(String callId) async {
    _seenInviteIds.remove(callId);
    try {
      await _dio.post(
        '/system/im/call/reject',
        data: {'callSessionId': callId, 'reason': 'busy'},
      );
    } catch (error) {
      debugPrint('[LiveKitCallInvitationBinding] 忙线拒绝来电失败: $error');
    }
  }

  Future<void> _openCallPage(CallLaunchArgs args) async {
    try {
      await _router().pushNamed(RouteNames.call, extra: args);
    } catch (error, stackTrace) {
      _seenInviteIds.remove(args.callSessionId);
      debugPrint('[LiveKitCallInvitationBinding] 打开通话页失败: $error\n$stackTrace');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reconcileActiveCall());
    }
  }

  Future<void> _reconcileActiveCall() {
    final existing = _reconcileFuture;
    if (existing != null) return existing;
    final operation = _reconcileActiveCallOnce();
    _reconcileFuture = operation.whenComplete(() => _reconcileFuture = null);
    return _reconcileFuture!;
  }

  Future<void> _reconcileActiveCallOnce() async {
    if (_disposed || _callActivity.isActive) return;
    try {
      final response = await _dio.get('/system/im/call/active');
      final body = response.data;
      if (body is! Map) return;
      final data = body['data'];
      if (data is! Map || data['callSessionId'] == null) return;
      final state = data['state']?.toString().toLowerCase() ?? '';
      if (!const {'ringing', 'connecting', 'connected'}.contains(state)) return;
      final recovered = <dynamic, dynamic>{
        ...data,
        'type': data['groupId'] == null ? 'call.invite' : 'call.group_invite',
        'callId': data['callSessionId'],
        'callerProfile': <String, dynamic>{
          'userId': data['callerId'],
          'displayName': data['callerName'],
          'avatarUrl': data['callerAvatar'],
        },
        '_recoveredState': state,
        '_recoveredIncoming': data['incoming'] == true,
      };
      debugPrint(
        '[LiveKitCallInvitationBinding] 恢复活跃通话: '
        '${data['callSessionId']}, state=$state, incoming=${data['incoming']}',
      );
      _handlePayload(recovered);
    } catch (error, stackTrace) {
      // 对账是实时事件的补偿路径；短暂失败不能关闭 Socket 或形成重试死循环。
      debugPrint(
        '[LiveKitCallInvitationBinding] 活跃通话对账失败: $error\n$stackTrace',
      );
    }
  }

  void _onNativeAction(NativeCallAction action) {
    switch (action.type) {
      case NativeCallActionType.accept:
        _releaseNativeIncomingScreen(action.args.callSessionId);
        _router().pushNamed(
          RouteNames.call,
          extra: action.args.copyWith(acceptedFromNative: true),
        );
      case NativeCallActionType.decline:
        _releaseNativeIncomingScreen(action.args.callSessionId);
        unawaited(
          _dio.post(
            '/system/im/call/reject',
            data: {'callSessionId': action.args.callSessionId},
          ),
        );
      case NativeCallActionType.ended:
      case NativeCallActionType.timeout:
        _releaseNativeIncomingScreen(action.args.callSessionId);
        break;
    }
  }

  void _releaseNativeIncomingScreen(String callId) {
    final lease = _nativeIncomingScreenLeases.remove(callId);
    if (lease != null) _screenAwake.release(lease);
  }

  int _intValue(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text) ?? 0,
    _ => 0,
  };

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _nativeActionSubscription?.cancel();
    _subscription = null;
    _nativeActionSubscription = null;
    _nativeIncomingScreenLeases.values.forEach(_screenAwake.release);
    _nativeIncomingScreenLeases.clear();
  }
}
