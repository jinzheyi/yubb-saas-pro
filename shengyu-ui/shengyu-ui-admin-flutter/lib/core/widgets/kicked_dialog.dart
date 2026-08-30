import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/session_cleanup_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';

/// 被踢出弹窗组件
///
/// 参考微信样式，展示踢人原因和设备信息，用户确认后自动登出并跳转登录页
class KickedDialog extends ConsumerWidget {
  const KickedDialog({
    super.key,
    required this.message,
    this.byDevice,
    this.kickedAt,
  });

  final String message;
  final String? byDevice;
  final int? kickedAt;

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    // 先关闭不可取消的弹窗，避免网络/存储清理较慢时界面仍停留在“账号异常”。
    // 随后的会话清理和路由替换仍会完成，且不会因当前 dialog 的 context
    // 被销毁而中断。
    Navigator.of(context, rootNavigator: true).pop();

    // 1. 断开 WebSocket 连接
    await ref.read(imSocketClientProvider).disconnect();

    // 2. 清理会话信息
    await ref.read(authSessionProvider.notifier).clearSession();

    // 3. 清理所有缓存
    ref.read(sessionCleanupServiceProvider).forceClearAllUserScopes();

    // 4. 跳转登录页
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeText = _formatTime(kickedAt);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Color(0xFFFF9800),
            ),
            const SizedBox(height: 16),

            // 标题
            const Text(
              '账号异常',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),

            // 提示内容
            Text(
              _buildMessageText(timeText),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // 安全提示
            const Text(
              '如非本人操作，请及时修改密码。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),

            // 确定按钮
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _onConfirm(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1890FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '确定',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildMessageText(String timeText) {
    if (byDevice != null && byDevice!.isNotEmpty) {
      if (timeText.isNotEmpty) {
        return '你的账号于 $timeText 在 $byDevice 上登录，你已被迫下线。';
      }
      return '你的账号在 $byDevice 上登录，你已被迫下线。';
    }
    if (timeText.isNotEmpty) {
      return '你的账号于 $timeText 在其他设备上登录，你已被迫下线。';
    }
    return message.isNotEmpty ? message : '你的账号已被迫下线。';
  }
}
