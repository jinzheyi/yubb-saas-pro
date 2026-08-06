import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_floating_window.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/permission_denied_dialog.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 去电界面 - 1:1 复刻微信设计
///
/// 微信去电界面特征：
/// - 语音通话：深色模糊背景 + 圆形头像 + 昵称 + 状态文字 + 底部3个圆形按钮
/// - 视频通话：摄像头预览全屏 + 圆形头像 + 昵称 + 状态文字 + 底部两排按钮
/// - 左上角图标：最小化悬浮窗
/// - 视频通话第二排左侧按钮：最小化悬浮窗
class OutgoingCallPage extends ConsumerStatefulWidget {
  const OutgoingCallPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends ConsumerState<OutgoingCallPage> {
  AudioPlayer? _ringtonePlayer;

  @override
  void initState() {
    super.initState();
    // 从悬浮窗恢复时不播放铃声（通话已建立）
    if (widget.args.entryMode != CallEntryMode.restore) {
      // 【关键修复】在 Future.microtask 之前启动铃声，
      // 避免 _configureAudioSession() 重新配置 AudioSession 中断铃声播放
      _startRingtone();
    }
    Future.microtask(() async {
      final controller = ref.read(callControllerProvider.notifier);
      await controller.initialize(widget.args);
      // 从悬浮窗恢复时，跳过 startOutgoing()，避免重新初始化媒体和音频状态
      if (widget.args.entryMode != CallEntryMode.restore) {
        await controller.startOutgoing();
      }
    });
  }

  Future<void> _startRingtone() async {
    try {
      // 关键修复：铃声播放使用 playback category，避免占用通话音频会话
      // playAndRecord 会激活麦克风，而铃声播放阶段不需要麦克风
      // 麦克风会在 CallMediaController.prepare() 中正确配置
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.notification,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));

      _ringtonePlayer = AudioPlayer();
      await _ringtonePlayer!.setAsset('assets/sounds/call_ringtone.mp3');
      await _ringtonePlayer!.setLoopMode(LoopMode.one);
      await _ringtonePlayer!.play();
      debugPrint('[OutgoingCallPage] 铃声播放成功');
    } catch (e) {
      debugPrint('[OutgoingCallPage] 播放铃声失败: $e');
    }
  }

  void _stopRingtone() {
    _ringtonePlayer?.stop();
    _ringtonePlayer?.dispose();
    _ringtonePlayer = null;
  }

  /// 最小化到悬浮窗
  void _minimizeToFloatingWindow() {
    final manager = ref.read(callFloatingWindowManagerProvider);
    if (manager.isVisible) return;

    // 保存当前媒体状态，恢复时保留摄像头/麦克风等设置
    final state = ref.read(activeCallStateProvider);
    manager.saveMediaState(state.mediaState);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // 在创建悬浮窗前先获取 controller 引用，避免 widget 销毁后无法访问 ref
    final controller = ref.read(callControllerProvider.notifier);

    // 获取 GoRouter 实例用于后续导航（避免依赖已销毁的 context）
    final router = ref.read(appRouterProvider);
    final callArgs = widget.args;

    manager.show(
      rootOverlay: overlay,
      builder: (context) => CallFloatingWindow(
        onRestore: () {
          manager.hide();
        },
        onHangup: () async {
          manager.hide();
          // 使用预先获取的 controller 引用，避免 widget 销毁后访问 ref 报错
          await controller.cancel();
        },
      ),
      callArgs: callArgs,
      routeName: RouteNames.callOutgoing,
      onRestore: () {
        // 点击悬浮窗恢复到通话界面
        manager.hide();
        // 使用 GoRouter 实例直接导航，避免依赖已销毁的页面 context
        router.pushNamed(
          RouteNames.callOutgoing,
          extra: callArgs.copyWith(entryMode: CallEntryMode.restore),
        );
      },
    );

    // 关闭当前通话页面
    if (context.mounted) context.pop();
  }

  @override
  void dispose() {
    _stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      // 通话连接成功时停止铃声
      if (next.pageStatus == CallPageStatus.connected) {
        _stopRingtone();
      }

      // 通话结束时自动移除悬浮窗
      if (next.pageStatus == CallPageStatus.ended ||
          next.pageStatus == CallPageStatus.failed) {
        ref.read(callFloatingWindowManagerProvider).hide();
      }

      if (next.pageStatus == CallPageStatus.failed &&
          next.error?.message.contains('权限') == true &&
          context.mounted) {
        final isPermanentlyDenied =
            next.error?.message.contains('永久') == true;
        final permissionType =
            next.error?.message.contains('麦克风') == true ? '麦克风' : '摄像头';

        PermissionHandler.handlePermissionDenied(
          context,
          permissionType: permissionType,
          isPermanentlyDenied: isPermanentlyDenied,
          errorMessage: next.error?.message ?? '权限被拒绝',
        );
      }

      if ((next.pageStatus == CallPageStatus.ended ||
              next.pageStatus == CallPageStatus.failed) &&
          context.mounted) {
        final navigator = Navigator.of(context);
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (mounted && navigator.canPop()) {
            navigator.pop();
          }
        });
      }
    });

    final state = ref.watch(activeCallStateProvider);
    final statusText = ref.watch(outgoingCallStatusTextProvider);
    final canCancel = ref.watch(canCancelOutgoingCallProvider);
    final title = state.title ?? widget.args.title ?? '新通话';
    final avatarUrl = state.calleeProfile?.avatarUrl;
    final isVideoCall = widget.args.callType == CallType.video;
    final mediaState = state.mediaState;
    final controller = ref.read(callControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景层
          if (isVideoCall && mediaState.localVideoRenderer != null && mediaState.cameraEnabled)
            // 视频通话：摄像头预览全屏（摄像头开启时）
            Positioned.fill(
              child: RTCVideoView(
                mediaState.localVideoRenderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: true,
              ),
            )
          else
            // 语音通话或摄像头关闭：纯色深色背景（微信风格）
            Positioned.fill(
              child: Container(
                color: const Color(0xFF3A3A3A),
              ),
            ),

          // 主内容区域
          SafeArea(
            child: Column(
              children: [
                // 顶部留白
                const Spacer(flex: 2),

                // 头像 + 昵称 + 状态文字
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 圆角矩形头像 120x120（微信风格，视频通话时较小 80x80）
                    AppAvatar(
                      name: title,
                      avatarUrl: avatarUrl,
                      seed: state.calleeProfile?.userId,
                      size: isVideoCall ? 80 : 120,
                      borderRadius: isVideoCall ? 8 : 12,
                      fontSize: isVideoCall ? 32 : 40,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    // 昵称 20px 白色
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 状态文字 14px 灰色
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),

                // 中间留白
                const Spacer(flex: 3),

                // 底部按钮区域
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isVideoCall) ...[
                        // 视频通话：第一排3个白色圆形按钮（麦克风/扬声器/摄像头）
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _WeChatCallButton(
                              icon: mediaState.microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                              label: mediaState.microphoneEnabled ? '麦克风已开' : '麦克风已关',
                              backgroundColor: Colors.white,
                              iconColor: Colors.black,
                              labelColor: Colors.white,
                              onTap: () => controller.toggleMute(),
                            ),
                            _WeChatCallButton(
                              icon: mediaState.speakerEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                              label: mediaState.speakerEnabled ? '扬声器已开' : '扬声器已关',
                              backgroundColor: Colors.white,
                              iconColor: Colors.black,
                              labelColor: Colors.white,
                              onTap: () => controller.toggleSpeaker(),
                            ),
                            _WeChatCallButton(
                              icon: mediaState.cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                              label: mediaState.cameraEnabled ? '摄像头已开' : '摄像头已关',
                              backgroundColor: Colors.white,
                              iconColor: Colors.black,
                              labelColor: Colors.white,
                              onTap: () => controller.toggleCamera(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // 视频通话：第二排按钮（挂断 + 翻转）
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 挂断按钮（红色）
                            _WeChatCallButton(
                              icon: Icons.call_end_rounded,
                              label: '取消',
                              backgroundColor: const Color(0xFFE54D4F),
                              iconColor: Colors.white,
                              labelColor: Colors.white,
                              size: 65,
                              onTap: canCancel
                                  ? () async {
                                      await controller.cancel();
                                      if (context.mounted) context.pop();
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 40),
                            // 翻转摄像头按钮（Web 平台不支持，隐藏）
                            if (!kIsWeb)
                              _WeChatCallIconButton(
                                icon: Icons.flip_camera_android_rounded,
                                onTap: () => controller.switchCamera(),
                              ),
                          ],
                        ),
                      ] else ...[
                        // 语音通话：3按钮横排（麦克风/取消/扬声器）- 微信风格
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _WeChatCallButton(
                              icon: mediaState.microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                              label: mediaState.microphoneEnabled ? '麦克风已开' : '麦克风已关',
                              backgroundColor: Colors.white,
                              iconColor: Colors.black,
                              labelColor: Colors.white,
                              size: 70,
                              onTap: () => controller.toggleMute(),
                            ),
                            _WeChatCallButton(
                              icon: Icons.call_end_rounded,
                              label: '取消',
                              backgroundColor: const Color(0xFFE54D4F),
                              iconColor: Colors.white,
                              labelColor: Colors.white,
                              size: 70,
                              onTap: canCancel
                                  ? () async {
                                      await controller.cancel();
                                      if (context.mounted) context.pop();
                                    }
                                  : null,
                            ),
                            _WeChatCallButton(
                              icon: mediaState.speakerEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                              label: mediaState.speakerEnabled ? '扬声器已开' : '扬声器已关',
                              backgroundColor: mediaState.speakerEnabled ? Colors.white : const Color(0xFF555555),
                              iconColor: mediaState.speakerEnabled ? Colors.black : Colors.white,
                              labelColor: Colors.white,
                              size: 70,
                              onTap: () => controller.toggleSpeaker(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 左上角最小化悬浮窗按钮（参考微信设计）
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _minimizeToFloatingWindow,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 微信风格通话按钮
class _WeChatCallButton extends StatelessWidget {
  const _WeChatCallButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.labelColor,
    this.size = 60,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final Color labelColor;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: size * 0.45,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

/// 微信风格通话图标按钮（无文字）
class _WeChatCallIconButton extends StatelessWidget {
  const _WeChatCallIconButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
