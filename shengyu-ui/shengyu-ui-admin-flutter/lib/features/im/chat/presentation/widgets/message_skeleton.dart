import 'package:flutter/material.dart';

/// 消息骨架屏组件
///
/// 模拟真实聊天消息布局（头像占位 + 气泡占位），
/// 使用 AnimationController + Opacity 实现颜色闪烁效果。
class MessageSkeleton extends StatefulWidget {
  /// 骨架屏条数
  const MessageSkeleton({super.key, this.count = 6});

  final int count;

  @override
  State<MessageSkeleton> createState() => _MessageSkeletonState();
}

class _MessageSkeletonState extends State<MessageSkeleton>
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListView(
            reverse: true,
            children: List.generate(widget.count, (index) {
              // 最后一条（渲染最底部）为 outgoing，其余交替
              final isOutgoing = index == 0 ? true : (index % 2 == 0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: isOutgoing
                    ? _OutgoingSkeletonItem(opacity: _animation.value)
                    : _IncomingSkeletonItem(opacity: _animation.value),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// 出消息骨架项（右侧）
class _OutgoingSkeletonItem extends StatelessWidget {
  const _OutgoingSkeletonItem({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SkeletonBubble(
                opacity: opacity,
                isOutgoing: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _SkeletonAvatar(opacity: opacity),
      ],
    );
  }
}

/// 入消息骨架项（左侧）
class _IncomingSkeletonItem extends StatelessWidget {
  const _IncomingSkeletonItem({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonAvatar(opacity: opacity),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: _SkeletonBubble(
            opacity: opacity,
            isOutgoing: false,
          ),
        ),
      ],
    );
  }
}

/// 骨架气泡（随机宽度模拟真实消息长度变化）
class _SkeletonBubble extends StatelessWidget {
  const _SkeletonBubble({required this.opacity, required this.isOutgoing});

  final double opacity;
  final bool isOutgoing;

  // 预设的宽度比例，模拟不同消息长度
  static const _widthRatios = [0.45, 0.6, 0.35, 0.55, 0.5, 0.7];

  @override
  Widget build(BuildContext context) {
    final widthRatio = _widthRatios[hashCode.abs() % _widthRatios.length];
    final shimmerColor = _shimmerColor(context, isOutgoing: isOutgoing);

    return Opacity(
      opacity: opacity,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * widthRatio,
          minWidth: 80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: shimmerColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        child: const SizedBox(height: 16, width: double.infinity),
      ),
    );
  }

  /// 骨架闪烁颜色：根据出/入消息使用不同色调
  Color _shimmerColor(BuildContext context, {required bool isOutgoing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isOutgoing) {
      return isDark ? const Color(0xFF2A4A3A) : const Color(0xFFD4EDDA);
    }
    return isDark ? const Color(0xFF2A3140) : const Color(0xFFE8EAED);
  }
}

/// 骨架头像占位
class _SkeletonAvatar extends StatelessWidget {
  const _SkeletonAvatar({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A3140) : const Color(0xFFD3DAE6),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
