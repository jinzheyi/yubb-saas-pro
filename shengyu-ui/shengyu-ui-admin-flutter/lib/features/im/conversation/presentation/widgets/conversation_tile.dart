import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ConversationTile extends StatefulWidget {
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
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  Timer? _mouseLongPressTimer;
  Offset? _mouseLongPressPosition;

  @override
  void dispose() {
    _mouseLongPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final conversation = widget.conversation;
    final displayTitle = _displayTitle(conversation);
    final previewTokens = _buildPreviewTokens(strings, conversation);
    final showGroupCount =
        conversation.conversationType == ConversationType.group &&
        conversation.groupMemberCount > 0;

    return Material(
      color: widget.highlightPinned ? const Color(0xFFF7F8FB) : Colors.white,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: (_) => _cancelMouseLongPress(),
        onPointerCancel: (_) => _cancelMouseLongPress(),
        child: GestureDetector(
          onLongPress: widget.onLongPress,
          onLongPressStart: widget.onLongPressStart,
          onSecondaryTapDown: widget.onSecondaryTapDown,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ConversationAvatar(
                    conversation: conversation,
                    displayTitle: displayTitle,
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
                                            color: const Color(0xFF202531),
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
                                            color: const Color(0xFFB1B7C5),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatUpdatedAt(context, conversation.updatedAt),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF9AA2AF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (conversation.lastMessageHasAtMe)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Text(
                                  '[@我]',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFF97316),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    for (final token in previewTokens)
                                      ...buildEmojiInlineSpans(
                                        text: token.text,
                                        textStyle: theme.textTheme.bodyMedium!
                                            .copyWith(
                                              fontSize: 13,
                                              height: 18 / 13,
                                              color: token.isNotice
                                                  ? const Color(0xFFF54A45)
                                                  : const Color(0xFF697386),
                                            ),
                                        emojiSize: 14,
                                        emojiPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 1,
                                            ),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversation.isMuted)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: AppIcon(
                                  AppIconKind.muteOff,
                                  size: 14,
                                  color: Color(0xFFC1C4C9),
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

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse ||
        widget.onMouseLongPress == null ||
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    _cancelMouseLongPress();
    _mouseLongPressPosition = event.position;
    _mouseLongPressTimer = Timer(const Duration(milliseconds: 450), () {
      final position = _mouseLongPressPosition;
      _mouseLongPressTimer = null;
      if (position != null) {
        widget.onMouseLongPress?.call(position);
      }
    });
  }

  void _cancelMouseLongPress() {
    _mouseLongPressTimer?.cancel();
    _mouseLongPressTimer = null;
    _mouseLongPressPosition = null;
  }
}

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
  final preview = _previewText(strings, conversation);
  if (preview.isEmpty) {
    return const <_PreviewToken>[];
  }
  final matches = RegExp(r'\[[\u4e00-\u9fa5\w]+\]').allMatches(preview);
  if (matches.isEmpty) {
    return <_PreviewToken>[
      _PreviewToken(
        text: preview,
        isNotice: _shouldHighlightPreview(conversation, preview),
      ),
    ];
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
  return tokens;
}

bool _isNoticePreview(String preview) {
  final normalized = preview.trim();
  return normalized == '[群公告更新]' ||
      normalized == '[Notice Updated]' ||
      normalized.startsWith('系统信息:') ||
      normalized.startsWith('System:');
}

bool _shouldHighlightPreview(Conversation conversation, String tokenText) {
  if (_isNoticePreview(tokenText)) {
    return true;
  }
  final normalizedPreview = conversation.lastMessagePreview.trimLeft();
  final isExplicitSelfPreview =
      conversation.lastMessageIsSelf ||
      normalizedPreview.startsWith('我:') ||
      normalizedPreview.startsWith('Me:');
  return conversation.lastMessageType != MessageType.text &&
      !isExplicitSelfPreview;
}

String _previewText(AppLocalizations strings, Conversation conversation) {
  final rawPreview = conversation.lastMessagePreview.trim().replaceAll(
    RegExp(r'\r?\n+'),
    ' ',
  );
  final canFormatGroupPreview =
      conversation.conversationType != ConversationType.group ||
      conversation.lastMessageType == MessageType.system ||
      conversation.lastMessageIsSelf ||
      (conversation.lastMessageSenderName?.trim().isNotEmpty ?? false);
  final preview =
      (canFormatGroupPreview
              ? MessagePreviewFormatter(
                  strings.localeName,
                ).formatConversationPreview(
                  type: conversation.lastMessageType,
                  content: conversation.lastMessagePreview,
                  customType: conversation.lastMessageCustomType,
                  fileName: conversation.lastMessageFileName,
                  systemEventKey: conversation.lastMessageSystemEventKey,
                  conversationType: conversation.conversationType,
                  isSelf: conversation.lastMessageIsSelf,
                  senderName: conversation.lastMessageSenderName,
                )
              : rawPreview)
          .trim()
          .replaceAll(RegExp(r'\r?\n+'), ' ');
  if (preview.isNotEmpty) {
    return preview.length > 100 ? '${preview.substring(0, 100)}...' : preview;
  }
  // Don't show fallback for text messages with empty content
  // This handles both brand-new conversations and local optimistic messages
  // that haven't been confirmed by the server yet
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
  });

  final Conversation conversation;
  final String displayTitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (conversation.conversationType == ConversationType.group)
          GroupAvatarWidget.fromMembers(
            members: conversation.groupMemberItems.isEmpty
                ? _fallbackGroupMembersFromTitle(conversation.title)
                : conversation.groupMemberItems
                    .map((item) => GroupAvatarMember(
                          userId: item.userId ?? '',
                          name: item.name ?? '',
                          avatarUrl: item.avatar,
                        ))
                    .toList(),
            size: 48,
            borderRadius: 8,
          )
        else
          AppAvatar(
            name: _fallbackText(),
            avatarUrl: conversation.targetAvatar,
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
        if (conversation.unreadCount > 0)
          Positioned(
            top: conversation.isMuted ? -3 : -7,
            right: conversation.isMuted ? -3 : -7,
            child: conversation.isMuted
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF54A45),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF54A45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      conversation.unreadCount > 99
                          ? '99+'
                          : '${conversation.unreadCount}',
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

  List<GroupAvatarMember> _fallbackGroupMembersFromTitle(String title) {
    final names = title
        .split(RegExp(r'[、，, ]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return names
        .map((name) => GroupAvatarMember(userId: name, name: name))
        .toList();
  }
}
