import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_floating_window.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 群通话等待页 - 微信风格
///
/// 用于群聊发起通话后，等待被邀请人接听的界面
/// 显示所有被邀请人的头像网格 + loading动画 + "等待对方接受邀请..."
class GroupOutgoingCallPage extends ConsumerStatefulWidget {
  const GroupOutgoingCallPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<GroupOutgoingCallPage> createState() => _GroupOutgoingCallPageState();
}

class _GroupOutgoingCallPageState extends ConsumerState<GroupOutgoingCallPage> {
  List<_InviteeInfo> _invitees = [];
  bool _isLoading = true;
  AudioPlayer? _ringtonePlayer;

  @override
  void initState() {
    super.initState();
    _loadInviteeInfo();
    Future.microtask(() async {
      final controller = ref.read(callControllerProvider.notifier);
      await controller.initialize(widget.args);
      // 从悬浮窗恢复时，跳过 startOutgoing()，避免重新初始化媒体和音频状态
      if (widget.args.entryMode != CallEntryMode.restore) {
        await controller.startOutgoing();
      }
    });
    // 群聊通话播放铃声
    if (widget.args.entryMode != CallEntryMode.restore) {
      _startRingtone();
    }
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
      debugPrint('[GroupOutgoingCallPage] 铃声播放成功');
    } catch (e) {
      debugPrint('[GroupOutgoingCallPage] 播放铃声失败: $e');
    }
  }

  void _stopRingtone() {
    _ringtonePlayer?.stop();
    _ringtonePlayer?.dispose();
    _ringtonePlayer = null;
  }

  /// 加载被邀请人信息
  Future<void> _loadInviteeInfo() async {
    try {
      final groupId = widget.args.groupId;
      if (groupId == null || groupId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 获取群成员列表
      final membersAsync = ref.read(groupMembersFutureProvider(groupId));
      final members = membersAsync.valueOrNull ?? [];

      // 筛选出被邀请的成员
      final inviteeIds = widget.args.inviteeIds.toSet();
      final invitees = members
          .where((m) => inviteeIds.contains(m.userId))
          .map((m) => _InviteeInfo(
                userId: m.userId,
                nickname: m.nickname,
                avatarUrl: m.avatarUrl,
              ))
          .toList();

      setState(() {
        _invitees = invitees;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[GroupOutgoingCallPage] 加载被邀请人信息失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 生成被邀请人姓名列表文本
  String _buildInviteeNamesText() {
    if (_invitees.isEmpty) {
      return '等待对方接受邀请...';
    }

    final names = _invitees.map((e) => e.nickname).toList();
    if (names.length <= 3) {
      return names.join('、');
    } else {
      return '${names.take(3).join('、')} 等';
    }
  }

  @override
  void dispose() {
    _stopRingtone();
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
          await controller.cancel();
        },
      ),
      callArgs: callArgs,
      routeName: RouteNames.groupOutgoingCall,
      onRestore: () {
        // 点击悬浮窗恢复到通话界面
        manager.hide();
        // 使用 GoRouter 实例直接导航，避免依赖已销毁的页面 context
        router.pushNamed(
          RouteNames.groupOutgoingCall,
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

      // 通话状态变化监听
      if (next.pageStatus == CallPageStatus.connected) {
        // 有人接听后，跳转到群通话中页面
        if (context.mounted) {
          context.pushReplacementNamed(
            RouteNames.groupCallSession,
            extra: widget.args,
          );
        }
      } else if (next.pageStatus == CallPageStatus.ended ||
          next.pageStatus == CallPageStatus.failed) {
        // 通话结束，返回上一页
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    final state = ref.watch(activeCallStateProvider);
    final mediaState = state.mediaState;
    final controller = ref.read(callControllerProvider.notifier);
    final isVideoCall = widget.args.callType == CallType.video;
    final callTypeText = isVideoCall ? '视频' : '语音';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景层
          if (isVideoCall && mediaState.localVideoRenderer != null && mediaState.cameraEnabled)
            // 视频通话：摄像头预览全屏
            Positioned.fill(
              child: RTCVideoView(
                mediaState.localVideoRenderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: true,
              ),
            )
          else
            // 语音通话或摄像头关闭：深色背景
            Positioned.fill(
              child: Container(
                color: const Color(0xFF3A3A3A),
              ),
            ),

          // 主内容区域
          SafeArea(
            child: Column(
              children: [
                // 顶部最小化按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: _minimizeToFloatingWindow,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
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

                const Spacer(flex: 2),

                // 被邀请人头像网格
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF07C160),
                    ),
                  )
                else
                  _buildInviteeAvatarsGrid(),

                const SizedBox(height: 24),

                // 被邀请人姓名列表
                Text(
                  _buildInviteeNamesText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // 状态文字
                Text(
                  '等待对方接受$callTypeText邀请...',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),

                const Spacer(flex: 3),

                // 底部控制按钮
                _buildControlBar(
                  mediaState: mediaState,
                  isVideoCall: isVideoCall,
                  controller: controller,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 被邀请人头像网格
  Widget _buildInviteeAvatarsGrid() {
    if (_invitees.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: _invitees.map((invitee) {
          return _buildInviteeAvatarItem(invitee);
        }).toList(),
      ),
    );
  }

  /// 单个被邀请人头像项
  Widget _buildInviteeAvatarItem(_InviteeInfo invitee) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头像 + loading
        Stack(
          alignment: Alignment.center,
          children: [
            // 头像（不传 backgroundColor，让 AppAvatar 根据 seed 自动生成不同颜色）
            AppAvatar(
              name: invitee.nickname,
              avatarUrl: invitee.avatarUrl,
              seed: invitee.userId,
              size: 64,
              borderRadius: 8,
              fontSize: 24,
            ),
            // Loading动画
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07C160)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 昵称
        Text(
          invitee.nickname,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 底部控制栏
  Widget _buildControlBar({
    required dynamic mediaState,
    required bool isVideoCall,
    required CallController controller,
  }) {
    if (isVideoCall) {
      // 视频通话：两排按钮
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一排：麦克风、扬声器、摄像头
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
          // 第二排：取消按钮
          _WeChatCallButton(
            icon: Icons.call_end_rounded,
            label: '取消',
            backgroundColor: const Color(0xFFE54D4F),
            iconColor: Colors.white,
            labelColor: Colors.white,
            size: 65,
            onTap: () async {
              await controller.cancel();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    } else {
      // 语音通话：一排3个按钮
      return Row(
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
            onTap: () async {
              await controller.cancel();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
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
      );
    }
  }
}

/// 被邀请人信息
class _InviteeInfo {
  final String userId;
  final String nickname;
  final String? avatarUrl;

  _InviteeInfo({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
  });
}

/// 微信风格通话按钮
class _WeChatCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback? onTap;
  final double size;

  const _WeChatCallButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.labelColor,
    this.onTap,
    this.size = 60,
  });

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
