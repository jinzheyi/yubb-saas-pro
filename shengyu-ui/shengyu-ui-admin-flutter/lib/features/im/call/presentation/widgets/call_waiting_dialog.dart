import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 群组通话等待对话框
///
/// 在群组通话发起后、被叫方接听前展示，显示：
/// - 被邀请人列表及接听状态
/// - 等待接听动画
/// - 取消通话按钮
class CallWaitingDialog extends StatelessWidget {
  const CallWaitingDialog({
    super.key,
    required this.title,
    required this.invitees,
    required this.onCancel,
    this.callType = '语音',
  });

  /// 通话标题（群组名称）
  final String title;

  /// 被邀请人列表
  final List<CallParticipantProfile> invitees;

  /// 取消回调
  final VoidCallback onCancel;

  /// 通话类型描述（语音/视频）
  final String callType;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A2334),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 通话图标 + 类型
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF246BFD).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  callType == '视频' ? Icons.videocam_rounded : Icons.phone_rounded,
                  color: const Color(0xFF246BFD),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              // 标题
              Text(
                '正在发起$callType通话',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB8C0CC),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // 被邀请人列表
              if (invitees.isNotEmpty) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: invitees.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final invitee = invitees[index];
                      return _InviteeTile(invitee: invitee);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 等待动画提示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 8),
                  Text(
                    '等待对方接听...',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A94A6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 取消按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onCancel,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE6E6),
                    foregroundColor: const Color(0xFFE54D4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '取消通话',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 被邀请人条目
class _InviteeTile extends StatelessWidget {
  const _InviteeTile({required this.invitee});

  final CallParticipantProfile invitee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B364B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppAvatar(
            name: invitee.displayName,
            avatarUrl: invitee.avatarUrl,
            seed: invitee.userId,
            size: 36,
            borderRadius: 12,
            fontSize: 14,
            textColor: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              invitee.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 等待状态图标
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF246BFD),
            ),
          ),
        ],
      ),
    );
  }
}

/// 脉冲动画圆点（等待状态指示器）
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + _controller.value * 0.7,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF246BFD),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
