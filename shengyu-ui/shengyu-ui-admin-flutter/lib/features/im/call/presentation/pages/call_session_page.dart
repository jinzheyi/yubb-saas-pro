import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_floating_window.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_waiting_banner.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 通话中界面 - 1:1 复刻微信设计
///
/// 视频通话布局：
/// - 远端视频全屏 + 本地视频小窗（100x140，可拖拽）
/// - 顶部信息栏：屏幕共享图标 + 通话时长 + 加号
/// - 底部控制栏：3按钮横排（麦克风/挂断/扬声器）+ 状态文字
/// - 支持锁定防误触（双击解锁）
///
/// 语音通话布局：
/// - 对方头像高斯模糊背景 + 圆角矩形头像（120x120）+ 昵称
/// - 顶部信息栏：屏幕共享图标 + 通话时长 + 加号
/// - 底部控制栏：3按钮横排（麦克风/挂断/扬声器）+ 状态文字
class CallSessionPage extends ConsumerStatefulWidget {
  const CallSessionPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<CallSessionPage> createState() => _CallSessionPageState();
}

class _CallSessionPageState extends ConsumerState<CallSessionPage> {
  /// 锁定状态（防误触）
  bool _isLocked = false;

  /// 本地视频小窗位置（可拖拽）
  Offset _localVideoPosition = const Offset(20, 100);

  /// 拖拽起始位置
  Offset _dragStart = Offset.zero;

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
  void dispose() {
    super.dispose();
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
          await controller.hangup();
        },
      ),
      callArgs: callArgs,
      routeName: RouteNames.callSession,
      onRestore: () {
        // 点击悬浮窗恢复到通话界面
        manager.hide();
        // 使用 GoRouter 实例直接导航，避免依赖已销毁的页面 context
        router.pushNamed(
          RouteNames.callSession,
          extra: callArgs.copyWith(entryMode: CallEntryMode.restore),
        );
      },
    );

    // 关闭当前通话页面
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      // 通话结束时彻底清理悬浮窗状态（防御性调用，Controller 已先执行 forceCleanup）
      if (next.pageStatus == CallPageStatus.ended ||
          next.pageStatus == CallPageStatus.failed) {
        ref.read(callFloatingWindowManagerProvider).forceCleanup();
      }

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
    final canHangup = ref.watch(canHangupCallProvider);
    final sessionStatusText = ref.watch(
      callSessionStatusTextProvider(widget.args),
    );
    final mediaState = state.mediaState;
    final title = state.title ?? widget.args.title ?? '通话中';
    final remoteAvatarUrl = state.isIncoming
        ? state.callerProfile?.avatarUrl
        : state.calleeProfile?.avatarUrl;
    final remoteUserId = state.isIncoming
        ? state.callerProfile?.userId
        : state.calleeProfile?.userId;
    
    // 获取对端的媒体状态（用于显示状态指示器）
    final remoteProfile = state.isIncoming
        ? state.callerProfile
        : state.calleeProfile;
    final remoteCameraEnabled = remoteProfile?.cameraEnabled ?? true;
    final remoteMicrophoneEnabled = remoteProfile?.microphoneEnabled ?? true;

    // 判断是否显示视频视图（视频通话且至少有一路视频流）
    // 注意：本地摄像头关闭不影响远端视频显示
    final showVideoView = isVideoEnabled &&
        (mediaState.localVideoRenderer != null ||
            mediaState.remoteVideoRenderer != null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // 双击解锁
        onDoubleTap: _isLocked
            ? () {
                setState(() => _isLocked = false);
              }
            : null,
        child: Stack(
          children: [
            // ========== 视频通话视图 ==========
            if (showVideoView) ...[
              // 远端视频（全屏）
              if (mediaState.remoteVideoRenderer != null &&
                  mediaState.remoteTrackReady)
                Positioned.fill(
                  child: RTCVideoView(
                    mediaState.remoteVideoRenderer!,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              
              // 远端摄像头关闭时显示头像和状态提示
              if (!remoteCameraEnabled && mediaState.remoteTrackReady)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF3A3A3A),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppAvatar(
                          name: title,
                          avatarUrl: remoteAvatarUrl,
                          seed: remoteUserId,
                          size: 120,
                          borderRadius: 12,
                          fontSize: 40,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam_off_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '摄像头已关闭',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 远端麦克风关闭时显示状态图标（右上角）
              if (!remoteMicrophoneEnabled && mediaState.remoteTrackReady)
                Positioned(
                  top: 60,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),

              // 本地视频预览（小窗，可拖拽，摄像头开启时显示）
              if (mediaState.cameraEnabled &&
                  mediaState.localVideoRenderer != null &&
                  mediaState.localTrackReady)
                Positioned(
                  left: _localVideoPosition.dx,
                  top: _localVideoPosition.dy,
                  child: GestureDetector(
                    onPanStart: (details) {
                      _dragStart = _localVideoPosition;
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _localVideoPosition = Offset(
                          (_dragStart.dx + details.globalPosition.dx -
                                  details.localPosition.dx)
                              .clamp(0, MediaQuery.of(context).size.width - 100),
                          (_dragStart.dy + details.globalPosition.dy -
                                  details.localPosition.dy)
                              .clamp(0, MediaQuery.of(context).size.height - 140),
                        );
                      });
                    },
                    child: Container(
                      width: 100,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: RTCVideoView(
                          mediaState.localVideoRenderer!,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          mirror: true,
                        ),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              // ========== 语音通话视图 ==========
              // 对方头像高斯模糊背景（微信风格）
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF3A3A3A),
                  child: remoteAvatarUrl != null && remoteAvatarUrl.isNotEmpty
                      ? Image.network(
                          remoteAvatarUrl,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.4),
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink(),
                        )
                      : null,
                ),
              ),
              // 模糊遮罩层
              Positioned.fill(
                child: BackdropFilter(
                  filter: dart_ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],

            // ========== 控制层（锁定后隐藏） ==========
            if (!_isLocked)
              SafeArea(
                child: Column(
                  children: [
                    // 通话等待横幅（有新来电时显示）
                    const CallWaitingBanner(),

                    // 顶部信息栏：屏幕共享图标 + 通话时长 + 加号（微信风格）
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // 左上角屏幕共享图标（未激活时灰色，激活时绿色）
                          GestureDetector(
                            onTap: _minimizeToFloatingWindow,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                mediaState.screenShareEnabled
                                    ? Icons.monitor_rounded
                                    : Icons.monitor_outlined,
                                color: mediaState.screenShareEnabled
                                    ? const Color(0xFF07C160)
                                    : Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                          // 通话时长（居中）
                          const Spacer(),
                          Text(
                            sessionStatusText,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // 加号按钮（邀请更多人加入）
                          GestureDetector(
                            onTap: () => _showMoreMenu(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // 中间区域：语音通话显示头像 + 昵称
                    if (!showVideoView)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 圆角矩形头像 120x120（微信风格）
                          AppAvatar(
                            name: title,
                            avatarUrl: remoteAvatarUrl,
                            seed: remoteUserId,
                            size: 120,
                            borderRadius: 12,
                            fontSize: 40,
                            textColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          // 昵称
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // 底部控制区域 - 3按钮横排（微信风格）
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          // 3按钮横排：麦克风 + 挂断 + 扬声器
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 麦克风按钮
                              _WeChatCallControlButton(
                                icon: mediaState.microphoneEnabled
                                    ? Icons.mic_rounded
                                    : Icons.mic_off_rounded,
                                label: mediaState.microphoneEnabled
                                    ? '麦克风已开'
                                    : '麦克风已关',
                                isActive: mediaState.microphoneEnabled,
                                onTap: canToggleControls
                                    ? () => ref
                                        .read(callControllerProvider.notifier)
                                        .toggleMute()
                                    : null,
                              ),
                              const SizedBox(width: 40),
                              // 挂断按钮（红色，居中）
                              _WeChatCallControlButton(
                                icon: Icons.call_end_rounded,
                                label: '挂断',
                                isActive: true,
                                isHangup: true,
                                onTap: canHangup
                                    ? () => ref
                                        .read(callControllerProvider.notifier)
                                        .hangup()
                                    : null,
                              ),
                              const SizedBox(width: 40),
                              // 扬声器按钮
                              _WeChatCallControlButton(
                                icon: mediaState.speakerEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_down_rounded,
                                label: mediaState.speakerEnabled
                                    ? '扬声器已开'
                                    : '扬声器已关',
                                isActive: mediaState.speakerEnabled,
                                onTap: canToggleControls
                                    ? () => ref
                                        .read(callControllerProvider.notifier)
                                        .toggleSpeaker()
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 锁定提示（双击解锁）
            if (_isLocked)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '双击屏幕解锁',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 显示更多菜单（BottomSheet）
  void _showMoreMenu(BuildContext context) {
    final isScreenShareEnabled = ref.read(isScreenShareEnabledProvider);
    final canToggleScreenShare = ref.read(canToggleScreenShareProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  '更多选项',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(color: Color(0xFF333333), height: 1),
              if (canToggleScreenShare)
                _MoreMenuItem(
                  icon: isScreenShareEnabled
                      ? Icons.stop_screen_share_rounded
                      : Icons.screen_share_rounded,
                  label: isScreenShareEnabled ? '停止共享' : '屏幕共享',
                  onTap: () {
                    if (context.mounted) Navigator.pop(context);
                    ref
                        .read(callControllerProvider.notifier)
                        .toggleScreenShare();
                  },
                ),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// 微信风格通话控制按钮
///
/// 圆形按钮：56x56（挂断按钮 60x60）
/// 背景色：白色（激活）/ 深灰色 #555555（未激活）/ 红色 #E54D4F（挂断）
/// 图标：28px
/// 文字：12px，白色，显示状态（麦克风已开/扬声器已关等）
class _WeChatCallControlButton extends StatelessWidget {
  const _WeChatCallControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isHangup = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isHangup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 根据状态确定颜色
    final Color bgColor;
    final Color iconColor;
    final double buttonSize;

    if (isHangup) {
      // 挂断按钮：红色
      bgColor = const Color(0xFFE54D4F);
      iconColor = Colors.white;
      buttonSize = 60;
    } else if (isActive) {
      // 激活状态：白色背景，黑色图标
      bgColor = Colors.white;
      iconColor = Colors.black;
      buttonSize = 56;
    } else {
      // 未激活状态：深灰色背景，白色图标
      bgColor = const Color(0xFF555555);
      iconColor = Colors.white;
      buttonSize = 56;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// 更多菜单项
class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
