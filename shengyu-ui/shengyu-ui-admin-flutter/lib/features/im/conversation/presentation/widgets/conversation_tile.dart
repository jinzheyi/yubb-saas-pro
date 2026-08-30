import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/conversation_preview_cache.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

/// 会话列表项组件
/// 已从 StatefulWidget 改为 StatelessWidget，消除不必要的 State 创建和销毁
/// 鼠标长按使用 _MouseLongPressHandler 独立处理
/// 角标数字从 BadgeState 读取（单一数据源），确保与会话列表/Tab 栏一致
class ConversationTile extends ConsumerWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
    this.onLongPressStart,
    this.onSecondaryTapDown,
    this.onMouseLongPress,
    this.highlightPinned = false,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureTapDownCallback? onSecondaryTapDown;
  final ValueChanged<Offset>? onMouseLongPress;
  final bool highlightPinned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final conversation = this.conversation;
    final displayTitle = _displayTitle(conversation);
    final previewTokens = _buildPreviewTokens(strings, conversation);
    final showGroupCount =
        conversation.conversationType == ConversationType.group &&
        conversation.groupMemberCount > 0;
    final showGroupStatus =
        conversation.conversationType == ConversationType.group &&
        conversation.groupMemberStatus != null &&
        conversation.groupMemberStatus != 0;
    final isLeftGroup =
        conversation.conversationType == ConversationType.group &&
        (conversation.isGroupKicked ||
            conversation.isGroupLeft ||
            conversation.isGroupDisbanded);

    // 从 BadgeState 读取角标（单一数据源），fallback 到 conversation.unreadCount
    final badgeState = ref.watch(badgeServiceProvider);
    final unreadCount =
        badgeState.conversationBadges[conversation.chatId] ??
        conversation.unreadCount;

    return Material(
      color: highlightPinned
          ? ThemeColors.tilePinnedBg(context)
          : ThemeColors.tileBg(context),
      child: _MouseLongPressHandler(
        onLongPress: onMouseLongPress,
        child: GestureDetector(
          onLongPress: onLongPress,
          onLongPressStart: onLongPressStart,
          onSecondaryTapDown: onSecondaryTapDown,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ConversationAvatar(
                    conversation: conversation,
                    displayTitle: displayTitle,
                    unreadCount: unreadCount,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isLeftGroup
                                                ? ThemeColors.leftGroupText(
                                                    context,
                                                  )
                                                : ThemeColors.textPrimary(
                                                    context,
                                                  ),
                                          ),
                                    ),
                                  ),
                                  if (showGroupCount) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${conversation.groupMemberCount})',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 13,
                                            color: ThemeColors.leftGroupText(
                                              context,
                                            ),
                                          ),
                                    ),
                                  ],
                                  if (showGroupStatus && !isLeftGroup) ...[
                                    const SizedBox(width: 4),
                                    _GroupStatusBadge(
                                      status: conversation.groupMemberStatus!,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatUpdatedAt(context, conversation.updatedAt),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isLeftGroup
                                    ? ThemeColors.leftGroupTimeText(context)
                                    : ThemeColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (conversation.lastMessageHasAtMe && !isLeftGroup)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  '[@我]',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ThemeColors.atMeText(context),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: _buildMessageSpans(
                                    context,
                                    isLeftGroup,
                                    conversation,
                                    previewTokens,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversation.isMuted)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: AppIcon(
                                  AppIconKind.muteOff,
                                  size: 14,
                                  color: ThemeColors.mutedIcon(context),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildMessageSpans(
    BuildContext context,
    bool isLeftGroup,
    Conversation conversation,
    List<_PreviewToken> previewTokens,
  ) {
    final theme = Theme.of(context);
    if (isLeftGroup) {
      final statusText = conversation.isGroupKicked
          ? '你已被移出群聊'
          : conversation.isGroupLeft
          ? '你已退出该群聊'
          : '该群已解散';
      return [
        TextSpan(
          text: statusText,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: ThemeColors.textSecondary(context),
          ),
        ),
      ];
    }

    final spans = <InlineSpan>[];
    for (final token in previewTokens) {
      spans.addAll(
        buildEmojiInlineSpans(
          text: token.text,
          textStyle: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: token.isNotice
                ? ThemeColors.chatTimeText(context)
                : ThemeColors.textSecondary(context),
          ),
          emojiSize: 14,
          emojiPadding: const EdgeInsets.symmetric(horizontal: 1),
        ),
      );
    }
    return spans;
  }
}

/// 鼠标长按处理器（提取为独立组件，避免 ConversationTile 持有 State）
class _MouseLongPressHandler extends StatefulWidget {
  const _MouseLongPressHandler({required this.child, this.onLongPress});

  final Widget child;
  final ValueChanged<Offset>? onLongPress;

  @override
  State<_MouseLongPressHandler> createState() => _MouseLongPressHandlerState();
}

class _MouseLongPressHandlerState extends State<_MouseLongPressHandler> {
  Timer? _mouseLongPressTimer;
  Offset? _mouseLongPressPosition;

  @override
  void dispose() {
    _mouseLongPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onLongPress == null) {
      return widget.child;
    }
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: (_) => _cancelMouseLongPress(),
      onPointerCancel: (_) => _cancelMouseLongPress(),
      child: widget.child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse ||
        widget.onLongPress == null ||
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    _cancelMouseLongPress();
    _mouseLongPressPosition = event.position;
    _mouseLongPressTimer = Timer(const Duration(milliseconds: 450), () {
      final position = _mouseLongPressPosition;
      _mouseLongPressTimer = null;
      if (position != null) {
        widget.onLongPress?.call(position);
      }
    });
  }

  void _cancelMouseLongPress() {
    _mouseLongPressTimer?.cancel();
    _mouseLongPressTimer = null;
    _mouseLongPressPosition = null;
  }
}

// 模块级缓存：预编译正则表达式，避免每次 build 重新解析
final _previewTokenPattern = RegExp(r'\[[\u4e00-\u9fa5\w]+\]');
final _newlinePattern = RegExp(r'\r?\n+');

String _displayTitle(Conversation conversation) {
  final trimmedTitle = conversation.title.trim();
  if (trimmedTitle.isNotEmpty) {
    return trimmedTitle;
  }
  final targetId = conversation.targetId?.trim() ?? '';
  if (targetId.isNotEmpty) {
    return targetId;
  }
  return conversation.chatId;
}

List<_PreviewToken> _buildPreviewTokens(
  AppLocalizations strings,
  Conversation conversation,
) {
  // 构建缓存 key：chatId + previewVersion
  final cacheKey = '${conversation.chatId}|${conversation.previewVersion}';

  // 尝试从缓存获取（命中则直接返回，避免字符串处理）
  final cached = ConversationPreviewCache.instance.get(cacheKey);
  if (cached != null) {
    final tokens = <_PreviewToken>[];
    for (var i = 0; i < cached.tokens.length; i++) {
      tokens.add(
        _PreviewToken(
          text: cached.tokens[i],
          isNotice: cached.isNoticeFlags[i],
        ),
      );
    }
    return tokens;
  }

  // 缓存未命中：计算并缓存
  final preview = _previewText(strings, conversation);
  if (preview.isEmpty) {
    // 缓存空结果，避免重复计算
    ConversationPreviewCache.instance.put(
      cacheKey,
      const PreviewCacheEntry(tokens: [], isNoticeFlags: []),
    );
    return const <_PreviewToken>[];
  }
  final matches = _previewTokenPattern.allMatches(preview);
  if (matches.isEmpty) {
    final result = <_PreviewToken>[
      _PreviewToken(
        text: preview,
        isNotice: _shouldHighlightPreview(conversation, preview),
      ),
    ];
    _cachePreview(cacheKey, result);
    return result;
  }

  final tokens = <_PreviewToken>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start > cursor) {
      final text = preview.substring(cursor, match.start);
      tokens.add(
        _PreviewToken(
          text: text,
          isNotice: _shouldHighlightPreview(conversation, text),
        ),
      );
    }
    final text = match.group(0) ?? '';
    if (text.isNotEmpty) {
      tokens.add(
        _PreviewToken(
          text: text,
          isNotice: _shouldHighlightPreview(conversation, text),
        ),
      );
    }
    cursor = match.end;
  }
  if (cursor < preview.length) {
    final text = preview.substring(cursor);
    tokens.add(
      _PreviewToken(
        text: text,
        isNotice: _shouldHighlightPreview(conversation, text),
      ),
    );
  }

  // 写入缓存
  _cachePreview(cacheKey, tokens);
  return tokens;
}

/// 将预览结果写入缓存
void _cachePreview(String cacheKey, List<_PreviewToken> tokens) {
  final texts = <String>[];
  final flags = <bool>[];
  for (final token in tokens) {
    texts.add(token.text);
    flags.add(token.isNotice);
  }
  ConversationPreviewCache.instance.put(
    cacheKey,
    PreviewCacheEntry(tokens: texts, isNoticeFlags: flags),
  );
}

bool _isNoticePreview(String preview) {
  final normalized = preview.trim();
  return normalized == '[群公告更新]' || normalized == '[Notice Updated]';
}

bool _shouldHighlightPreview(Conversation conversation, String tokenText) {
  if (_isNoticePreview(tokenText)) {
    return true;
  }
  if (conversation.lastMessageType == MessageType.system) {
    return true;
  }
  final isExplicitSelfPreview = conversation.lastMessageIsSelf;
  return conversation.lastMessageType != MessageType.text &&
      !isExplicitSelfPreview;
}

String _previewText(AppLocalizations strings, Conversation conversation) {
  final rawPreview = conversation.lastMessagePreview.trim().replaceAll(
    _newlinePattern,
    ' ',
  );
  final canFormatGroupPreview =
      conversation.conversationType != ConversationType.group ||
      conversation.lastMessageType == MessageType.system ||
      conversation.lastMessageIsSelf ||
      (conversation.lastMessageSenderName?.trim().isNotEmpty ?? false);
  final preview =
      (canFormatGroupPreview
              ? MessagePreviewFormatterWithContext(
                  strings,
                ).formatConversationPreview(
                  type: conversation.lastMessageType,
                  content: conversation.lastMessagePreview,
                  customType: conversation.lastMessageCustomType,
                  fileName: conversation.lastMessageFileName,
                  systemEventKey: conversation.lastMessageSystemEventKey,
                  systemEventParams: conversation.lastMessageSystemEventParams,
                  conversationType: conversation.conversationType,
                  isSelf: conversation.lastMessageIsSelf,
                  senderName: conversation.lastMessageSenderName,
                )
              : rawPreview)
          .trim()
          .replaceAll(_newlinePattern, ' ');
  if (preview.isNotEmpty) {
    return preview.length > 100 ? '${preview.substring(0, 100)}...' : preview;
  }
  if (conversation.lastMessageType == MessageType.text) {
    return '';
  }
  return switch (conversation.lastMessageType) {
    MessageType.image => strings.chatHistoryPreviewImage,
    MessageType.voice => strings.chatHistoryPreviewVoice,
    MessageType.video => strings.chatHistoryPreviewVideo,
    MessageType.file => strings.chatHistoryPreviewFile,
    MessageType.location => strings.chatHistoryPreviewLocation,
    MessageType.emoji => strings.chatHistoryPreviewEmoji,
    MessageType.sticker => strings.chatHistoryPreviewSticker,
    MessageType.custom => strings.chatHistoryPreviewMessage,
    MessageType.contactCard => '[${strings.chatContactCardLabel}]',
    MessageType.system => strings.chatHistoryPreviewSystem,
    MessageType.text => strings.chatHistoryPreviewMessage,
    MessageType.callRecord => '[通话记录]',
  };
}

String _formatUpdatedAt(BuildContext context, DateTime value) {
  final locale = AppLocalizations.of(context).localeName.toLowerCase();
  final now = DateTime.now();
  final localValue = value.toLocal();
  if (localValue.millisecondsSinceEpoch <= 0) {
    return '';
  }
  if (now.year == localValue.year &&
      now.month == localValue.month &&
      now.day == localValue.day) {
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (yesterday.year == localValue.year &&
      yesterday.month == localValue.month &&
      yesterday.day == localValue.day) {
    return locale.startsWith('zh') ? '昨天' : 'Yesterday';
  }
  final difference = DateTime(now.year, now.month, now.day)
      .difference(DateTime(localValue.year, localValue.month, localValue.day))
      .inDays;
  if (difference > 0 && difference < 7) {
    if (locale.startsWith('zh')) {
      const weekdays = <String>[
        '星期日',
        '星期一',
        '星期二',
        '星期三',
        '星期四',
        '星期五',
        '星期六',
      ];
      return weekdays[localValue.weekday % 7];
    }
    const weekdays = <String>[
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return weekdays[localValue.weekday % 7];
  }
  final month = localValue.month.toString().padLeft(2, '0');
  final day = localValue.day.toString().padLeft(2, '0');
  if (now.year == localValue.year) {
    return '$month/$day';
  }
  return '${localValue.year}/$month/$day';
}

class _PreviewToken {
  const _PreviewToken({required this.text, required this.isNotice});

  final String text;
  final bool isNotice;
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.conversation,
    required this.displayTitle,
    this.unreadCount = 0,
  });

  final Conversation conversation;
  final String displayTitle;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (conversation.conversationType == ConversationType.group)
          GroupAvatarWidget.fromMembers(
            // 群自定义头像优先；未设置时才以服务端稳定排序的成员资料拼图。
            // 成员资料暂缺不再把群名伪造成成员，避免列表同步时头像跳变。
            avatarUrl: conversation.targetAvatar,
            fallbackName: _fallbackText(),
            fallbackSeed: conversation.targetId ?? conversation.chatId,
            members: conversation.groupMemberItems
                .map(
                  (item) => GroupAvatarMember(
                    userId: item.userId ?? '',
                    name: item.name ?? '',
                    avatarUrl: item.avatar,
                  ),
                )
                .toList(),
            size: 48,
            borderRadius: 8,
          )
        else
          AppAvatar(
            name: _fallbackText(),
            avatarUrl: conversation.targetAvatar,
            seed: conversation.targetId,
            backgroundColor: resolveConversationAvatarBg(
              avatarBg: conversation.avatarBg,
              conversationType: conversation.conversationType,
              targetId: conversation.targetId,
              chatId: conversation.chatId,
            ),
            size: 48,
            borderRadius: 8,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        if (unreadCount > 0)
          Positioned(
            top: conversation.isMuted ? -3 : -7,
            right: conversation.isMuted ? -3 : -7,
            child: conversation.isMuted
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: ThemeColors.unreadBadgeBg(context),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: ThemeColors.scaffoldBg(context),
                        width: 2,
                      ),
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: ThemeColors.unreadBadgeBg(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ThemeColors.scaffoldBg(context),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  String _fallbackText() {
    return resolveConversationAvatarText(
      avatarText: conversation.avatarText,
      title: displayTitle,
      targetId: conversation.targetId,
    );
  }
}

class _GroupStatusBadge extends StatelessWidget {
  const _GroupStatusBadge({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      1 => ('已退出', ThemeColors.groupLeftStatusColor(context)),
      2 => ('已被踢', ThemeColors.groupKickedStatusColor(context)),
      3 => ('已解散', ThemeColors.groupDisbandedStatusColor(context)),
      _ => ('', Colors.transparent),
    };
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
