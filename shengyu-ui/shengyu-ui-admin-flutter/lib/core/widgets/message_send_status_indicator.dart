import 'package:flutter/material.dart';

/// 消息发送状态
enum MessageSendStatus {
  sending,    // 发送中
  sent,       // 已发送
  delivered,  // 已送达
  read,       // 已读
  failed,     // 失败
}

/// 消息发送状态指示器
class MessageSendStatusIndicator extends StatelessWidget {
  final MessageSendStatus status;
  final VoidCallback? onRetry;

  const MessageSendStatusIndicator({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageSendStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case MessageSendStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.error_outline, color: Colors.red, size: 16),
        );
      case MessageSendStatus.sent:
      case MessageSendStatus.delivered:
      case MessageSendStatus.read:
        return const SizedBox.shrink();
    }
  }
}
