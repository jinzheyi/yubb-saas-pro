import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';

/// WebSocket 连接状态提示条
///
/// 根据当前 WebSocket 连接状态展示不同的 UI 提示：
/// - connected: 不显示
/// - connecting: 正在连接服务器...
/// - reconnectWaiting: 正在重连服务器 (X/10)...
/// - disconnected: 连接已断开，点击重试
class ConnectionStatusNoticeBar extends ConsumerWidget {
  const ConnectionStatusNoticeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketStateAsync = ref.watch(socketConnectionStateProvider);
    final reconnectAttemptsAsync = ref.watch(socketReconnectAttemptsProvider);
    final maxReconnectAttempts = ref.watch(socketMaxReconnectAttemptsProvider);

    return socketStateAsync.when(
      data: (socketState) {
        final reconnectAttempts = reconnectAttemptsAsync.value ?? 0;
        return _buildByState(
          context,
          ref,
          socketState,
          reconnectAttempts,
          maxReconnectAttempts,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildByState(
    BuildContext context,
    WidgetRef ref,
    ImSocketConnectionState state,
    int reconnectAttempts,
    int maxReconnectAttempts,
  ) {
    switch (state) {
      case ImSocketConnectionState.connected:
        return const SizedBox.shrink();

      case ImSocketConnectionState.connecting:
        return _buildNoticeBar(
          color: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          icon: Icons.cloud_upload_outlined,
          message: '正在连接服务器...',
          isLoading: true,
        );

      case ImSocketConnectionState.reconnectWaiting:
        return _buildNoticeBar(
          color: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          icon: Icons.sync,
          message: '正在重连服务器 ($reconnectAttempts/$maxReconnectAttempts)...',
          isLoading: true,
        );

      case ImSocketConnectionState.disconnected:
        return GestureDetector(
          onTap: () => ref.read(imSocketClientProvider).reconnect(),
          child: _buildNoticeBar(
            color: const Color(0xFFFFEBEE),
            textColor: const Color(0xFFC62828),
            icon: Icons.cloud_off,
            message: '连接已断开，点击重试',
            showRetryButton: true,
          ),
        );

      // 其他中间状态（authenticating, probing, reauthenticating, invalidated）不显示提示条
      case ImSocketConnectionState.probing:
      case ImSocketConnectionState.authenticating:
      case ImSocketConnectionState.reauthenticating:
      case ImSocketConnectionState.invalidated:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNoticeBar({
    required Color color,
    required Color textColor,
    required IconData icon,
    required String message,
    bool isLoading = false,
    bool showRetryButton = false,
  }) {
    return Container(
      height: 32,
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          else
            Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
          if (showRetryButton) ...[
            const SizedBox(width: 8),
            Text(
              '重试',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
