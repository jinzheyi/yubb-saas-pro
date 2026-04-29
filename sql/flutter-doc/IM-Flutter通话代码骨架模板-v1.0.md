# IM Flutter 通话代码骨架模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：通话模块 controller、repository、provider、page、coordinator 的建议代码骨架模板

---

## 1. `call_repository.dart` 模板

```dart
abstract class CallRepository {
  Future<CallInviteResult> createInvite(CreateCallInviteCommand command);

  Future<void> accept({
    required String callSessionId,
  });

  Future<void> reject({
    required String callSessionId,
  });

  Future<void> cancel({
    required String callSessionId,
  });

  Future<void> hangup({
    required String callSessionId,
  });

  Future<ActiveCallStateResult> syncState({
    required String callSessionId,
  });

  Stream<CallSocketEvent> watchSocketEvents();
}
```

---

## 2. `call_controller.dart` 模板

```dart
class CallController extends StateNotifier<CallState> {
  CallController(
    this._createCallInviteUseCase,
    this._acceptCallUseCase,
    this._rejectCallUseCase,
    this._cancelCallUseCase,
    this._hangupCallUseCase,
    this._syncActiveCallStateUseCase,
    this._callMediaController,
    this._callCoordinator,
  ) : super(const CallState());

  final CreateCallInviteUseCase _createCallInviteUseCase;
  final AcceptCallUseCase _acceptCallUseCase;
  final RejectCallUseCase _rejectCallUseCase;
  final CancelCallUseCase _cancelCallUseCase;
  final HangupCallUseCase _hangupCallUseCase;
  final SyncActiveCallStateUseCase _syncActiveCallStateUseCase;
  final CallMediaController _callMediaController;
  final CallCoordinator _callCoordinator;

  Future<void> initialize(CallLaunchArgs args) async {
    state = state.copyWith(
      callSessionId: args.callSessionId,
      chatId: args.chatId,
      callType: args.callType,
      entryMode: args.entryMode,
      pageStatus: CallPageStatus.loading,
    );
  }

  Future<void> startOutgoing() async {
    state = state.copyWith(
      pageStatus: CallPageStatus.ringing,
      isOutgoing: true,
    );
  }

  Future<void> accept() async {
    state = state.copyWith(pageStatus: CallPageStatus.accepting);
    await _acceptCallUseCase.execute(callSessionId: state.callSessionId);
  }

  Future<void> reject() async {
    await _rejectCallUseCase.execute(callSessionId: state.callSessionId);
    state = state.copyWith(pageStatus: CallPageStatus.ended);
  }

  Future<void> cancel() async {
    await _cancelCallUseCase.execute(callSessionId: state.callSessionId);
    state = state.copyWith(pageStatus: CallPageStatus.ended);
  }

  Future<void> hangup() async {
    state = state.copyWith(pageStatus: CallPageStatus.ending);
    await _hangupCallUseCase.execute(callSessionId: state.callSessionId);
    await _callMediaController.disposeSession();
    state = state.copyWith(pageStatus: CallPageStatus.ended);
  }

  Future<void> onSocketEvent(CallSocketEvent event) async {
    switch (event.type) {
      case CallSocketEventType.accepted:
        state = state.copyWith(pageStatus: CallPageStatus.connecting);
        break;
      case CallSocketEventType.ended:
        await _callMediaController.disposeSession();
        state = state.copyWith(pageStatus: CallPageStatus.ended);
        break;
      default:
        break;
    }
  }
}
```

---

## 3. `call_media_controller.dart` 模板

```dart
class CallMediaController {
  CallMediaController(
    this._rtcGatewayClient,
    this._callPermissionCoordinator,
  );

  final RtcGatewayClient _rtcGatewayClient;
  final CallPermissionCoordinator _callPermissionCoordinator;

  Future<void> prepareAndJoin({
    required CallType callType,
    required RtcRoomBundle roomBundle,
  }) async {
    await _callPermissionCoordinator.ensurePermissions(callType: callType);
    await _rtcGatewayClient.join(roomBundle);
  }

  Future<void> toggleMute() {
    return _rtcGatewayClient.toggleMute();
  }

  Future<void> toggleSpeaker() {
    return _rtcGatewayClient.toggleSpeaker();
  }

  Future<void> toggleCamera() {
    return _rtcGatewayClient.toggleCamera();
  }

  Future<void> switchCamera() {
    return _rtcGatewayClient.switchCamera();
  }

  Future<void> disposeSession() {
    return _rtcGatewayClient.disposeSession();
  }
}
```

---

## 4. `call_coordinator.dart` 模板

```dart
class CallCoordinator {
  const CallCoordinator(this._router);

  final AppRouter _router;

  void openIncomingCall(CallLaunchArgs args) {
    _router.pushIncomingCall(args);
  }

  void openOutgoingCall(CallLaunchArgs args) {
    _router.pushOutgoingCall(args);
  }

  void openCallSession(CallLaunchArgs args) {
    _router.pushCallSession(args);
  }

  void closeCallFlow() {
    _router.popCallFlow();
  }
}
```

---

## 5. `call_permission_coordinator.dart` 模板

```dart
class CallPermissionCoordinator {
  CallPermissionCoordinator(this._permissionService);

  final PermissionService _permissionService;

  Future<void> ensurePermissions({
    required CallType callType,
  }) async {
    final microphone = await _permissionService.request(AppPermission.microphone);
    if (microphone.state != PermissionGrantState.granted) {
      throw const PlatformFailure(
        code: PlatformFailureCode.permissionDenied,
        message: 'Microphone permission denied.',
      );
    }

    if (callType == CallType.video) {
      final camera = await _permissionService.request(AppPermission.camera);
      if (camera.state != PermissionGrantState.granted) {
        throw const PlatformFailure(
          code: PlatformFailureCode.permissionDenied,
          message: 'Camera permission denied.',
        );
      }
    }
  }
}
```

---

## 6. provider 模板

```dart
final callRepositoryProvider = Provider<CallRepository>((ref) {
  throw UnimplementedError();
});

final callPermissionCoordinatorProvider =
    Provider<CallPermissionCoordinator>((ref) {
  return CallPermissionCoordinator(ref.watch(permissionServiceProvider));
});

final callMediaControllerProvider = Provider<CallMediaController>((ref) {
  return CallMediaController(
    ref.watch(rtcGatewayClientProvider),
    ref.watch(callPermissionCoordinatorProvider),
  );
});

final callCoordinatorProvider = Provider<CallCoordinator>((ref) {
  return CallCoordinator(ref.watch(appRouterBridgeProvider));
});

final callControllerProvider =
    StateNotifierProvider.autoDispose<CallController, CallState>((ref) {
  return CallController(
    ref.watch(createCallInviteUseCaseProvider),
    ref.watch(acceptCallUseCaseProvider),
    ref.watch(rejectCallUseCaseProvider),
    ref.watch(cancelCallUseCaseProvider),
    ref.watch(hangupCallUseCaseProvider),
    ref.watch(syncActiveCallStateUseCaseProvider),
    ref.watch(callMediaControllerProvider),
    ref.watch(callCoordinatorProvider),
  );
});
```

---

## 7. `incoming_call_page.dart` 模板

```dart
class IncomingCallPage extends ConsumerWidget {
  const IncomingCallPage({
    super.key,
    required this.args,
  });

  final CallLaunchArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callControllerProvider);

    return Scaffold(
      body: IncomingCallView(
        state: state,
        onAccept: () => ref.read(callControllerProvider.notifier).accept(),
        onReject: () => ref.read(callControllerProvider.notifier).reject(),
      ),
    );
  }
}
```

---

## 8. `call_session_page.dart` 模板

```dart
class CallSessionPage extends ConsumerWidget {
  const CallSessionPage({
    super.key,
    required this.args,
  });

  final CallLaunchArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callControllerProvider);

    return Scaffold(
      body: CallSessionView(
        state: state,
        onHangup: () => ref.read(callControllerProvider.notifier).hangup(),
        onToggleMute: () => ref.read(callMediaControllerProvider).toggleMute(),
        onToggleSpeaker: () =>
            ref.read(callMediaControllerProvider).toggleSpeaker(),
        onToggleCamera: () =>
            ref.read(callMediaControllerProvider).toggleCamera(),
      ),
    );
  }
}
```

---

## 9. 结论

这套骨架足以支撑通话模块从设计态进入代码生成态，后续只需要继续补：

1. DTO / mapper
2. RtcGatewayClient 实现
3. 页面组件拆分
