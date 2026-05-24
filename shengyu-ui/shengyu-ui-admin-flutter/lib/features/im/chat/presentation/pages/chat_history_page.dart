import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ChatHistoryPage extends ConsumerStatefulWidget {
  const ChatHistoryPage({super.key, required this.args});

  final ChatEntryArgs args;

  @override
  ConsumerState<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends ConsumerState<ChatHistoryPage> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatHistoryItem> _records = const [];
  bool _loading = false;
  bool _searched = false;
  bool _hasMore = true;
  int _pageNo = 1;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leadingWidth: 68,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF202531),
            padding: const EdgeInsets.only(left: 8),
          ),
          icon: const AppIcon(
            AppIconKind.chevronLeft,
            size: 22,
            color: Color(0xFF202531),
          ),
          label: Text(
            strings.backAction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(strings.chatHistoryTitle),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(reset: true),
                      decoration: InputDecoration(
                        icon: const AppIcon(
                          AppIconKind.search,
                          size: 18,
                          color: Color(0xFF98A1B2),
                        ),
                        hintText: strings.chatHistorySearchPlaceholder,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _search(reset: true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(strings.searchAction),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _DateFilterButton(
                    label: strings.chatHistoryStartTime,
                    value: _formatFilterDate(_startTime),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateFilterButton(
                    label: strings.chatHistoryEndTime,
                    value: _formatFilterDate(_endTime),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    side: BorderSide.none,
                    backgroundColor: const Color(0xFFF5F7FB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(strings.resetAction),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _records.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                ? _HistoryEmptyState(
                    message: _searched
                        ? strings.chatHistoryEmptySearched
                        : strings.chatHistoryEmptyIdle,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _records.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _records.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: Text(
                              _loading
                                  ? strings.chatHistoryLoading
                                  : (_hasMore ? '' : strings.chatHistoryNoMore),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF98A1B2),
                              ),
                            ),
                          ),
                        );
                      }
                      final item = _records[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _openChatAnchor(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ContactsInitialAvatar(
                                    name: item.senderName,
                                    color: _avatarColorFor(item.senderId),
                                    avatarUrl: item.senderAvatar,
                                    size: 40,
                                    borderRadius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.messageType == MessageType.system
                                              ? strings.chatGroupSystemSender
                                              : (item.senderName.trim().isEmpty
                                                    ? strings.chatHistoryUnknownUser
                                                    : item.senderName.trim()),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF202531),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(strings, item.sentAt),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF98A1B2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(left: 52),
                                child: _HighlightedContent(
                                  text: _contentText(strings, item),
                                  keyword: _searchController.text.trim(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loading || !_hasMore || !_searched) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      _search(reset: false);
    }
  }

  Future<void> _search({required bool reset}) async {
    final strings = AppLocalizations.of(context);
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.chatHistoryEnterKeyword)));
      return;
    }
    if (_loading) {
      return;
    }
    final nextPage = reset ? 1 : _pageNo + 1;
    setState(() {
      _loading = true;
      if (reset) {
        _searched = true;
      }
    });
    try {
      final records = await ref
          .read(messageRepositoryProvider)
          .searchChatHistory(
            chatId: widget.args.chatId,
            keyword: keyword,
            startTime: _startTime == null
                ? null
                : '${DateFormat('yyyy-MM-dd').format(_startTime!)} 00:00:00',
            endTime: _endTime == null
                ? null
                : '${DateFormat('yyyy-MM-dd').format(_endTime!)} 23:59:59',
            pageNo: nextPage,
            pageSize: _pageSize,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _records = reset ? records : <ChatHistoryItem>[..._records, ...records];
        _pageNo = nextPage;
        _hasMore = records.length >= _pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.chatHistorySearchFailed)));
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final strings = AppLocalizations.of(context);
    final now = DateTime.now();
    final initial = isStart ? (_startTime ?? now) : (_endTime ?? now);
    final firstDate = DateTime(2000);
    final lastDate = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    if (isStart) {
      if (_endTime != null && picked.isAfter(_endTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.chatHistoryStartAfterEnd)),
        );
        return;
      }
      setState(() {
        _startTime = picked;
      });
    } else {
      if (_startTime != null && picked.isBefore(_startTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.chatHistoryEndBeforeStart)),
        );
        return;
      }
      setState(() {
        _endTime = picked;
      });
    }
    if (_searched) {
      await _search(reset: true);
    }
  }

  void _resetFilters() {
    setState(() {
      _startTime = null;
      _endTime = null;
      _records = const [];
      _pageNo = 1;
      _hasMore = true;
    });
    if (_searched && _searchController.text.trim().isNotEmpty) {
      _search(reset: true);
    } else {
      setState(() {
        _searched = false;
      });
    }
  }

  void _openChatAnchor(ChatHistoryItem item) {
    if (item.messageId.trim().isEmpty || item.messageId.trim() == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).chatHistoryLocateFailed),
        ),
      );
      return;
    }
    context.pushNamed(
      RouteNames.chat,
      extra: ChatEntryArgs(
        chatId: widget.args.chatId,
        conversationType: widget.args.conversationType,
        targetId: widget.args.targetId,
        title: widget.args.title,
        entryMode: ChatEntryMode.anchor,
        anchorSequence: item.sequence.trim().isNotEmpty ? item.sequence : null,
        anchorMessageId: item.messageId,
        highlightedMessageId: item.messageId,
      ),
    );
  }

  String _formatFilterDate(DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context).chatHistoryUnlimited;
    }
    return DateFormat('yyyy-MM-dd').format(value);
  }

  String _formatTime(AppLocalizations strings, DateTime? dateTime) {
    if (dateTime == null) {
      return strings.groupHistoryTimeUnknown;
    }
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDay).inDays;
    final timeText = DateFormat('HH:mm').format(local);
    if (diffDays == 0) {
      return strings.chatHistoryTodayAt(timeText);
    }
    if (diffDays == 1) {
      return strings.chatHistoryYesterdayAt(timeText);
    }
    if (diffDays < 7) {
      return strings.chatHistoryDaysAgoAt(diffDays, timeText);
    }
    return strings.chatHistoryMonthDayAt(local.month, local.day, timeText);
  }

  String _contentText(AppLocalizations strings, ChatHistoryItem item) {
    if (item.content.isNotEmpty) {
      return item.content;
    }
    switch (item.systemEventKey) {
      case 'im.system.group_notice_updated':
        return strings.chatGroupNoticeUpdated;
      case 'im.system.group_mute_all_enabled':
        return strings.chatGroupMuteAllEnabled;
      case 'im.system.group_mute_all_disabled':
        return strings.chatGroupMuteAllDisabled;
      case 'im.system.group_member_added_one':
      case 'im.system.group_member_added_two':
      case 'im.system.group_member_added_many':
        return strings.chatGroupMemberAdded;
      case 'im.system.group_member_removed':
        return strings.chatGroupMemberRemoved;
      case 'im.system.group_owner_transferred':
        return strings.chatGroupOwnerTransferred;
      case 'im.system.group_member_role_set_admin':
        return strings.chatGroupMemberRoleSetAdmin;
      case 'im.system.group_member_role_set_member':
        return strings.chatGroupMemberRoleSetMember;
      case 'im.system.group_member_muted':
      case 'im.system.group_member_muted_until':
        return strings.chatGroupMemberMutedGeneric;
      case 'im.system.group_member_unmuted':
        return strings.chatGroupMemberUnmutedGeneric;
    }
    return switch (item.messageType) {
      MessageType.image => strings.chatHistoryPreviewImage,
      MessageType.voice => strings.chatHistoryPreviewVoice,
      MessageType.video => strings.chatHistoryPreviewVideo,
      MessageType.file => strings.chatHistoryPreviewFile,
      MessageType.location => strings.chatHistoryPreviewLocation,
      MessageType.emoji => strings.chatHistoryPreviewEmoji,
      MessageType.sticker => strings.chatHistoryPreviewSticker,
      MessageType.custom => strings.chatHistoryPreviewMessage,
      MessageType.contactCard => strings.chatMoreActionContactCard,
      MessageType.system => strings.chatHistoryPreviewSystem,
      MessageType.text => strings.chatHistoryPreviewMessage,
    };
  }

  Color _avatarColorFor(String seed) {
    return getUserAvatarColor(seed);
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label $value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF202531)),
              ),
            ),
            const AppIcon(
              AppIconKind.chevronDown,
              size: 16,
              color: Color(0xFF98A1B2),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              AppIconKind.history,
              size: 56,
              color: Color(0xFFD0D5DD),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF98A1B2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedContent extends StatelessWidget {
  const _HighlightedContent({required this.text, required this.keyword});

  final String text;
  final String keyword;

  @override
  Widget build(BuildContext context) {
    // 无搜索关键词时，使用 emoji 渲染
    if (keyword.isEmpty || text.isEmpty) {
      return RichText(
        text: TextSpan(
          children: buildEmojiInlineSpans(
            text: text,
            textStyle: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF4E5666),
            ),
          ),
        ),
      );
    }
    // 有搜索关键词时，同时处理 emoji 渲染和高亮
    return RichText(
      text: TextSpan(
        children: _buildHighlightedEmojiSpans(),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedEmojiSpans() {
    final normalized = normalizeEmojiDisplayText(text);
    final spans = <InlineSpan>[];
    final lowerKeyword = keyword.toLowerCase();

    // 先按 emoji token 分割文本，保留 token 位置信息
    final segments = <_EmojiSegment>[];
    var lastEnd = 0;
    for (final match in ChatEmojiCatalog.tokenRegExp.allMatches(normalized)) {
      if (match.start > lastEnd) {
        segments.add(_EmojiSegment(
          text: normalized.substring(lastEnd, match.start),
          isEmoji: false,
        ));
      }
      segments.add(_EmojiSegment(
        text: match.group(0) ?? '',
        isEmoji: true,
        emojiToken: match.group(0),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < normalized.length) {
      segments.add(_EmojiSegment(
        text: normalized.substring(lastEnd),
        isEmoji: false,
      ));
    }

    // 对每个文本片段进行关键词高亮处理
    for (final segment in segments) {
      if (segment.isEmoji) {
        // emoji 片段直接添加
        final assets = ChatEmojiCatalog.candidateAssetsFor(segment.emojiToken ?? segment.text);
        if (assets.isNotEmpty) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: ChatEmojiAssetImage(assets: assets, size: 20),
            ),
          ));
        } else {
          spans.add(TextSpan(text: segment.text, style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF4E5666),
          )));
        }
      } else {
        // 文本片段进行关键词高亮
        final lowerSource = segment.text.toLowerCase();
        var searchStart = 0;
        while (true) {
          final idx = lowerSource.indexOf(lowerKeyword, searchStart);
          if (idx < 0) {
            if (searchStart < segment.text.length) {
              spans.add(TextSpan(text: segment.text.substring(searchStart), style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF4E5666),
              )));
            }
            break;
          }
          if (idx > searchStart) {
            spans.add(TextSpan(text: segment.text.substring(searchStart, idx), style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF4E5666),
            )));
          }
          spans.add(TextSpan(
            text: segment.text.substring(idx, idx + keyword.length),
            style: const TextStyle(
              color: Color(0xFF246BFD),
              backgroundColor: Color(0xFFEAF1FF),
              fontWeight: FontWeight.w600,
            ),
          ));
          searchStart = idx + keyword.length;
        }
      }
    }
    return spans;
  }
}

class _EmojiSegment {
  final String text;
  final bool isEmoji;
  final String? emojiToken;

  _EmojiSegment({required this.text, required this.isEmoji, this.emojiToken});
}
