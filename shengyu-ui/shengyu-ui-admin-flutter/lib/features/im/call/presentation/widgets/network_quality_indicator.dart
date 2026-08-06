import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';

/// 网络质量指示器组件
/// 
/// 显示当前通话的网络质量状态，包括信号强度和详细信息
class NetworkQualityIndicator extends ConsumerWidget {
  const NetworkQualityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkQuality = ref.watch(networkQualityProvider);
    final roundTripTime = ref.watch(roundTripTimeProvider);
    final packetLossRate = ref.watch(packetLossRateProvider);
    
    // 如果网络质量未知，不显示
    if (networkQuality == NetworkQuality.unknown) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () => _showNetworkDetails(context, networkQuality, roundTripTime, packetLossRate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(networkQuality),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSignalIcon(networkQuality),
            const SizedBox(width: 4),
            Text(
              _getQualityText(networkQuality),
              style: TextStyle(
                fontSize: 11,
                color: _getTextColor(networkQuality),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信号强度图标
  Widget _buildSignalIcon(NetworkQuality quality) {
    final color = _getIconColor(quality);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < _getSignalBars(quality);
        return Container(
          width: 3,
          height: 4 + index * 2,
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  /// 显示网络详情对话框
  void _showNetworkDetails(
    BuildContext context,
    NetworkQuality quality,
    int? rtt,
    double? packetLoss,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2334),
        title: Row(
          children: [
            _buildSignalIcon(quality),
            const SizedBox(width: 8),
            Text(
              '网络质量详情',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('网络状态', _getQualityText(quality), _getIconColor(quality)),
            const SizedBox(height: 12),
            if (rtt != null) ...[
              _buildDetailRow('延迟 (RTT)', '$rtt ms', _getRttColor(rtt)),
              const SizedBox(height: 12),
            ],
            if (packetLoss != null) ...[
              _buildDetailRow('丢包率', '${(packetLoss * 100).toStringAsFixed(1)}%', _getPacketLossColor(packetLoss)),
              const SizedBox(height: 12),
            ],
            const Divider(color: Color(0xFF2B364B)),
            const SizedBox(height: 12),
            const Text(
              '网络质量说明：',
              style: TextStyle(
                color: Color(0xFF8F96A3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildQualityDescription('优秀', '延迟 < 100ms，丢包率 < 1%', const Color(0xFF4CAF50)),
            _buildQualityDescription('良好', '延迟 < 300ms，丢包率 < 5%', const Color(0xFF8BC34A)),
            _buildQualityDescription('一般', '延迟 < 500ms，丢包率 < 10%', const Color(0xFFFFC107)),
            _buildQualityDescription('较差', '延迟 ≥ 500ms 或 丢包率 ≥ 10%', const Color(0xFFFF5722)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '关闭',
              style: TextStyle(color: Color(0xFF246BFD)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8F96A3),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityDescription(String level, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$level：',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      color: Color(0xFF8F96A3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取信号条数（1-4）
  int _getSignalBars(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return 4;
      case NetworkQuality.good:
        return 3;
      case NetworkQuality.fair:
        return 2;
      case NetworkQuality.poor:
        return 1;
      case NetworkQuality.unknown:
        return 0;
    }
  }

  /// 获取质量文本
  String _getQualityText(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return '优秀';
      case NetworkQuality.good:
        return '良好';
      case NetworkQuality.fair:
        return '一般';
      case NetworkQuality.poor:
        return '较差';
      case NetworkQuality.unknown:
        return '未知';
    }
  }

  /// 获取图标颜色
  Color _getIconColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return const Color(0xFF4CAF50);
      case NetworkQuality.good:
        return const Color(0xFF8BC34A);
      case NetworkQuality.fair:
        return const Color(0xFFFFC107);
      case NetworkQuality.poor:
        return const Color(0xFFFF5722);
      case NetworkQuality.unknown:
        return const Color(0xFF8F96A3);
    }
  }

  /// 获取文本颜色
  Color _getTextColor(NetworkQuality quality) {
    return _getIconColor(quality);
  }

  /// 获取背景颜色
  Color _getBackgroundColor(NetworkQuality quality) {
    return _getIconColor(quality).withValues(alpha: 0.15);
  }

  /// 获取 RTT 颜色
  Color _getRttColor(int rtt) {
    if (rtt < 100) return const Color(0xFF4CAF50);
    if (rtt < 300) return const Color(0xFF8BC34A);
    if (rtt < 500) return const Color(0xFFFFC107);
    return const Color(0xFFFF5722);
  }

  /// 获取丢包率颜色
  Color _getPacketLossColor(double packetLoss) {
    if (packetLoss < 0.01) return const Color(0xFF4CAF50);
    if (packetLoss < 0.05) return const Color(0xFF8BC34A);
    if (packetLoss < 0.10) return const Color(0xFFFFC107);
    return const Color(0xFFFF5722);
  }
}
