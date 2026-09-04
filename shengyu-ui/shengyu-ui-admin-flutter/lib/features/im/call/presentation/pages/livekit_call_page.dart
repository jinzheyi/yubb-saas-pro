import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/call_audio_cue_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/call_screen_awake_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/native_call_ui_gateway.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/livekit_call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_participant_view_model.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_visual_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/livekit_call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_control_button.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_end_overlay.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_identity_panel.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_status_banner.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/direct_video_stage.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/group_video_grid.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';

class LiveKitCallPage extends ConsumerStatefulWidget {
  const LiveKitCallPage({super.key, required this.args});
  final CallLaunchArgs args;

  @override
  ConsumerState<LiveKitCallPage> createState() => _LiveKitCallPageState();
}

class _LiveKitCallPageState extends ConsumerState<LiveKitCallPage> {
  late final LiveKitCallController _controller;
  late final LiveKitCallActivityRegistry _callActivity;
  late final NativeCallUiGateway _nativeCallUi;
  late final CallAudioCueService _audioCues;
  late final CallScreenAwakeService _screenAwake;
  late final Object _screenAwakeLease;
  late final Object _callActivityLease;
  final Set<String> _operations = <String>{};
  bool _accepted = false;
  bool _accepting = false;
  bool _closing = false;
  bool _allowPop = false;
  bool _ringtoneStarted = false;
  bool _endCueStarted = false;
  bool _wasReconnecting = false;
  bool _showRecoveredBanner = false;
  Timer? _operationMessageTimer;
  Timer? _recoveredBannerTimer;

  @override
  void initState() {
    super.initState();
    _callActivity = ref.read(liveKitCallActivityProvider);
    _nativeCallUi = ref.read(nativeCallUiGatewayProvider);
    _callActivityLease = _callActivity.acquire(widget.args.callSessionId);
    _audioCues = ref.read(callAudioCueServiceProvider);
    _screenAwake = ref.read(callScreenAwakeServiceProvider);
    _screenAwakeLease = _screenAwake.acquire();
    _controller = LiveKitCallController(
      dio: ref.read(dioProvider),
      deviceInfoService: ref.read(deviceInfoServiceProvider),
      callEvents: ref.read(liveKitCallEventBusProvider).stream,
      args: widget.args,
      localUserId: ref.read(authSessionProvider).userId,
      onCallIdChanged: (callId) {
        _callActivity.update(_callActivityLease, callId);
        if (widget.args.entryMode == CallEntryMode.outgoing) {
          _startRingingOnce();
        }
      },
    )..addListener(_refresh);
    if (widget.args.entryMode == CallEntryMode.outgoing) {
      unawaited(_runInitial(_controller.startOutgoing()));
    } else if (widget.args.entryMode == CallEntryMode.restore) {
      unawaited(_runInitial(_controller.restore()));
    } else if (widget.args.acceptedFromNative) {
      _accepted = true;
      _accepting = true;
      unawaited(_acceptIncoming());
    } else {
      _startRingingOnce();
    }
  }

  Future<void> _runInitial(Future<void> operation) async {
    try {
      await operation;
    } catch (error) {
      debugPrint('[LiveKitCallPage] 建立通话失败: $error');
      if (_controller.launchFailure == CallLaunchFailure.groupMemberBusy) {
        await _allowAndPop(CallPageResult.groupMemberBusy);
      }
    }
  }

  void _refresh() {
    if (!mounted) return;
    final reconnecting = _controller.reconnecting;
    if (_wasReconnecting && !reconnecting && _controller.connected) {
      _showRecoveredBanner = true;
      _recoveredBannerTimer?.cancel();
      _recoveredBannerTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showRecoveredBanner = false);
      });
    }
    _wasReconnecting = reconnecting;
    if (_controller.operationMessage != null) {
      _operationMessageTimer?.cancel();
      _operationMessageTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) _controller.clearOperationMessage();
      });
    }
    setState(() {});
    if (_controller.answered) unawaited(_audioCues.stopRinging());
    if (_controller.shouldClose && !_closing) {
      unawaited(_showEndThenClose(const Duration(milliseconds: 800)));
    }
  }

  void _startRingingOnce() {
    if (_ringtoneStarted || _endCueStarted) return;
    _ringtoneStarted = true;
    unawaited(_audioCues.startRinging());
  }

  void _playEndCueOnce() {
    if (_endCueStarted) return;
    _endCueStarted = true;
    unawaited(_audioCues.playEndCue());
  }

  Future<void> _acceptIncoming() async {
    if (_operations.contains('accept')) return;
    _operations.add('accept');
    if (mounted) setState(() => _accepting = true);
    await _audioCues.stopRinging();
    try {
      await _controller.acceptIncoming();
      if (!mounted) return;
      _accepted = true;
      await _nativeCallUi.setConnected(_controller.callId);
    } catch (error) {
      debugPrint('[LiveKitCallPage] 接听失败: $error');
    } finally {
      _operations.remove('accept');
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _runDevice(String key, Future<void> Function() operation) async {
    if (_operations.contains(key) || _closing) return;
    setState(() => _operations.add(key));
    try {
      await operation();
    } catch (error) {
      _controller.reportOperationFailure(error);
    } finally {
      if (mounted) setState(() => _operations.remove(key));
    }
  }

  Future<void> _finishAndClose(Future<void> Function() operation) async {
    if (_closing) return;
    setState(() => _closing = true);
    _playEndCueOnce();
    final serverFinalization = operation();
    await _controller.disposeCall();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _allowAndPop();
    unawaited(
      serverFinalization.catchError((Object error) {
        debugPrint('[LiveKitCallPage] 服务端终结等待生命周期收敛: $error');
      }),
    );
  }

  Future<void> _showEndThenClose(Duration delay) async {
    if (_closing) return;
    setState(() => _closing = true);
    _playEndCueOnce();
    await _controller.disposeCall();
    await Future<void>.delayed(delay);
    await _allowAndPop();
  }

  Future<void> _allowAndPop([Object? result]) async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  void _onPopInvoked(bool didPop, Object? _) {
    if (didPop || _closing) return;
    if (_visualState.phase == CallVisualPhase.incoming) {
      unawaited(_finishAndClose(_controller.rejectIncoming));
    } else {
      unawaited(_finishAndClose(_controller.hangup));
    }
  }

  CallVisualState get _visualState => CallVisualStateResolver.resolve(
    strings: AppLocalizations.of(context),
    args: widget.args,
    accepted: _accepted,
    accepting: _accepting,
    closing: _closing,
    connected: _controller.connected,
    reconnecting: _controller.reconnecting,
    hasRemoteParticipant: _controller.hasRemoteParticipant,
    hasLocalParticipant: _controller.hasLocalParticipant,
    shouldClose: _controller.shouldClose,
    elapsedSeconds: _controller.elapsedSeconds,
    remoteParticipantCount: _controller.room?.remoteParticipants.length ?? 0,
    endReason: _controller.endReason,
  );

  @override
  void dispose() {
    _operationMessageTimer?.cancel();
    _recoveredBannerTimer?.cancel();
    _callActivity.release(_callActivityLease);
    _screenAwake.release(_screenAwakeLease);
    _controller.removeListener(_refresh);
    unawaited(_nativeCallUi.end(_controller.callId));
    unawaited(_audioCues.stopRinging());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visualState;
    final groupMembers = widget.args.isGroupCall && widget.args.groupId != null
        ? ref
              .watch(groupMembersFutureProvider(widget.args.groupId!))
              .asData
              ?.value
        : null;
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    final participants = _participants(groupMembers, profile, visual);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _onPopInvoked(false, null),
      },
      child: Focus(
        autofocus: kIsWeb,
        child: PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: _onPopInvoked,
          child: Scaffold(
            backgroundColor: const Color(0xFF0B0B0D),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final maxStageWidth = kIsWeb
                    ? visual.isVideo
                          ? 1200.0
                          : 520.0
                    : constraints.maxWidth;
                final stageWidth = constraints.maxWidth > maxStageWidth
                    ? maxStageWidth
                    : constraints.maxWidth;
                final desktopVideo =
                    kIsWeb && visual.isVideo && constraints.maxWidth >= 900;
                final ratioHeight = stageWidth * 9 / 16;
                final stageHeight = desktopVideo
                    ? constraints.maxHeight > ratioHeight
                          ? ratioHeight
                          : constraints.maxHeight
                    : constraints.maxHeight;
                return Center(
                  child: SizedBox(
                    width: stageWidth,
                    height: stageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _background(visual, participants),
                        if (visual.isVideo)
                          ..._videoOverlays(visual, groupMembers),
                        if (!visual.isVideo)
                          _audioContent(visual, participants, groupMembers),
                        _controls(visual),
                        if (_controller.reconnecting || _showRecoveredBanner)
                          SafeArea(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: CallStatusBanner(
                                  text: _showRecoveredBanner
                                      ? '网络已恢复'
                                      : '网络不稳定，正在恢复…',
                                  recovered: _showRecoveredBanner,
                                ),
                              ),
                            ),
                          ),
                        if (_controller.operationMessage != null)
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: visual.isVideo ? 220 : 160,
                            child: Center(
                              child: CallStatusBanner(
                                text: _controller.operationMessage!,
                              ),
                            ),
                          ),
                        if (visual.phase == CallVisualPhase.ending)
                          CallEndOverlay(
                            text: visual.endText,
                            elapsedText: visual.elapsedText,
                            showElapsed: _controller.elapsedSeconds > 0,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _background(
    CallVisualState visual,
    List<CallParticipantViewModel> participants,
  ) {
    if (!visual.isVideo ||
        const {
          CallVisualPhase.incoming,
          CallVisualPhase.accepting,
          CallVisualPhase.restoring,
        }.contains(visual.phase)) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF202024), Color(0xFF0B0B0D)],
          ),
        ),
      );
    }
    if (visual.isGroup) {
      return Padding(
        // 群视频控制区始终位于网格之外，9 格时也不会遮挡最后一行昵称。
        padding: const EdgeInsets.only(bottom: 190),
        child: GroupVideoGrid(participants: participants),
      );
    }
    final local = participants.where((p) => p.isLocal).firstOrNull;
    final remote = participants.where((p) => !p.isLocal).firstOrNull;
    return DirectVideoStage(
      local: local,
      remote: remote,
      waitingForRemote: visual.phase == CallVisualPhase.waitingRemote,
    );
  }

  List<Widget> _videoOverlays(
    CallVisualState visual,
    List<GroupMember>? groupMembers,
  ) {
    final centered = const {
      CallVisualPhase.incoming,
      CallVisualPhase.accepting,
      CallVisualPhase.restoring,
    }.contains(visual.phase);
    return [
      const Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: 170,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x8C000000), Colors.transparent],
            ),
          ),
        ),
      ),
      if (centered)
        SafeArea(
          child: Align(
            alignment: const Alignment(0, -.42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CallIdentityPanel(
                name: visual.displayName,
                status: visual.statusText,
                avatarUrl: visual.avatarUrl,
                avatar: _groupIdentityAvatar(visual, groupMembers),
              ),
            ),
          ),
        )
      else
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 132, 0),
              child: CallIdentityPanel(
                name: visual.displayName,
                status: visual.statusText,
                compact: true,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _audioContent(
    CallVisualState visual,
    List<CallParticipantViewModel> participants,
    List<GroupMember>? groupMembers,
  ) {
    return SafeArea(
      child: Align(
        alignment: const Alignment(0, -.34),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CallIdentityPanel(
                name: visual.displayName,
                status: visual.statusText,
                avatarUrl: visual.avatarUrl,
                avatar: _groupIdentityAvatar(visual, groupMembers),
              ),
              if (visual.isGroup &&
                  visual.phase == CallVisualPhase.waitingRemote) ...[
                const SizedBox(height: 12),
                Text(
                  '已邀请 ${widget.args.inviteeIds.length} 人 · '
                  '${_controller.room?.remoteParticipants.length ?? 0} 人加入',
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 13,
                  ),
                ),
              ],
              if (visual.isGroup && participants.isNotEmpty) ...[
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 14,
                  children: [
                    for (final participant in participants)
                      SizedBox(
                        width: 58,
                        child: Column(
                          children: [
                            AppAvatar(
                              name: participant.name,
                              avatarUrl: participant.avatarUrl,
                              seed: participant.identity,
                              size: 48,
                              borderRadius: 24,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              participant.isLocal ? '我' : participant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(CallVisualState visual) {
    final incoming =
        visual.phase == CallVisualPhase.incoming ||
        visual.phase == CallVisualPhase.accepting;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 24;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: incoming
                ? _incomingControls(visual)
                : _activeControls(visual),
          ),
        ),
      ),
    );
  }

  Widget? _groupIdentityAvatar(
    CallVisualState visual,
    List<GroupMember>? members,
  ) {
    if (!visual.isGroup ||
        widget.args.conversationTitle?.trim().isNotEmpty != true) {
      return null;
    }
    if (members == null || members.isEmpty) {
      return AppAvatar(
        name: visual.displayName,
        seed: widget.args.groupId ?? visual.displayName,
        size: 96,
        borderRadius: 48,
        fontSize: 34,
      );
    }
    return GroupAvatarWidget.fromMembers(
      members: members
          .take(4)
          .map(
            (member) => GroupAvatarMember(
              userId: member.userId,
              name: member.nickname,
              avatarUrl: member.avatarUrl,
            ),
          )
          .toList(growable: false),
      size: 96,
      borderRadius: 48,
    );
  }

  Widget _incomingControls(CallVisualState visual) {
    final accepting = visual.phase == CallVisualPhase.accepting;
    return Row(
      key: const ValueKey('incoming-controls'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallControlButton(
          icon: Icons.call_end,
          label: '拒绝',
          kind: CallControlKind.destructive,
          large: true,
          enabled: !accepting && !_closing,
          onPressed: () => _finishAndClose(_controller.rejectIncoming),
        ),
        CallControlButton(
          icon: Icons.call,
          label: '接听',
          kind: CallControlKind.accept,
          large: true,
          enabled: !accepting && !_closing,
          loading: accepting,
          onPressed: _acceptIncoming,
        ),
      ],
    );
  }

  Widget _activeControls(CallVisualState visual) {
    final restoring = visual.phase == CallVisualPhase.restoring;
    final mediaEnabled =
        _controller.hasLocalParticipant &&
        !_controller.reconnecting &&
        !_closing &&
        !restoring;
    final destructive = CallControlButton(
      icon: Icons.call_end,
      label: callDestructiveLabel(
        strings: AppLocalizations.of(context),
        args: widget.args,
        phase: visual.phase,
      ),
      kind: CallControlKind.destructive,
      large: true,
      enabled: !_closing,
      onPressed: () => _finishAndClose(_controller.hangup),
    );
    if (restoring) {
      return Center(
        key: const ValueKey('restoring-controls'),
        child: destructive,
      );
    }
    final microphone = CallControlButton(
      icon: _controller.microphoneEnabled ? Icons.mic : Icons.mic_off,
      label: _controller.microphoneEnabled ? '麦克风已开' : '麦克风已关',
      selected: _controller.microphoneEnabled,
      enabled: mediaEnabled,
      loading: _operations.contains('microphone'),
      onPressed: () => _runDevice('microphone', _controller.toggleMicrophone),
    );
    if (!visual.isVideo) {
      final children = <Widget>[microphone, destructive];
      if (_controller.speakerRoutingSupported) {
        children.add(
          CallControlButton(
            icon: _controller.speakerEnabled ? Icons.volume_up : Icons.hearing,
            label: _controller.speakerEnabled ? '扬声器已开' : '扬声器已关',
            selected: _controller.speakerEnabled,
            enabled: mediaEnabled,
            loading: _operations.contains('speaker'),
            onPressed: () => _runDevice('speaker', _controller.toggleSpeaker),
          ),
        );
      }
      return Row(
        key: const ValueKey('audio-controls'),
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      );
    }
    return Column(
      key: const ValueKey('video-controls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            microphone,
            CallControlButton(
              icon: _controller.cameraEnabled
                  ? Icons.videocam
                  : Icons.videocam_off,
              label: _controller.cameraEnabled ? '摄像头已开' : '摄像头已关',
              selected: _controller.cameraEnabled,
              enabled: mediaEnabled,
              loading: _operations.contains('camera'),
              onPressed: () => _runDevice('camera', _controller.toggleCamera),
            ),
            CallControlButton(
              icon: Icons.cameraswitch,
              label: '翻转',
              enabled:
                  mediaEnabled &&
                  _controller.cameraEnabled &&
                  !_operations.contains('camera'),
              loading: _operations.contains('switchCamera'),
              onPressed: () =>
                  _runDevice('switchCamera', _controller.switchCamera),
            ),
          ],
        ),
        const SizedBox(height: 14),
        destructive,
      ],
    );
  }

  List<CallParticipantViewModel> _participants(
    List<GroupMember>? members,
    UserProfile? profile,
    CallVisualState visual,
  ) {
    final result = <CallParticipantViewModel>[];
    final room = _controller.room;
    final local = room?.localParticipant;
    if (local != null) {
      final publication = local.videoTrackPublications.firstOrNull;
      result.add(
        CallParticipantViewModel(
          identity: local.identity,
          name: profile?.nickname.isNotEmpty == true ? profile!.nickname : '我',
          avatarUrl: profile?.avatarUrl,
          isLocal: true,
          cameraEnabled: _controller.cameraEnabled,
          publicationPresent: publication != null,
          videoTrack: publication?.track is VideoTrack
              ? publication!.track as VideoTrack
              : null,
        ),
      );
    }
    for (final remote
        in room?.remoteParticipants.values ?? const <RemoteParticipant>[]) {
      final member = members
          ?.where((item) => item.userId == remote.identity)
          .firstOrNull;
      final publication = remote.videoTrackPublications.firstOrNull;
      result.add(
        CallParticipantViewModel(
          identity: remote.identity,
          name:
              member?.nickname ?? (visual.isGroup ? '成员' : visual.displayName),
          avatarUrl: member?.avatarUrl ?? visual.avatarUrl,
          isLocal: false,
          cameraEnabled: publication != null && !publication.muted,
          publicationPresent: publication != null,
          videoTrack: publication?.track is VideoTrack
              ? publication!.track as VideoTrack
              : null,
        ),
      );
    }
    return result;
  }
}
