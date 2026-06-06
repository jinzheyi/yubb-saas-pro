import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

/// 企业级本地化格式化工具类
///
/// 所有日期/数字/文件大小格式化必须通过此类，禁止硬编码格式。
/// 格式化行为自动跟随 MaterialApp 当前语言环境。
final class LocaleFormatter {
  LocaleFormatter._();

  /// 格式化日期时间（根据当前语言环境）
  ///
  /// [context] 用于获取当前 locale
  /// [dateTime] 要格式化的日期时间
  /// [showTime] 是否显示时间部分
  ///
  /// 示例：
  /// - zh-CN: 2024-1-15 14:30
  /// - en: 1/15/2024 2:30 PM
  static String formatDateTime(
    BuildContext context,
    DateTime dateTime, {
    bool showTime = true,
  }) {
    final locale = Localizations.localeOf(context).languageCode;
    if (showTime) {
      return DateFormat.yMd(locale).add_Hm().format(dateTime);
    }
    return DateFormat.yMd(locale).format(dateTime);
  }

  /// 格式化聊天消息时间戳
  ///
  /// 规则：
  /// - 今天：今天 HH:mm
  /// - 昨天：昨天 HH:mm
  /// - 7天内：周几 HH:mm（如 周一 14:30 / Mon 14:30）
  /// - 超过7天：yyyy-M-d HH:mm
  static String formatChatTimestamp(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDiff = today.difference(targetDay).inDays;

    final time = DateFormat.Hm(locale).format(dateTime);

    if (daysDiff == 0) {
      return l10n.chatTimeToday(time);
    }
    if (daysDiff == 1) {
      return l10n.chatTimeYesterday(time);
    }
    if (daysDiff < 7) {
      final weekday = DateFormat.E(locale).format(dateTime);
      return l10n.chatPresenceWeekdayActiveAt(weekday, time);
    }
    return DateFormat.yMd(locale).add_Hm().format(dateTime);
  }

  /// 格式化相对时间（用于活跃状态显示）
  ///
  /// 规则：
  /// - 1分钟内：刚刚活跃
  /// - 1小时内：X分钟前活跃
  /// - 今天：今天活跃于 HH:mm
  /// - 昨天：昨天活跃于 HH:mm
  /// - 7天内：周几活跃于 HH:mm
  /// - 超过7天：近期活跃
  static String formatPresenceActiveTime(
    BuildContext context,
    DateTime lastActiveTime,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(lastActiveTime);

    if (diff.inMinutes < 1) {
      return l10n.chatPresenceJustNowActive;
    }
    if (diff.inHours < 1) {
      return l10n.chatPresenceMinutesAgoActive(diff.inMinutes);
    }

    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(
      lastActiveTime.year,
      lastActiveTime.month,
      lastActiveTime.day,
    );
    final daysDiff = today.difference(targetDay).inDays;
    final time = DateFormat.Hm(locale).format(lastActiveTime);

    if (daysDiff == 0) {
      return l10n.chatPresenceTodayActiveAt(time);
    }
    if (daysDiff == 1) {
      return l10n.chatPresenceYesterdayActiveAt(time);
    }
    if (daysDiff < 7) {
      final weekday = DateFormat.E(locale).format(lastActiveTime);
      return l10n.chatPresenceWeekdayActiveAt(weekday, time);
    }
    return l10n.chatPresenceRecentlyActive;
  }

  /// 格式化聊天历史时间（用于聊天记录搜索结果）
  ///
  /// 规则：
  /// - 今天：今天 {time}
  /// - 昨天：昨天 {time}
  /// - N天前：{count}天前 {time}
  /// - 其他：{month}-{day} {time}
  static String formatChatHistoryTime(
    BuildContext context,
    DateTime dateTime,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDiff = today.difference(targetDay).inDays;

    final time = DateFormat.Hm(locale).format(dateTime);

    if (daysDiff == 0) {
      return l10n.chatHistoryTodayAt(time);
    }
    if (daysDiff == 1) {
      return l10n.chatHistoryYesterdayAt(time);
    }
    if (daysDiff < 30) {
      return l10n.chatHistoryDaysAgoAt(daysDiff, time);
    }
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return l10n.chatHistoryMonthDayAt(month, day, time);
  }

  /// 格式化禁言截止时间
  ///
  /// 返回格式：{month}-{day} {hour}:{minute}
  static String formatMuteUntil(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('MM-dd HH:mm', locale).format(dateTime);
  }

  /// 格式化已读/回执时间
  ///
  /// 规则：
  /// - 1分钟内：刚刚
  /// - 今天：今天 {time}
  /// - 昨天：昨天 {time}
  /// - 其他：格式化日期时间
  static String formatReadReceiptTime(
    BuildContext context,
    DateTime readAt,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(readAt);

    if (diff.inMinutes < 1) {
      return l10n.chatReadReceiptJustNow;
    }

    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(readAt.year, readAt.month, readAt.day);
    final daysDiff = today.difference(targetDay).inDays;
    final time = DateFormat.Hm(locale).format(readAt);

    if (daysDiff == 0) {
      return l10n.chatReadReceiptTodayAt(time);
    }
    if (daysDiff == 1) {
      return l10n.chatReadReceiptYesterdayAt(time);
    }
    return DateFormat.yMd(locale).add_Hm().format(readAt);
  }

  /// 格式化入群申请时间
  ///
  /// 返回本地化的完整日期时间格式
  static String formatApplicationTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMd(locale).add_Hm().format(dateTime);
  }

  /// 格式化整数（根据语言环境添加千分位）
  ///
  /// 示例：
  /// - zh-CN: 1,234,567
  /// - en: 1,234,567
  static String formatNumber(BuildContext context, int number) {
    final locale = Localizations.localeOf(context).languageCode;
    return NumberFormat.decimalPattern(locale).format(number);
  }

  /// 格式化文件大小
  ///
  /// 返回人类可读的文件大小字符串
  /// 示例：1.5 KB, 2.3 MB, 1.05 GB
  static String formatFileSize(BuildContext context, int bytes) {
    final locale = Localizations.localeOf(context).languageCode;
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${NumberFormat('#,##0.0', locale).format(bytes / 1024)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${NumberFormat('#,##0.0', locale).format(bytes / (1024 * 1024))} MB';
    }
    return '${NumberFormat('#,##0.00', locale).format(bytes / (1024 * 1024 * 1024))} GB';
  }

  /// 格式化媒体日期分组标题（用于聊天媒体页面）
  ///
  /// 规则：
  /// - 今天：今天
  /// - 昨天：昨天
  /// - 其他：{month}-{day}（如 01-15）
  static String formatMediaDateGroup(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDiff = today.difference(targetDay).inDays;

    if (daysDiff == 0) return l10n.chatMediaToday;
    if (daysDiff == 1) return l10n.chatMediaYesterday;

    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return l10n.chatMediaMonthDay(month, day);
  }

  /// 格式化转发合并详情时间
  ///
  /// 规则与聊天时间戳相同
  static String formatForwardCombineTime(
    BuildContext context,
    DateTime dateTime,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDiff = today.difference(targetDay).inDays;

    final time = DateFormat.Hm(locale).format(dateTime);

    if (daysDiff == 0) {
      return l10n.chatForwardCombineDetailTodayAt(time);
    }
    if (daysDiff == 1) {
      return l10n.chatForwardCombineDetailYesterdayAt(time);
    }
    return DateFormat.yMd(locale).add_Hm().format(dateTime);
  }
}
