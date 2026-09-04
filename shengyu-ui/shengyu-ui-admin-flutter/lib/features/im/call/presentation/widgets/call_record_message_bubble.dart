import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record_message.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_record_display_text.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

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

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 276),
      decoration: BoxDecoration(
        color: bubbleColor,
        // 接收方添加边框和阴影，与普通消息一致
        border: isOutgoing
            ? null
            : Border.all(color: ThemeColors.divider(context)),
        boxShadow: isOutgoing
            ? null
            : const [
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
          Icon(_callIcon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _buildDisplayText(context),
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return bubble;
    return GestureDetector(onTap: onTap, child: bubble);
  }

  /// 构建展示文本（微信风格）
  String _buildDisplayText(BuildContext context) {
    return callRecordDisplayText(
      strings: AppLocalizations.of(context),
      callType: message.callType,
      status: message.status,
      durationSeconds: message.duration,
      isGroupCall: message.isGroupCall,
      isOutgoing: isOutgoing,
      callerName: message.callerName,
    );
  }

  /// 通话图标
  IconData get _callIcon {
    return message.callType == CallType.video
        ? Icons.videocam_outlined
        : Icons.call_outlined;
  }
}
