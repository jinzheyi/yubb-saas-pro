import 'package:flutter/material.dart';

/// 红点组件（无数字，表示有待查看内容）
///
/// 使用场景：
/// - 通讯录"我的群组"有待处理的入群申请
/// - 设置"关于圣钰IM"有版本更新
class BadgeDot extends StatelessWidget {
  const BadgeDot({
    super.key,
    this.size = 8,
    this.color = const Color(0xFFF54A45),
    this.borderColor,
    this.borderWidth = 0,
  });

  final double size;
  final Color color;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: borderColor ?? Colors.white, width: borderWidth)
            : null,
      ),
    );
  }
}

/// 数字角标组件（显示具体数量，>99 显示 99+）
///
/// 使用场景：
/// - Tab 栏消息未读数
/// - 通讯录 Tab 群申请数
/// - 列表项具体数量
class BadgeCount extends StatelessWidget {
  const BadgeCount({
    super.key,
    required this.count,
    this.minWidth = 16,
    this.height = 16,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
    this.maxDisplay = 99,
    this.color = const Color(0xFFF54A45),
    this.textColor = Colors.white,
  });

  final int count;
  final double minWidth;
  final double height;
  final double fontSize;
  final EdgeInsets padding;
  final int maxDisplay;
  final Color color;
  final Color textColor;

  String get _displayText {
    if (count > maxDisplay) return '$maxDisplay+';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _displayText,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 角标容器：在子组件的右上角叠加红点或数字角标
///
/// 使用方式：
/// ```dart
/// BadgeOverlay(
///   dot: true,        // 或 count: 5
///   child: Icon(...),
/// )
/// ```
class BadgeOverlay extends StatelessWidget {
  const BadgeOverlay({
    super.key,
    required this.child,
    this.dot = false,
    this.count = 0,
    this.dotSize = 8,
    this.topOffset = -2,
    this.rightOffset = -2,
  }) : assert(!(dot && count > 0), 'dot 和 count 不能同时使用');

  final Widget child;
  final bool dot;
  final int count;
  final double dotSize;
  final double topOffset;
  final double rightOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (dot)
          Positioned(
            top: topOffset,
            right: rightOffset,
            child: BadgeDot(size: dotSize),
          )
        else if (count > 0)
          Positioned(
            top: topOffset,
            right: rightOffset,
            child: BadgeCount(count: count),
          ),
      ],
    );
  }
}

/// 列表项右侧角标组件：用于 ListTile trailing 区域
///
/// 使用方式：
/// ```dart
/// ListTile(
///   trailing: ListItemBadge(dot: true),
///   // 或
///   trailing: ListItemBadge(count: 5),
/// )
/// ```
class ListItemBadge extends StatelessWidget {
  const ListItemBadge({
    super.key,
    this.dot = false,
    this.count = 0,
    this.dotSize = 8,
  }) : assert(!(dot && count > 0), 'dot 和 count 不能同时使用');

  final bool dot;
  final int count;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    if (!dot && count <= 0) return const SizedBox.shrink();
    return dot
        ? BadgeDot(size: dotSize)
        : BadgeCount(count: count);
  }
}
