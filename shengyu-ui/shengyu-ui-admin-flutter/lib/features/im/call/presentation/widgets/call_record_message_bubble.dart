import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record_message.dart';

/// 通话记录消息气泡组件
///
/// 在聊天窗口中以气泡形式展示 1v1 通话记录（参考微信）：
/// - 已接通：显示通话时长，如 "通话时长 00:06 "
/// - 未接听/已拒绝/已取消：显示状态，如 "已取消 📞"
/// - 忙线：显示 "对方忙线中"
///
/// 样式区分：
/// - 发出的消息（isOutgoing=true）：蓝色气泡，右对齐
/// - 收到的消息（isOutgoing=false）：白色气泡，左对齐
///
/// 注意：群聊通话记录不走此组件，由 ChatTimeline 中的
/// _CallRecordCenteredMessage 居中渲染
class CallRecordMessageBubble extends StatelessWidget {
  final CallRecordMessage message;
  final bool isOutgoing;
  final VoidCallback? onTap;

  const CallRecordMessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 使用与普通文本消息一致的颜色
    final bubbleColor = isOutgoing
        ? const Color(0xFFD2E3FC) // 发送方蓝色气泡
        : ThemeColors.chatBubbleIncoming(context); // 接收方自适应颜色
    
    final textColor = isOutgoing
        ? const Color(0xFF1F2329) // 发送方深色文字
        : ThemeColors.chatBubbleIncomingText(context); // 接收方自适应文字颜色

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 276),
        decoration: BoxDecoration(
          color: bubbleColor,
          // 接收方添加边框和阴影，与普通消息一致
          border: isOutgoing ? null : Border.all(color: ThemeColors.divider(context)),
          boxShadow: isOutgoing ? null : const [
            BoxShadow(
              color: Color(0x0A162033),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          // 使用与普通消息一致的圆角
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isOutgoing ? 12 : 5),
            bottomRight: Radius.circular(isOutgoing ? 5 : 12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _callIcon,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _buildDisplayText(),
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展示文本（微信风格）
  String _buildDisplayText() {
    final callTypeText = message.callType == CallType.video ? '视频' : '语音';
    final callerName = message.callerName ?? '对方';

    // 群通话特殊处理（理论上群聊不走此组件，但保留兜底）
    if (message.isGroupCall) {
      return _buildGroupCallText(callerName, callTypeText);
    }

    // 1v1 通话
    return _buildOneToOneCallText(callerName, callTypeText);
  }

  /// 构建1v1通话展示文本
  String _buildOneToOneCallText(String callerName, String callTypeText) {
    switch (message.status) {
      case CallStatus.completed:
        // 已接通：显示通话时长
        final duration = _formatDuration(message.duration);
        return '$callTypeText通话时长 $duration';
      case CallStatus.missed:
        // 未接听
        return isOutgoing ? '未接听' : '$callerName发起了$callTypeText通话';
      case CallStatus.rejected:
        // 已拒绝
        return isOutgoing ? '$callTypeText通话已取消' : '$callerName发起了$callTypeText通话';
      case CallStatus.busy:
        // 忙线
        return '对方忙线中';
      case CallStatus.cancelled:
        // 已取消
        return '$callTypeText通话已取消';
    }
  }

  /// 构建群通话展示文本（兜底逻辑）
  String _buildGroupCallText(String callerName, String callTypeText) {
    switch (message.status) {
      case CallStatus.completed:
        final duration = _formatDuration(message.duration);
        return '$callTypeText通话时长 $duration';
      case CallStatus.missed:
      case CallStatus.rejected:
      case CallStatus.cancelled:
        if (message.inviteeNames.isNotEmpty) {
          final inviteeList = message.inviteeNames.map((name) => '"$name"').join('、');
          return '"$callerName"邀请你和$inviteeList加入了群聊';
        }
        return '"$callerName"发起了$callTypeText通话';
      case CallStatus.busy:
        return '对方忙线中';
    }
  }

  /// 通话图标
  IconData get _callIcon {
    return message.callType == CallType.video
        ? Icons.videocam_outlined
        : Icons.call_outlined;
  }

  /// 格式化通话时长
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '00:${secs.toString().padLeft(2, '0')}';
    }
  }
}
