import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/search/domain/entities/message_search_item.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class SearchChatHistoryPage extends ConsumerStatefulWidget {
  const SearchChatHistoryPage({super.key, this.initialKeyword = ''});

  final String initialKeyword;

  @override
  ConsumerState<SearchChatHistoryPage> createState() =>
      _SearchChatHistoryPageState();
}

class _SearchChatHistoryPageState extends ConsumerState<SearchChatHistoryPage> {
  late final TextEditingController _searchController;
  List<MessageSearchItem> _items = const [];
  bool _searched = false;
  bool _loading = false;
  bool _hasMore = true;
  int _pageNo = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialKeyword);
    if (widget.initialKeyword.trim().isNotEmpty) {
      Future.microtask(() => _search(reset: true));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(strings.globalChatSearchTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 19,
                          color: Color(0xFF98A1B2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: widget.initialKeyword.trim().isEmpty,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(reset: true),
                            decoration: InputDecoration(
                              hintText: strings.globalChatSearchPlaceholder,
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => _search(reset: true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 40),
                    backgroundColor: const Color(0xFF246BFD),
                  ),
                  child: Text(strings.searchAction),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _items.isEmpty && !_loading
                ? Center(
                    child: Text(
                      _searched
                          ? strings.globalChatSearchEmpty
                          : strings.globalChatSearchHint,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 48) {
                        _search(reset: false);
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _items.length + (_loading || _hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                _loading
                                    ? strings.globalChatSearchLoading
                                    : strings.globalChatSearchLoadMore,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8F96A3),
                                ),
                              ),
                            ),
                          );
                        }
                        final item = _items[index];
                        final displayTitle = _displayTitle(item);
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openSearchResult(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF3FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: Color(0xFF246BFD),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF202531),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF4E5666),
                                              height: 1.35,
                                            ),
                                            children: _highlightContent(
                                              _displayContent(strings, item),
                                              _searchController.text.trim(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _buildMeta(item),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8F96A3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatTime(item.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8F96A3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _search({required bool reset}) async {
    final keyword = _searchController.text.trim();
    if (keyword.length < 2) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).searchMinLength)),
      );
      return;
    }
    if (_loading || (!reset && !_hasMore)) {
      return;
    }
    if (reset) {
      setState(() {
        _pageNo = 1;
        _hasMore = true;
        _items = const [];
      });
    }
    setState(() {
      _searched = true;
      _loading = true;
    });
    try {
      final result = await ref
          .read(messageRepositoryProvider)
          .searchMessages(
            keyword: keyword,
            pageNo: _pageNo,
            pageSize: _pageSize,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = reset ? result : [..._items, ...result];
        _hasMore = result.length >= _pageSize;
        if (_hasMore) {
          _pageNo += 1;
        }
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
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  List<TextSpan> _highlightContent(String content, String keyword) {
    if (keyword.isEmpty || content.isEmpty) {
      return [TextSpan(text: content)];
    }
    final lowerContent = content.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lowerContent.indexOf(lowerKeyword, start);
      if (index < 0) {
        spans.add(TextSpan(text: content.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: content.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: content.substring(index, index + keyword.length),
          style: const TextStyle(
            color: Color(0xFF246BFD),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + keyword.length;
    }
    return spans;
  }

  String _displayContent(AppLocalizations strings, MessageSearchItem item) {
    final snippet = item.snippet.trim();
    if (snippet.isNotEmpty) {
      return snippet;
    }
    final highlight = item.highlight.trim();
    if (highlight.isNotEmpty) {
      return highlight;
    }
    return _contentText(strings, item);
  }

  String _buildMeta(MessageSearchItem item) {
    final parts = <String>[];
    if (item.senderName.trim().isNotEmpty) {
      parts.add(item.senderName.trim());
    }
    if (item.messageType.trim().isNotEmpty) {
      parts.add(item.messageType.trim());
    }
    return parts.join(' · ');
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    return DateFormat('MM-dd HH:mm').format(dateTime.toLocal());
  }

  void _openSearchResult(MessageSearchItem item) {
    if (item.chatId.isEmpty || item.chatId == '0' || item.messageId.isEmpty) {
      return;
    }
    final isGroup =
        item.conversationType == 2 ||
        (item.groupId.isNotEmpty && item.groupId != '0');
    final displayTitle = _displayTitle(item);
    context.pushNamed(
      RouteNames.chat,
      extra: ChatEntryArgs(
        chatId: item.chatId,
        conversationType: isGroup
            ? ConversationType.group
            : ConversationType.direct,
        targetId: isGroup
            ? (item.groupId.isNotEmpty ? item.groupId : item.targetId)
            : item.targetId,
        title: displayTitle,
        entryMode: ChatEntryMode.anchor,
        anchorSequence: item.sequence.isNotEmpty && item.sequence != '0'
            ? item.sequence
            : null,
        anchorMessageId: item.messageId,
        highlightedMessageId: item.messageId,
      ),
    );
  }

  String _contentText(AppLocalizations strings, MessageSearchItem item) {
    if (item.content.isNotEmpty) {
      return item.content;
    }
    switch (item.messageType.toLowerCase()) {
      case 'image':
      case '2':
        return strings.chatHistoryPreviewImage;
      case 'voice':
      case '3':
        return strings.chatHistoryPreviewVoice;
      case 'video':
      case '4':
        return strings.chatHistoryPreviewVideo;
      case 'file':
      case '5':
        return strings.chatHistoryPreviewFile;
      case 'location':
      case '6':
        return strings.chatHistoryPreviewLocation;
      case 'emoji':
      case '7':
        return strings.chatHistoryPreviewEmoji;
      case 'sticker':
      case '8':
        return strings.chatHistoryPreviewSticker;
      case 'system':
        return strings.chatHistoryPreviewSystem;
      default:
        return strings.chatHistoryPreviewMessage;
    }
  }

  String _displayTitle(MessageSearchItem item) {
    final conversationName = item.conversationName.trim();
    if (conversationName.isNotEmpty) {
      return conversationName;
    }
    final senderName = item.senderName.trim();
    if (senderName.isNotEmpty) {
      return senderName;
    }
    return item.chatId;
  }
}
