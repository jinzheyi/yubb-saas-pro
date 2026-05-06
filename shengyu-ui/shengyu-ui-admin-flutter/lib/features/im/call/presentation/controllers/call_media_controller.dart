import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';

class CallPermissionCoordinator {
  const CallPermissionCoordinator();

  Future<void> ensurePermissions({required CallType callType}) async {}
}

class CallMediaController {
  const CallMediaController(this._permissionCoordinator);

  final CallPermissionCoordinator _permissionCoordinator;

  Future<CallMediaState> prepare(
    CallMediaState state,
    CallType callType,
  ) async {
    await _permissionCoordinator.ensurePermissions(callType: callType);
    return state.copyWith(
      cameraEnabled: callType == CallType.video,
      localTrackReady: true,
      rtcConnectionStatus: RtcConnectionStatus.preparing,
    );
  }

  Future<CallMediaState> prepareJoin(
    CallMediaState state, {
    required CallType callType,
    required RtcRoomBundle roomBundle,
  }) async {
    final prepared = await prepare(state, callType);
    return prepared.copyWith(
      localTrackReady: true,
      rtcConnectionStatus: RtcConnectionStatus.joining,
    );
  }

  Future<CallMediaState> disposeSession(CallMediaState state) async {
    return state.copyWith(
      localTrackReady: false,
      remoteTrackReady: false,
      rtcConnectionStatus: RtcConnectionStatus.disconnected,
    );
  }

  CallMediaState markReconnecting(CallMediaState state) {
    return state.copyWith(
      rtcConnectionStatus: RtcConnectionStatus.reconnecting,
    );
  }

  CallMediaState markConnected(CallMediaState state) {
    return state.copyWith(
      rtcConnectionStatus: RtcConnectionStatus.connected,
      remoteTrackReady: true,
    );
  }

  CallMediaState markFailed(CallMediaState state) {
    return state.copyWith(
      rtcConnectionStatus: RtcConnectionStatus.disconnected,
      remoteTrackReady: false,
    );
  }

  CallMediaState toggleMute(CallMediaState state) {
    return state.copyWith(microphoneEnabled: !state.microphoneEnabled);
  }

  CallMediaState toggleSpeaker(CallMediaState state) {
    return state.copyWith(speakerEnabled: !state.speakerEnabled);
  }

  CallMediaState toggleCamera(CallMediaState state) {
    return state.copyWith(cameraEnabled: !state.cameraEnabled);
  }

  CallMediaState switchCamera(CallMediaState state) {
    return state.copyWith(frontCamera: !state.frontCamera);
  }
}
