import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

class CallSessionPage extends ConsumerStatefulWidget {
  const CallSessionPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<CallSessionPage> createState() => _CallSessionPageState();
}

class _CallSessionPageState extends ConsumerState<CallSessionPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(callControllerProvider.notifier)
          .initialize(widget.args.copyWith(entryMode: CallEntryMode.restore)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      final wasFinished =
          previous != null &&
          (previous.pageStatus == CallPageStatus.ended ||
              previous.pageStatus == CallPageStatus.failed);
      final isFinished =
          next.pageStatus == CallPageStatus.ended ||
          next.pageStatus == CallPageStatus.failed;
      if (!wasFinished && isFinished && context.mounted) {
        final navigator = Navigator.of(context);
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted && navigator.canPop()) {
            navigator.pop();
          }
        });
      }
    });

    final state = ref.watch(activeCallStateProvider);
    final isVideoEnabled = ref.watch(isCallVideoEnabledProvider);
    final canToggleControls = ref.watch(canToggleCallControlsProvider);
    final canSwitchCamera = ref.watch(canSwitchCallCameraProvider);
    final canHangup = ref.watch(canHangupCallProvider);
    final bannerText = ref.watch(callSessionBannerTextProvider);
    final sessionStatusText = ref.watch(
      callSessionStatusTextProvider(widget.args),
    );
    final mediaState = state.mediaState;
    final title = state.title ?? widget.args.title ?? '通话中';
    final remoteAvatarUrl = state.isIncoming
        ? state.callerProfile?.avatarUrl
        : state.calleeProfile?.avatarUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1522),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sessionStatusText,
                style: const TextStyle(fontSize: 14, color: Color(0xFFB8C0CC)),
              ),
              if (bannerText != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF172033),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2B364B)),
                  ),
                  child: Text(
                    bannerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB8C0CC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2334),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2B364B)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppAvatar(
                      name: title,
                      avatarUrl: remoteAvatarUrl,
                      seed: state.callerProfile?.userId ?? state.calleeProfile?.userId,
                      backgroundColor: const Color(0xFF246BFD),
                      size: 72,
                      borderRadius: 24,
                      fontSize: 28,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Icon(
                      isVideoEnabled
                          ? Icons.video_call_rounded
                          : Icons.call_rounded,
                      size: 42,
                      color: const Color(0xFF8F96A3),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isVideoEnabled ? '视频通话连接中' : '语音通话连接中',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFE5EAF3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mediaState.remoteTrackReady
                          ? '远端媒体已就绪'
                          : '远端媒体接入前，当前页面先消费连接态、重连态与失败态',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8F96A3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.pageStatus == CallPageStatus.failed) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF331A22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF5B2A35)),
                  ),
                  child: const Text(
                    '当前会话将按失败态回退',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFFC1C7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallToolButton(
                    icon: mediaState.microphoneEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: mediaState.microphoneEnabled ? '静音' : '取消静音',
                    onTap: canToggleControls
                        ? () => ref
                              .read(callControllerProvider.notifier)
                              .toggleMute()
                        : null,
                  ),
                  _CallToolButton(
                    icon: mediaState.speakerEnabled
                        ? Icons.volume_up_rounded
                        : Icons.hearing_disabled_rounded,
                    label: mediaState.speakerEnabled ? '扬声器' : '听筒',
                    onTap: canToggleControls
                        ? () => ref
                              .read(callControllerProvider.notifier)
                              .toggleSpeaker()
                        : null,
                  ),
                  if (isVideoEnabled)
                    _CallToolButton(
                      icon: Icons.cameraswitch_outlined,
                      label: strings.callSwitch,
                      onTap: canSwitchCamera
                          ? () => ref
                                .read(callControllerProvider.notifier)
                                .switchCamera()
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: canHangup
                      ? () => ref.read(callControllerProvider.notifier).hangup()
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE6E6),
                    foregroundColor: const Color(0xFFE54D4F),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('挂断'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallToolButton extends StatelessWidget {
  const _CallToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: const Color(0xFF1B2435),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                color: onTap == null ? const Color(0xFF5D6778) : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onTap == null
                ? const Color(0xFF5D6778)
                : const Color(0xFFB8C0CC),
          ),
        ),
      ],
    );
  }
}
