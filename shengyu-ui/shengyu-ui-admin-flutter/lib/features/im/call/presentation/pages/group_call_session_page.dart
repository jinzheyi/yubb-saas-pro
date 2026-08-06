import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_floating_window.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_waiting_banner.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/group_call_participant_grid.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 群组通话会话页面 - 1:1 复刻微信设计
///
/// 布局结构（从上到下）：
/// - 顶部信息栏：群名称 | 参与人数 | 通话时长
/// - 参与者网格（矩阵式布局）
/// - 底部控制栏：圆形按钮（静音/扬声器/摄像头/更多）+ 红色圆形挂断
class GroupCallSessionPage extends ConsumerStatefulWidget {
  const GroupCallSessionPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<GroupCallSessionPage> createState() =>
      _GroupCallSessionPageState();
}

class _GroupCallSessionPageState extends ConsumerState<GroupCallSessionPage> {
  /// 横屏模式状态
  bool _isLandscape = false;

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
    // 恢复竖屏模式
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
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
      routeName: RouteNames.groupCallSession,
      onRestore: () {
        // 点击悬浮窗恢复到通话界面
        manager.hide();
        // 使用 GoRouter 实例直接导航，避免依赖已销毁的页面 context
        router.pushNamed(
          RouteNames.groupCallSession,
          extra: callArgs.copyWith(entryMode: CallEntryMode.restore),
        );
      },
    );

    // 关闭当前通话页面
    if (context.mounted) context.pop();
  }

  /// 切换横屏模式
  void _toggleLandscape() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      // 切换到横屏
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // 切换到竖屏
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeCallStateProvider);
    final isVideoEnabled = ref.watch(isCallVideoEnabledProvider);
    final canToggleControls = ref.watch(canToggleCallControlsProvider);
    final canHangup = ref.watch(canHangupCallProvider);
    final isScreenShareEnabled = ref.watch(isScreenShareEnabledProvider);
    final canToggleScreenShare = ref.watch(canToggleScreenShareProvider);
    final sessionStatusText = ref.watch(
      callSessionStatusTextProvider(widget.args),
    );
    final mediaState = state.mediaState;
    final title = state.title ?? widget.args.title ?? '群组通话';
    final participants = state.participants;
    
    // 判断用户角色：邀请人 vs 被邀请人
    // 邀请人：主动发起通话的人
    // 被邀请人：被邀请加入通话的人
    final isInviter = state.isOutgoing && state.isGroupCall;
    final isInvitee = state.isIncoming && state.isGroupCall;

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 通话等待横幅（有新来电时显示）
            const CallWaitingBanner(),

            // 顶部信息栏
            _buildTopBar(title, sessionStatusText, participants.length),

            // 参与者网格视图（矩阵式布局）
            Expanded(
              child: GroupCallParticipantGrid(
                participants: participants,
                localUserId: ref.read(authSessionProvider).userId,
                speakingUserId: state.speakingUserId,
                onInviteTap: () => _showInviteDialog(context),
                isInviter: isInviter,
              ),
            ),

            // 底部控制栏（区分邀请人/被邀请人视图）
            _buildControlBar(
              mediaState: mediaState,
              isVideoEnabled: isVideoEnabled,
              canToggleControls: canToggleControls,
              canHangup: canHangup,
              isScreenShareEnabled: isScreenShareEnabled,
              canToggleScreenShare: canToggleScreenShare,
              isInviter: isInviter,
              isInvitee: isInvitee,
              participantCount: participants.length,
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部信息栏 - 微信风格
  /// 屏幕共享图标（左上）+ 通话时长（居中）+ 加号按钮（右上）
  Widget _buildTopBar(String title, String statusText, int participantCount) {
    final mediaState = ref.watch(activeCallStateProvider).mediaState;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            statusText,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 加号按钮（邀请更多人加入）
          GestureDetector(
            onTap: () => _showInviteDialog(context),
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
    );
  }

  /// 底部控制栏 - 微信风格（区分邀请人/被邀请人视图）
  ///
  /// 邀请人视图（2人通话）：
  /// - 3个按钮：麦克风、扬声器、摄像头
  /// - 挂断按钮独立在下方
  /// - 按钮有文字标签
  ///
  /// 被邀请人视图（2人通话）：
  /// - 圆角卡片内5个按钮：折叠、麦克风、扬声器、摄像头、挂断
  /// - 无文字标签
  ///
  /// 3人以上通话：
  /// - 圆角卡片内5个按钮（同被邀请人视图）
  Widget _buildControlBar({
    required dynamic mediaState,
    required bool isVideoEnabled,
    required bool canToggleControls,
    required bool canHangup,
    required bool isScreenShareEnabled,
    required bool canToggleScreenShare,
    required bool isInviter,
    required bool isInvitee,
    required int participantCount,
  }) {
    // 2人通话且是邀请人：使用邀请人视图
    if (participantCount == 2 && isInviter) {
      return _buildInviterControlBar(
        mediaState: mediaState,
        canToggleControls: canToggleControls,
        canHangup: canHangup,
      );
    }
    
    // 其他情况：使用被邀请人视图（圆角卡片）
    return _buildInviteeControlBar(
      mediaState: mediaState,
      canToggleControls: canToggleControls,
      canHangup: canHangup,
    );
  }
  
  /// 邀请人视图控制栏（2人通话）
  /// 3个按钮：麦克风、扬声器、摄像头 + 独立挂断按钮
  Widget _buildInviterControlBar({
    required dynamic mediaState,
    required bool canToggleControls,
    required bool canHangup,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3个功能按钮横排
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 麦克风按钮
              _WeChatCallControlButton(
                icon: mediaState.microphoneEnabled
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                label: mediaState.microphoneEnabled ? '麦克风已开' : '麦克风已关',
                isActive: mediaState.microphoneEnabled,
                onTap: canToggleControls
                    ? () => ref
                        .read(callControllerProvider.notifier)
                        .toggleMute()
                    : null,
              ),
              // 扬声器按钮
              _WeChatCallControlButton(
                icon: mediaState.speakerEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                label: mediaState.speakerEnabled ? '扬声器已开' : '扬声器已关',
                isActive: mediaState.speakerEnabled,
                onTap: canToggleControls
                    ? () => ref
                        .read(callControllerProvider.notifier)
                        .toggleSpeaker()
                    : null,
              ),
              // 摄像头按钮
              _WeChatCallControlButton(
                icon: mediaState.cameraEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                label: mediaState.cameraEnabled ? '摄像头已开' : '摄像头已关',
                isActive: mediaState.cameraEnabled,
                onTap: canToggleControls
                    ? () => ref
                        .read(callControllerProvider.notifier)
                        .toggleCamera()
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 挂断按钮（独立居中）
          _WeChatCallControlButton(
            icon: Icons.call_end_rounded,
            label: '挂断',
            isActive: true,
            isHangup: true,
            onTap: canHangup
                ? () => ref.read(callControllerProvider.notifier).hangup()
                : null,
          ),
        ],
      ),
    );
  }
  
  /// 被邀请人视图控制栏（2人通话或被邀请人）
  /// 圆角卡片内5个按钮：折叠、麦克风、扬声器、摄像头、挂断
  Widget _buildInviteeControlBar({
    required dynamic mediaState,
    required bool canToggleControls,
    required bool canHangup,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 圆角卡片容器
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 折叠按钮（暂时隐藏，后续实现）
                // _InviteeControlButton(
                //   icon: Icons.keyboard_arrow_up_rounded,
                //   isActive: false,
                //   onTap: () {},
                // ),
                // 麦克风按钮
                _InviteeControlButton(
                  icon: mediaState.microphoneEnabled
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,
                  isActive: mediaState.microphoneEnabled,
                  onTap: canToggleControls
                      ? () => ref
                          .read(callControllerProvider.notifier)
                          .toggleMute()
                      : null,
                ),
                // 扬声器按钮
                _InviteeControlButton(
                  icon: mediaState.speakerEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  isActive: mediaState.speakerEnabled,
                  onTap: canToggleControls
                      ? () => ref
                          .read(callControllerProvider.notifier)
                          .toggleSpeaker()
                      : null,
                ),
                // 摄像头按钮
                _InviteeControlButton(
                  icon: mediaState.cameraEnabled
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  isActive: mediaState.cameraEnabled,
                  onTap: canToggleControls
                      ? () => ref
                          .read(callControllerProvider.notifier)
                          .toggleCamera()
                      : null,
                ),
                // 挂断按钮（红色）
                _InviteeControlButton(
                  icon: Icons.call_end_rounded,
                  isActive: true,
                  isHangup: true,
                  onTap: canHangup
                      ? () => ref.read(callControllerProvider.notifier).hangup()
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示更多菜单（BottomSheet）
  /// 
  /// 注意：此方法当前未被调用，保留供未来功能扩展使用
  /// 如需启用，可在底部控制栏的"更多"按钮中调用
  // ignore: unused_element
  void _showMoreMenu(BuildContext context) {
    final isVideoEnabled = ref.read(isCallVideoEnabledProvider);
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
              if (isVideoEnabled)
                _MoreMenuItem(
                  icon: _isLandscape
                      ? Icons.portrait_rounded
                      : Icons.landscape_rounded,
                  label: _isLandscape ? '竖屏模式' : '横屏模式',
                  onTap: () {
                    Navigator.pop(context);
                    _toggleLandscape();
                  },
                ),
              if (canToggleScreenShare)
                _MoreMenuItem(
                  icon: isScreenShareEnabled
                      ? Icons.stop_screen_share_rounded
                      : Icons.screen_share_rounded,
                  label: isScreenShareEnabled ? '停止共享' : '屏幕共享',
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(callControllerProvider.notifier)
                        .toggleScreenShare();
                  },
                ),
              _MoreMenuItem(
                icon: Icons.person_add_rounded,
                label: '邀请好友加入',
                onTap: () {
                  Navigator.pop(context);
                  _showInviteDialog(context);
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

  /// 显示邀请好友对话框
  void _showInviteDialog(BuildContext context) {
    final groupId = widget.args.groupId ?? '';
    final groupMembersAsync = ref.watch(groupMembersFutureProvider(groupId));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '邀请好友加入',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: groupMembersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF246BFD)),
            ),
            error: (error, stack) => Center(
              child: Text(
                '加载失败: $error',
                style: const TextStyle(color: Color(0xFFE54D4F)),
              ),
            ),
            data: (members) {
              // 过滤掉已经在通话中的成员
              final currentParticipants =
                  ref.read(activeCallStateProvider).participants;
              final participantIds =
                  currentParticipants.map((p) => p.userId).toSet();
              final availableMembers = members
                  .where((m) => !participantIds.contains(m.userId))
                  .toList();

              if (availableMembers.isEmpty) {
                return const Center(
                  child: Text(
                    '所有成员都在通话中',
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                );
              }

              return ListView.builder(
                itemCount: availableMembers.length,
                itemBuilder: (context, index) {
                  final member = availableMembers[index];
                  return _buildInviteItem(context, member);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建邀请选项
  Widget _buildInviteItem(BuildContext context, dynamic member) {
    return ListTile(
      leading: AppAvatar(
        name: member.nickname,
        avatarUrl: member.avatarUrl,
        seed: member.userId,
        size: 40,
        borderRadius: 20,
        fontSize: 16,
        textColor: Colors.white,
      ),
      title: Text(
        member.nickname,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: member.deptName != null
          ? Text(
              member.deptName,
              style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
            )
          : null,
      trailing: const Icon(
        Icons.add_circle_outline,
        color: Color(0xFF246BFD),
      ),
      onTap: () {
        Navigator.of(context).pop();
        // 调用邀请接口
        _inviteMember(member.userId, member.nickname);
      },
    );
  }

  /// 邀请成员加入通话
  Future<void> _inviteMember(String userId, String nickname) async {
    try {
      final state = ref.read(activeCallStateProvider);
      final callSessionId = state.callSessionId;
      final groupId = widget.args.groupId;

      if (callSessionId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通话会话ID无效')),
        );
        return;
      }

      if (groupId == null || groupId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群组ID无效')),
        );
        return;
      }

      // 调用后端邀请接口
      await ref.read(callRepositoryProvider).inviteGroupMembers(
            callSessionId: callSessionId,
            groupId: groupId,
            inviteeIds: [userId],
          );

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已邀请 $nickname 加入通话')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('邀请失败: $e')),
        );
      }
    }
  }
}

/// 微信风格通话控制按钮（邀请人视图）
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

/// 被邀请人视图控制按钮（圆角卡片内）
///
/// 圆形按钮：48x48（挂断按钮 52x52）
/// 背景色：白色（激活）/ 深灰色 #555555（未激活）/ 红色 #E54D4F（挂断）
/// 图标：24px
/// 无文字标签
class _InviteeControlButton extends StatelessWidget {
  const _InviteeControlButton({
    required this.icon,
    required this.isActive,
    this.isHangup = false,
    this.onTap,
  });

  final IconData icon;
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
      buttonSize = 52;
    } else if (isActive) {
      // 激活状态：白色背景，黑色图标
      bgColor = Colors.white;
      iconColor = Colors.black;
      buttonSize = 48;
    } else {
      // 未激活状态：深灰色背景，白色图标
      bgColor = const Color(0xFF555555);
      iconColor = Colors.white;
      buttonSize = 48;
    }

    return GestureDetector(
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
          size: 24,
        ),
      ),
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
