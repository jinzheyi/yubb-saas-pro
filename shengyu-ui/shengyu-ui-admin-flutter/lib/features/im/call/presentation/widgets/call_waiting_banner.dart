import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 通话等待横幅 - 微信风格
///
/// 显示在通话中页面顶部，当有来电等待时显示
/// 包含：头像、昵称、通话类型、保持/切换按钮
///
/// 参考微信通话等待：
/// - 当用户正在通话中收到新来电时显示
/// - 用户可选择"保持"（拒绝新来电）或"切换"（挂断当前，接听新来电）
class CallWaitingBanner extends ConsumerWidget {
  const CallWaitingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final pendingCall = callState.pendingIncomingCall;

    // 没有待处理来电时不显示
    if (pendingCall == null) {
      return const SizedBox.shrink();
    }

    final callerName = pendingCall.callerProfile.displayName.isNotEmpty
        ? pendingCall.callerProfile.displayName
        : '未知来电';
    final callerAvatar = pendingCall.callerProfile.avatarUrl;
    final callerUserId = pendingCall.callerProfile.userId;
    final isVideoCall = pendingCall.callType == CallType.video;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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

          // 保持按钮（拒绝新来电，保持当前通话）
          _BannerTextButton(
            label: '保持',
            color: const Color(0xFF999999),
            onTap: () async {
              await ref.read(callControllerProvider.notifier).rejectPendingCall();
            },
          ),

          const SizedBox(width: 8),

          // 切换按钮（挂断当前通话，接听新来电）
          _BannerTextButton(
            label: '切换',
            color: const Color(0xFF07C160),
            onTap: () async {
              await ref.read(callControllerProvider.notifier).switchToPendingCall();
            },
          ),
        ],
      ),
    );
  }
}

/// 横幅文字按钮
class _BannerTextButton extends StatelessWidget {
  const _BannerTextButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
