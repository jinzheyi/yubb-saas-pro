import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';

/// 会话列表骨架屏组件
///
/// 模拟会话列表项布局（头像 + 标题 + 预览文字 + 时间戳），
/// 使用 AnimationController + Opacity 实现颜色闪烁效果。
class ConversationSkeleton extends StatefulWidget {
  /// 骨架屏条数
  const ConversationSkeleton({super.key, this.count = 8});

  final int count;

  @override
  State<ConversationSkeleton> createState() => _ConversationSkeletonState();
}

class _ConversationSkeletonState extends State<ConversationSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          itemCount: widget.count,
          itemBuilder: (context, index) {
            return _ConversationSkeletonItem(
              opacity: _animation.value,
              showDivider: index < widget.count - 1,
            );
          },
        );
      },
    );
  }
}

/// 单个会话骨架项
class _ConversationSkeletonItem extends StatelessWidget {
  const _ConversationSkeletonItem({
    required this.opacity,
    this.showDivider = true,
  });

  final double opacity;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = _shimmerColor(context);

    return Opacity(
      opacity: opacity,
      child: Container(
        color: isDark ? const Color(0xFF121620) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 头像占位
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                // 标题 + 预览文字区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行：标题 + 时间戳
                      Row(
                        children: [
                          // 标题占位
                          Container(
                            width: _randomTitleWidth(),
                            height: 16,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const Spacer(),
                          // 时间戳占位
                          Container(
                            width: 32,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A3140)
                                  : const Color(0xFFE8EAED),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 预览文字占位
                      Container(
                        width: _randomPreviewWidth(),
                        height: 13,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A3140)
                              : const Color(0xFFE8EAED),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 分割线
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Divider(
                  height: 1,
                  color: ThemeColors.divider(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 骨架闪烁颜色
  Color _shimmerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A3140) : const Color(0xFFD3DAE6);
  }

  // 预设的标题宽度，模拟不同长度的标题
  double _randomTitleWidth() {
    const widths = [120.0, 90.0, 150.0, 110.0, 130.0, 80.0];
    return widths[hashCode.abs() % widths.length];
  }

  // 预设的预览文字宽度，模拟不同长度的预览
  double _randomPreviewWidth() {
    const widths = [180.0, 150.0, 200.0, 160.0, 140.0, 220.0];
    return widths[hashCode.abs() % widths.length];
  }
}
