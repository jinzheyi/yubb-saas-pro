import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/accept_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/cancel_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/create_call_invite_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/hangup_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/reject_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/sync_active_call_state_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_socket_payload_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/active_call_registry.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_media_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

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
    this._activeCallRegistry,
    this._payloadResolver,
    Stream<CallSocketEvent> socketEvents,
  ) : super(const CallState()) {
    _socketSubscription = socketEvents.listen(_onSocketEvent);
  }

  final CreateCallInviteUseCase _createCallInviteUseCase;
  final AcceptCallUseCase _acceptCallUseCase;
  final RejectCallUseCase _rejectCallUseCase;
  final CancelCallUseCase _cancelCallUseCase;
  final HangupCallUseCase _hangupCallUseCase;
  final SyncActiveCallStateUseCase _syncActiveCallStateUseCase;
  final CallMediaController _callMediaController;
  final CallCoordinator _callCoordinator;
  final ActiveCallRegistry _activeCallRegistry;
  final CallSocketPayloadResolver _payloadResolver;

  StreamSubscription<CallSocketEvent>? _socketSubscription;
  Timer? _elapsedTimer;

  Future<void> initialize(CallLaunchArgs args) async {
    _activeCallRegistry.register(args);
    state = state.copyWith(
      callSessionId: args.callSessionId,
      chatId: args.chatId,
      callType: args.callType,
      entryMode: args.entryMode,
      title: args.title,
      pageStatus: CallPageStatus.loading,
      isIncoming: args.entryMode == CallEntryMode.incoming,
      isOutgoing: args.entryMode == CallEntryMode.outgoing,
      error: null,
    );
    try {
      if (args.entryMode == CallEntryMode.restore) {
        final synced = await _syncActiveCallStateUseCase.execute(
          callSessionId: args.callSessionId,
        );
        _applySyncedState(synced);
        if (synced.pageStatus == CallPageStatus.connected) {
          _startElapsedTimer();
        }
      } else if (args.entryMode == CallEntryMode.incoming) {
        state = state.copyWith(pageStatus: CallPageStatus.ringing);
      } else {
        state = state.copyWith(pageStatus: CallPageStatus.ringing);
      }
    } catch (error, stackTrace) {
      state = state.copyWith(
        pageStatus: CallPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  Future<void> startOutgoing() async {
    try {
      var effectiveSessionId = state.callSessionId;
      if (state.callSessionId.isEmpty &&
          state.chatId.isNotEmpty &&
          state.callType != null) {
        final invite = await _createCallInviteUseCase.execute(
          chatId: state.chatId,
          callType: state.callType!,
        );
        effectiveSessionId = invite.callSessionId;
        state = state.copyWith(
          callSessionId: effectiveSessionId,
          chatId: invite.chatId.isEmpty ? state.chatId : invite.chatId,
          callType: invite.callType ?? state.callType,
          title: invite.title ?? state.title,
          callerProfile: invite.callerProfile ?? state.callerProfile,
          calleeProfile: invite.calleeProfile ?? state.calleeProfile,
          error: null,
        );
      }
      _activeCallRegistry.register(
        _buildLaunchArgs(callSessionId: effectiveSessionId),
      );
      state = state.copyWith(
        pageStatus: CallPageStatus.ringing,
        isOutgoing: true,
      );
    } catch (error, stackTrace) {
      _enterFailed(
        CallEndReason.rtcError,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  Future<void> accept() async {
    state = state.copyWith(
      pageStatus: CallPageStatus.accepting,
      hasAccepted: true,
    );
    try {
      await _acceptCallUseCase.execute(callSessionId: state.callSessionId);
      final mediaState = await _callMediaController.prepare(
        state.mediaState,
        state.callType ?? CallType.audio,
      );
      state = state.copyWith(
        pageStatus: CallPageStatus.connecting,
        mediaState: mediaState,
      );
      final args = _buildLaunchArgs(entryMode: CallEntryMode.restore);
      _activeCallRegistry.register(args);
      _callCoordinator.openCallSession(args);
    } catch (error, stackTrace) {
      _enterFailed(
        CallEndReason.permissionDenied,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  Future<void> reject() async {
    await _rejectCallUseCase.execute(callSessionId: state.callSessionId);
    _enterEnded(CallEndReason.rejectedByCallee);
  }

  Future<void> cancel() async {
    await _cancelCallUseCase.execute(callSessionId: state.callSessionId);
    _enterEnded(CallEndReason.cancelledByCaller);
  }

  Future<void> hangup() async {
    state = state.copyWith(pageStatus: CallPageStatus.ending);
    await _hangupCallUseCase.execute(callSessionId: state.callSessionId);
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.hangupByLocal, mediaState: mediaState);
  }

  void markConnected() {
    _startElapsedTimer();
    state = state.copyWith(
      pageStatus: CallPageStatus.connected,
      hasConnected: true,
      mediaState: _callMediaController.markConnected(state.mediaState),
    );
  }

  void toggleMute() {
    state = state.copyWith(
      mediaState: _callMediaController.toggleMute(state.mediaState),
    );
  }

  void toggleSpeaker() {
    state = state.copyWith(
      mediaState: _callMediaController.toggleSpeaker(state.mediaState),
    );
  }

  void toggleCamera() {
    state = state.copyWith(
      mediaState: _callMediaController.toggleCamera(state.mediaState),
    );
  }

  void switchCamera() {
    state = state.copyWith(
      mediaState: _callMediaController.switchCamera(state.mediaState),
    );
  }

  Future<void> _onSocketEvent(CallSocketEvent event) async {
    if (event.callSessionId != state.callSessionId) {
      return;
    }
    switch (event.type) {
      case CallSocketEventType.accepted:
        await onAccepted();
        break;
      case CallSocketEventType.busy:
        await onBusy();
        break;
      case CallSocketEventType.ended:
        await onEnded();
        break;
      case CallSocketEventType.cancelled:
        await onCancelled();
        break;
      case CallSocketEventType.rejected:
        await onRejected();
        break;
      case CallSocketEventType.timeout:
        await onTimeout();
        break;
      case CallSocketEventType.stateSync:
        await onStateSync();
        break;
      case CallSocketEventType.deviceTerminated:
        await onDeviceTerminated();
        break;
      case CallSocketEventType.mediaTokenIssued:
        await onMediaTokenIssued(event);
        break;
      case CallSocketEventType.invite:
        onInviteReceived(event);
        break;
    }
  }

  void onInviteReceived(CallSocketEvent event) {
    final resolved = _payloadResolver.resolve(
      event.payload,
      fallbackCallSessionId: event.callSessionId,
    );
    final args = _buildLaunchArgs(
      callSessionId: event.callSessionId,
      entryMode: CallEntryMode.incoming,
    );
    _activeCallRegistry.register(args);
    state = state.copyWith(
      callSessionId: event.callSessionId,
      entryMode: CallEntryMode.incoming,
      isIncoming: true,
      isOutgoing: false,
      pageStatus: CallPageStatus.ringing,
      endReason: CallEndReason.none,
      title: resolved.title ?? state.title,
      callerProfile: resolved.callerProfile ?? state.callerProfile,
      calleeProfile: resolved.calleeProfile ?? state.calleeProfile,
      acceptedDeviceId: resolved.acceptedDeviceId,
      roomBundle: resolved.roomBundle,
    );
  }

  Future<void> onAccepted() async {
    _enterConnecting();
    if (state.entryMode != CallEntryMode.restore) {
      final args = _buildLaunchArgs(entryMode: CallEntryMode.restore);
      _activeCallRegistry.register(args);
      _callCoordinator.openCallSession(args);
    }
  }

  Future<void> onRejected() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.rejectedByCallee, mediaState: mediaState);
  }

  Future<void> onBusy() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.busy, mediaState: mediaState);
  }

  Future<void> onCancelled() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.cancelledByCaller, mediaState: mediaState);
  }

  Future<void> onEnded() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.hangupByRemote, mediaState: mediaState);
  }

  Future<void> onTimeout() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.noAnswer, mediaState: mediaState);
  }

  Future<void> onStateSync() async {
    final synced = await _syncActiveCallStateUseCase.execute(
      callSessionId: state.callSessionId,
    );
    _applySyncedState(synced);
    if (synced.pageStatus == CallPageStatus.connected) {
      _activeCallRegistry.register(
        _buildLaunchArgs(entryMode: CallEntryMode.restore),
      );
      _startElapsedTimer();
    } else if (synced.pageStatus == CallPageStatus.reconnecting ||
        synced.pageStatus == CallPageStatus.connecting) {
      _stopElapsedTimer();
    } else if (synced.pageStatus == CallPageStatus.ended ||
        synced.pageStatus == CallPageStatus.failed) {
      _activeCallRegistry.clear(state.callSessionId);
      _stopElapsedTimer();
    }
  }

  Future<void> onDeviceTerminated() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.kickedByOtherDevice, mediaState: mediaState);
  }

  Future<void> onMediaTokenIssued(CallSocketEvent event) async {
    final resolved = _payloadResolver.resolve(
      event.payload,
      fallbackCallSessionId: state.callSessionId,
    );
    final roomBundle = resolved.roomBundle ?? state.roomBundle;
    final acceptedDeviceId =
        resolved.acceptedDeviceId ?? state.acceptedDeviceId;
    var mediaState = state.mediaState;
    try {
      if (roomBundle != null) {
        mediaState = await _callMediaController.prepareJoin(
          state.mediaState,
          callType: state.callType ?? CallType.audio,
          roomBundle: roomBundle,
        );
      }
    } catch (error, stackTrace) {
      _enterFailed(
        CallEndReason.rtcError,
        error: AppErrorMapper.map(error, stackTrace),
      );
      return;
    }
    if (state.pageStatus == CallPageStatus.accepting ||
        state.pageStatus == CallPageStatus.ringing ||
        state.pageStatus == CallPageStatus.connecting) {
      _enterConnecting(
        acceptedDeviceId: acceptedDeviceId,
        roomBundle: roomBundle,
        mediaState: mediaState,
      );
    }
  }

  void markReconnecting() {
    _stopElapsedTimer();
    state = state.copyWith(
      pageStatus: CallPageStatus.reconnecting,
      mediaState: _callMediaController.markReconnecting(state.mediaState),
    );
  }

  void restoreConnected() {
    _startElapsedTimer();
    state = state.copyWith(
      pageStatus: CallPageStatus.connected,
      hasConnected: true,
      mediaState: _callMediaController.markConnected(state.mediaState),
    );
  }

  Future<void> markRtcFailure({
    CallEndReason endReason = CallEndReason.rtcError,
  }) async {
    _stopElapsedTimer();
    _activeCallRegistry.clear(state.callSessionId);
    state = state.copyWith(
      pageStatus: CallPageStatus.failed,
      endReason: endReason,
      mediaState: _callMediaController.markFailed(state.mediaState),
    );
  }

  Future<void> markPermissionDenied() async {
    _stopElapsedTimer();
    _activeCallRegistry.clear(state.callSessionId);
    state = state.copyWith(
      pageStatus: CallPageStatus.failed,
      endReason: CallEndReason.permissionDenied,
      mediaState: _callMediaController.markFailed(state.mediaState),
    );
  }

  void markRemoteTrackReady() {
    if (state.pageStatus == CallPageStatus.connecting ||
        state.pageStatus == CallPageStatus.reconnecting) {
      restoreConnected();
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && state.pageStatus == CallPageStatus.connected) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  void _enterEnded(CallEndReason endReason, {CallMediaState? mediaState}) {
    _stopElapsedTimer();
    _activeCallRegistry.clear(state.callSessionId);
    state = state.copyWith(
      pageStatus: CallPageStatus.ended,
      endReason: endReason,
      mediaState: mediaState ?? state.mediaState,
    );
  }

  void _enterFailed(CallEndReason endReason, {required AppError error}) {
    _stopElapsedTimer();
    _activeCallRegistry.clear(state.callSessionId);
    state = state.copyWith(
      pageStatus: CallPageStatus.failed,
      endReason: endReason,
      error: error,
    );
  }

  void _applySyncedState(ActiveCallStateResult synced) {
    final nextPageStatus = synced.pageStatus;
    state = state.copyWith(
      pageStatus: nextPageStatus,
      elapsedSeconds: synced.elapsedSeconds,
      callSessionId: synced.callSessionId.isEmpty
          ? state.callSessionId
          : synced.callSessionId,
      chatId: synced.chatId.isEmpty ? state.chatId : synced.chatId,
      callType: synced.callType ?? state.callType,
      title: synced.title ?? state.title,
      callerProfile: synced.callerProfile ?? state.callerProfile,
      calleeProfile: synced.calleeProfile ?? state.calleeProfile,
      acceptedDeviceId: synced.acceptedDeviceId ?? state.acceptedDeviceId,
      roomBundle: synced.roomBundle ?? state.roomBundle,
      mediaState: _syncMediaStateWithPageStatus(
        state.mediaState,
        nextPageStatus,
      ),
      error: nextPageStatus == CallPageStatus.failed ? state.error : null,
    );
  }

  CallMediaState _syncMediaStateWithPageStatus(
    CallMediaState current,
    CallPageStatus pageStatus,
  ) {
    switch (pageStatus) {
      case CallPageStatus.connected:
        return _callMediaController.markConnected(current);
      case CallPageStatus.reconnecting:
        return _callMediaController.markReconnecting(current);
      case CallPageStatus.connecting:
      case CallPageStatus.accepting:
      case CallPageStatus.loading:
        return current.copyWith(
          rtcConnectionStatus: current.localTrackReady
              ? RtcConnectionStatus.joining
              : RtcConnectionStatus.preparing,
        );
      case CallPageStatus.ended:
      case CallPageStatus.failed:
        return _callMediaController.markFailed(current);
      case CallPageStatus.initial:
      case CallPageStatus.ringing:
      case CallPageStatus.ending:
        return current;
    }
  }

  void _enterConnecting({
    String? acceptedDeviceId,
    RtcRoomBundle? roomBundle,
    CallMediaState? mediaState,
  }) {
    state = state.copyWith(
      pageStatus: CallPageStatus.connecting,
      acceptedDeviceId: acceptedDeviceId ?? state.acceptedDeviceId,
      roomBundle: roomBundle ?? state.roomBundle,
      mediaState: mediaState ?? state.mediaState,
    );
  }

  CallLaunchArgs _buildLaunchArgs({
    String? callSessionId,
    CallEntryMode? entryMode,
  }) {
    return CallLaunchArgs(
      callSessionId: callSessionId ?? state.callSessionId,
      chatId: state.chatId,
      callType: state.callType ?? CallType.audio,
      entryMode: entryMode ?? state.entryMode ?? CallEntryMode.outgoing,
      title: state.title,
      inviteId: null,
      fromUserId: null,
      toUserId: null,
    );
  }

  @override
  void dispose() {
    _stopElapsedTimer();
    _socketSubscription?.cancel();
    super.dispose();
  }
}
