import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 来电横幅通知 Widget - 微信风格
///
/// 显示在会话列表顶部，当有来电时显示
/// 包含：头像、昵称、通话类型、接听/拒绝按钮
class CallIncomingBanner extends ConsumerWidget {
  const CallIncomingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    
    // 只在来电响铃时显示
    if (callState.pageStatus != CallPageStatus.ringing || !callState.isIncoming) {
      return const SizedBox.shrink();
    }

    final callerName = callState.callerProfile?.displayName ?? '未知来电';
    final callerAvatar = callState.callerProfile?.avatarUrl;
    final callerUserId = callState.callerProfile?.userId ?? '';
    final callType = callState.callType;
    final isVideoCall = callType == CallType.video;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 头像 48x48
          AppAvatar(
            name: callerName,
            avatarUrl: callerAvatar,
            seed: callerUserId,
            size: 48,
            borderRadius: 8,
            fontSize: 18,
          ),
          const SizedBox(width: 12),
          
          // 昵称 + 通话类型
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  callerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isVideoCall ? '邀请你视频通话..' : '邀请你语音通话..',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 拒绝按钮
          _BannerIconButton(
            icon: Icons.call_end_rounded,
            color: const Color(0xFFE54D4F),
            onTap: () async {
              await ref.read(callControllerProvider.notifier).reject();
            },
          ),
          
          const SizedBox(width: 8),
          
          // 接听按钮
          _BannerIconButton(
            icon: isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
            color: const Color(0xFF07C160),
            onTap: () async {
              await ref.read(callControllerProvider.notifier).accept();
              // 接听后会自动跳转到通话页面，无需手动导航
            },
          ),
        ],
      ),
    );
  }
}

/// 横幅图标按钮
class _BannerIconButton extends StatelessWidget {
  const _BannerIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
