import 'package:flutter/material.dart';

/// 主题颜色适配工具类
///
/// 通过 static 方法直接从 ThemeData 获取颜色，避免额外 widget 开销。
/// 所有方法均为 O(1) 查找。
abstract class ThemeColors {
  /// Scaffold 背景色
  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// 表面色（卡片、容器背景）
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// 次要表面色（嵌套卡片、子容器背景）
  static Color surfaceDim(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.brightness == Brightness.dark
        ? const Color(0xFF10151F)
        : const Color(0xFFF5F7FB);
  }

  /// 输入框背景色
  static Color inputFill(BuildContext context) {
    final theme = Theme.of(context);
    return theme.inputDecorationTheme.fillColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF2A3140)
            : const Color(0xFFF2F4F8));
  }

  /// 主文本颜色
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// 次要文本颜色（描述、提示）
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// 分割线颜色
  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  /// 搜索栏/标签栏背景色
  static Color searchBarBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A3140)
        : const Color(0xFFF3F4F8);
  }

  /// 选中状态背景色（Tab 选中、高亮区域）
  static Color activeBg(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.primaryContainer;
  }

  /// 内联通知背景色
  static Color noticeBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF1A3A6B)
        : const Color(0xFFEAF2FF);
  }

  /// 通知文本色
  static Color noticeText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF6BA4FF)
        : const Color(0xFF246BFD);
  }

  /// 索引标签颜色
  static Color indexRailText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF8F96A3)
        : const Color(0xFF202531);
  }

  /// Chevron / 箭头图标颜色
  static Color chevronColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF5A6270)
        : const Color(0xFFB8C0CC);
  }

  /// 底部导航栏背景色
  static Color bottomNavBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF1E2430)
        : Colors.white;
  }

  /// 底部导航栏边框色
  static Color bottomNavBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A3140)
        : const Color(0xFFE2E7EF);
  }

  /// 底部导航非选中文字颜色
  static Color bottomNavInactiveText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF8F96A3)
        : const Color(0xFF8F96A3);
  }

  /// 空状态文字颜色
  static Color emptyText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF5A6270)
        : const Color(0xFF8F96A3);
  }

  /// 错误文字颜色
  static Color errorText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFE54D4F);
  }

  /// 对话框/弹窗背景色
  static Color dialogBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.dialogTheme.backgroundColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF1E2430)
            : Colors.white);
  }

  /// 气泡（消息）背景色 - 对方消息
  static Color chatBubbleIncoming(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A3140)
        : Colors.white;
  }

  /// 气泡（消息）文字色 - 对方消息
  static Color chatBubbleIncomingText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF202531);
  }

  /// 聊天时间标签背景色
  static Color chatTimeBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A3140)
        : const Color(0xFFF7F8FB);
  }

  /// 聊天时间标签文字色
  static Color chatTimeText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF8F96A3)
        : const Color(0xFF697386);
  }

  /// 搜索提示文字颜色
  static Color searchHint(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF5A6270)
        : const Color(0xFF98A1B2);
  }

  /// 搜索输入文字颜色
  static Color searchText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF202531);
  }

  /// 搜索图标颜色
  static Color searchIcon(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF5A6270)
        : const Color(0xFF98A1B2);
  }

  /// Header 图标/按钮颜色
  static Color headerIcon(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF202531);
  }

  /// 分类按钮非激活背景色
  static Color categoryInactiveBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A3140)
        : const Color(0xFFF3F4F8);
  }

  /// 分类按钮非激活文字颜色
  static Color categoryInactiveText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF5A6270)
        : const Color(0xFF697386);
  }

  /// 分类按钮激活文字颜色
  static Color categoryActiveText(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimaryContainer;

  /// 菜单项背景色
  static Color menuItemBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A3140)
        : const Color(0xFFF7F8FB);
  }

  /// 菜单项文字色
  static Color menuText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF8F96A3)
        : const Color(0xFF697386);
  }

  /// 弹出菜单背景色
  static Color popupMenuBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF1E2430)
        : Colors.white;
  }

  /// 弹出菜单边框色
  static Color popupMenuBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A3140)
        : const Color(0xFFF0F2F6);
  }

  /// 会话列表项背景色（普通）
  static Color tileBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF121620)
        : Colors.white;
  }

  /// 会话列表项背景色（置顶高亮）
  static Color tilePinnedBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF1A2030)
        : const Color(0xFFF7F8FB);
  }

  /// 左群/退群状态文字色
  static Color leftGroupText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF5A6270)
        : const Color(0xFFB1B7C5);
  }

  /// 左群状态时间文字色
  static Color leftGroupTimeText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF3A4050)
        : const Color(0xFFC1C4C9);
  }

  /// [@我] 标签色
  static Color atMeText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFF97316)
        : const Color(0xFFF97316);
  }

  /// 免打扰图标色
  static Color mutedIcon(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF3A4050)
        : const Color(0xFFC1C4C9);
  }

  /// 未读消息标记背景色
  static Color unreadBadgeBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFE54D4F)
        : const Color(0xFFF54A45);
  }

  /// 群状态标签文字色（退出）
  static Color groupLeftStatusColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF8F96A3)
        : const Color(0xFF9AA2AF);
  }

  /// 群状态标签文字色（被踢）
  static Color groupKickedStatusColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFF5A623)
        : const Color(0xFFFF9500);
  }

  /// 群状态标签文字色（解散）
  static Color groupDisbandedStatusColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFFF3B30);
  }

  /// 加载指示器颜色
  static Color loadingColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// 消息气泡（我方）背景色
  static Color chatBubbleOutgoing(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// 消息气泡（我方）文字色
  static Color chatBubbleOutgoingText(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  /// 高亮搜索文字色
  static Color highlightText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF6BA4FF)
        : const Color(0xFF246BFD);
  }

  /// 高亮搜索背景色
  static Color highlightBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF1A3A6B)
        : const Color(0xFFEAF1FF);
  }

  /// 索引分组头部背景色
  static Color indexedHeaderBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? ThemeColors.scaffoldBg(context)
        : const Color(0xFFF5F7FB);
  }
}
