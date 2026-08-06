import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/permission_denied_dialog.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 来电界面 - 1:1 复刻微信设计
///
/// 微信来电界面特征：
/// - 纯色深色背景（#3A3A3A）+ 圆角矩形头像 + 昵称 + 状态文字
/// - 底部两个大圆形按钮：拒绝（左）+ 接听（右），70x70
/// - 状态文字："邀请你语音通话.." / "邀请你视频通话.."
/// - 群通话：显示"邀请你多人通话..." + 参与者头像
class IncomingCallPage extends ConsumerStatefulWidget {
  const IncomingCallPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage>
    with TickerProviderStateMixin {
  AudioPlayer? _ringtonePlayer;

  /// 铃声脉冲动画控制器（微信风格：头像周围脉冲波纹 + 呼吸缩放）
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _breathController;
  late Animation<double> _pulseAnimation1;
  late Animation<double> _pulseAnimation2;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化脉冲波纹动画1
    _pulseController1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation1 = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController1, curve: Curves.easeOut),
    );
    _pulseController1.repeat();

    // 初始化脉冲波纹动画2（延迟1秒开始，形成交错效果）
    _pulseController2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation2 = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _pulseController2.repeat();
    });

    // 初始化呼吸缩放动画
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathController.repeat(reverse: true);

    Future.microtask(
      () => ref.read(callControllerProvider.notifier).initialize(widget.args),
    );
    // 播放来电铃声（单聊和群聊都播放）
    _startRingtone();
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
      debugPrint('[IncomingCallPage] 铃声播放成功');
    } catch (e) {
      debugPrint('[IncomingCallPage] 播放铃声失败: $e');
    }
  }

  void _stopRingtone() {
    _ringtonePlayer?.stop();
    _ringtonePlayer?.dispose();
    _ringtonePlayer = null;
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    _breathController.dispose();
    _stopRingtone();
    super.dispose();
  }

  /// 构建群聊来电参与者头像网格
  Widget _buildGroupCallAvatars(List<CallParticipantProfile> participants) {
    // 最多显示4个头像（微信风格）
    final displayParticipants = participants.take(4).toList();
    final size = participants.length == 1 ? 120.0 : 80.0;
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: displayParticipants.map((participant) {
        return AppAvatar(
          name: participant.displayName,
          avatarUrl: participant.avatarUrl,
          seed: participant.userId,
          size: size,
          borderRadius: 12,
          fontSize: size > 100 ? 40 : 28,
          textColor: Colors.white,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      if (previous?.pageStatus == next.pageStatus) {
        return;
      }
      
      // 通话结束时彻底清理悬浮窗状态（防御性调用，Controller 已先执行 forceCleanup）
      if (next.pageStatus == CallPageStatus.ended ||
          next.pageStatus == CallPageStatus.failed) {
        ref.read(callFloatingWindowManagerProvider).forceCleanup();
      }
      
      // 处理权限拒绝
      if (next.pageStatus == CallPageStatus.failed && 
          next.error?.message.contains('权限') == true &&
          context.mounted) {
        final isPermanentlyDenied = next.error?.message.contains('永久') == true;
        final permissionType = next.error?.message.contains('麦克风') == true ? '麦克风' : '摄像头';
        
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
    final statusText = ref.watch(incomingCallStatusTextProvider);
    final canReject = ref.watch(canRejectIncomingCallProvider);
    final canAccept = ref.watch(canAcceptIncomingCallProvider);
    final title = state.title ?? widget.args.title ?? '语音通话';
    final avatarUrl = state.callerProfile?.avatarUrl;
    final callerUserId = state.callerProfile?.userId ?? '';
    final isVideoCall = widget.args.callType == CallType.video;
    final isGroupCall = widget.args.isGroupCall;

    // 群聊来电状态文本
    final groupCallStatusText = isGroupCall
        ? '${state.callerProfile?.displayName ?? '发起人'}邀请你多人通话...'
        : statusText;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景层 - 纯色深色（微信风格）
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
                    // 群聊来电：显示多个参与者头像网格
                    if (isGroupCall && state.participants.isNotEmpty)
                      _buildGroupCallAvatars(state.participants)
                    else
                      // 单聊来电：显示单个头像 + 脉冲波纹动画
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 脉冲波纹 1
                          AnimatedBuilder(
                            animation: _pulseAnimation1,
                            builder: (context, child) {
                              return Opacity(
                                opacity: (1.0 - _pulseController1.value).clamp(0.0, 0.6),
                                child: Container(
                                  width: 120 * _pulseAnimation1.value,
                                  height: 120 * _pulseAnimation1.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF07C160),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // 脉冲波纹 2
                          AnimatedBuilder(
                            animation: _pulseAnimation2,
                            builder: (context, child) {
                              return Opacity(
                                opacity: (1.0 - _pulseController2.value).clamp(0.0, 0.6),
                                child: Container(
                                  width: 120 * _pulseAnimation2.value,
                                  height: 120 * _pulseAnimation2.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF07C160),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // 头像（呼吸缩放）
                          AnimatedBuilder(
                            animation: _breathAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _breathAnimation.value,
                                child: child,
                              );
                            },
                            child: AppAvatar(
                              name: title,
                              avatarUrl: avatarUrl,
                              seed: callerUserId,
                              size: 120,
                              borderRadius: 12,
                              fontSize: 40,
                              textColor: Colors.white,
                            ),
                          ),
                        ],
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
                      isGroupCall ? groupCallStatusText : statusText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),

                // 中间留白
                const Spacer(flex: 3),

                // 底部按钮区域 - 左右布局（微信风格）
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 拒绝按钮 - 红色圆形（左下角）
                      _WeChatCallButton(
                        icon: Icons.call_end_rounded,
                        label: '拒绝',
                        backgroundColor: const Color(0xFFE54D4F),
                        iconColor: Colors.white,
                        labelColor: Colors.white,
                        size: 70,
                        onTap: canReject
                            ? () async {
                                await ref
                                    .read(callControllerProvider.notifier)
                                    .reject();
                                if (context.mounted) context.pop();
                              }
                            : null,
                      ),
                      // 接听按钮 - 绿色圆形（右下角）
                      _WeChatCallButton(
                        icon: isVideoCall
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        label: isVideoCall ? '视频接听' : '接听',
                        backgroundColor: const Color(0xFF07C160),
                        iconColor: Colors.white,
                        labelColor: Colors.white,
                        size: 70,
                        onTap: canAccept
                            ? () async {
                                await ref
                                    .read(callControllerProvider.notifier)
                                    .accept();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
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
