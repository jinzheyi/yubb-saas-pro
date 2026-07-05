import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/file_preview_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_bubble_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/providers/favorite_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/providers/file_preview_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

// 预编译正则表达式，避免循环内重复构造
final _quoteCharPattern = RegExp(r'''["']''');

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FavoriteItem> _records = const [];
  bool _loading = false;
  bool _searched = false;
  bool _hasMore = true;
  int _pageNo = 1;
  DateTime? _startTime;
  DateTime? _endTime;
  _FavoriteFilter _filter = _FavoriteFilter.all;
  String _currentKeyword = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadInitialData();
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
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: AppIcon(
            AppIconKind.chevronLeft,
            size: 22,
            color: ThemeColors.headerIcon(context),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(strings.favoritePageTitle),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          _buildDateFilter(),
          Expanded(child: _buildContent(strings)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final strings = AppLocalizations.of(context);
    return Container(
      color: ThemeColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: ThemeColors.searchBarBg(context),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    ShengyuIconFont.chaxun,
                    size: 16,
                    color: ThemeColors.searchIcon(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeColors.searchText(context),
                      ),
                      onSubmitted: (_) => _search(reset: true),
                      decoration: InputDecoration(
                        hintText: strings.favoriteSearchPlaceholder,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isCollapsed: true,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: ThemeColors.searchHint(context),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.trim().isNotEmpty)
                    InkWell(
                      onTap: () => _search(reset: true),
                      child: Icon(
                        ShengyuIconFont.fasong,
                        size: 16,
                        color: ThemeColors.searchIcon(context),
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

  Widget _buildFilterBar() {
    return Container(
      color: ThemeColors.scaffoldBg(context),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in _FavoriteFilter.values)
            _FilterChip(
              label: filter.label(AppLocalizations.of(context)),
              selected: _filter == filter,
              onTap: () => _changeFilter(filter),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    final strings = AppLocalizations.of(context);
    return Container(
      color: ThemeColors.surface(context),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              side: BorderSide.none,
              backgroundColor: ThemeColors.surfaceDim(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              foregroundColor: ThemeColors.textPrimary(context),
            ),
            child: Text(strings.resetAction),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations strings) {
    if (_loading && _records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_records.isEmpty) {
      return _HistoryEmptyState(
        message: _searched
            ? strings.chatHistoryEmptySearched
            : strings.favoritePageEmpty,
      );
    }
    return ListView.builder(
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
                style: TextStyle(
                  fontSize: 13,
                  color: ThemeColors.textSecondary(context),
                ),
              ),
            ),
          );
        }
        final item = _records[index];
        final historyItem = _toHistoryItem(item);
        final message = _toMessage(item, historyItem);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeColors.surface(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ContactsInitialAvatar(
                    name: historyItem.senderName,
                    color: _avatarColorFor(historyItem.senderId),
                    avatarUrl: historyItem.senderAvatar,
                    seed: historyItem.senderId,
                    size: 40,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historyItem.senderName.trim().isEmpty
                              ? strings.chatHistoryUnknownUser
                              : historyItem.senderName.trim(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ThemeColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(strings, historyItem.sentAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.textSecondary(context),
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
                child: _buildMessageBubble(message, historyItem, item),
              ),
            ],
          ),
        );
      },
    );
  }

  ChatHistoryItem _toHistoryItem(FavoriteItem item) {
    // 优先使用后端返回的发送者信息，兼容旧数据从快照解析
    String senderName = item.senderNickname.trim();
    String senderAvatar = item.senderAvatar.trim();
    String senderId = item.senderId.trim();
    
    if (senderName.isEmpty) {
      final parsedSnapshot = _safeParseJson(item.messageSnapshot);
      final snapshotMap = parsedSnapshot is Map<String, dynamic> ? parsedSnapshot : null;
      senderName = snapshotMap?['senderName']?.toString() ?? '';
      senderAvatar = snapshotMap?['senderAvatar']?.toString() ?? '';
      if (senderId.isEmpty) {
        senderId = snapshotMap?['senderId']?.toString() ?? item.messageId;
      }
    }
    if (senderId.isEmpty) {
      senderId = item.messageId;
    }
    
    String? sentAt;
    final rawTime = item.sendTime.trim().isNotEmpty
        ? item.sendTime
        : item.favoriteTime;
    if (rawTime.isNotEmpty) {
      sentAt = rawTime.contains(' ')
          ? rawTime.replaceFirst(' ', 'T')
          : rawTime;
    }
    
    DateTime? parsedDate;
    if (sentAt != null && sentAt.isNotEmpty) {
      parsedDate = DateTime.tryParse(sentAt);
      if (parsedDate == null) {
        final millis = int.tryParse(sentAt);
        if (millis != null && millis > 0) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(
            sentAt.length <= 10 ? millis * 1000 : millis,
          );
        }
      }
    }

    final content = _extractFavoriteContent(item);

    return ChatHistoryItem(
      messageId: item.messageId,
      chatId: '',
      sequence: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      messageType: _toMessageType(item.messageType),
      sentAt: parsedDate,
      extra: item.messageExtra,
    );
  }

  Message _toMessage(FavoriteItem item, ChatHistoryItem historyItem) {
    final extra = _parseMessageExtra(item);
    return Message(
      messageId: item.messageId,
      chatId: '',
      senderId: historyItem.senderId,
      senderName: historyItem.senderName,
      senderAvatar: historyItem.senderAvatar,
      type: historyItem.messageType,
      status: MessageStatus.delivered,
      content: historyItem.content,
      sentAt: historyItem.sentAt ?? DateTime.now(),
      isOutgoing: false,
      sequence: '',
      extra: extra,
    );
  }

  MessageExtra _parseMessageExtra(FavoriteItem item) {
    final extraData = _parseExtraFromFavorite(item);
    if (extraData.isNotEmpty) {
      return MessageExtra(
        fileId: extraData['fileId'],
        fileUrl: extraData['url']?.isNotEmpty == true ? extraData['url'] : extraData['fileUrl'],
        fileName: extraData['fileName'],
        mimeType: extraData['fileType']?.isNotEmpty == true ? extraData['fileType'] : extraData['mimeType'],
        fileType: extraData['fileType'],
        fileSize: int.tryParse(extraData['size'] ?? extraData['fileSize'] ?? ''),
        thumbnailUrl: extraData['thumbnailUrl'],
        thumbFileId: extraData['thumbFileId'],
        width: int.tryParse(extraData['width'] ?? ''),
        height: int.tryParse(extraData['height'] ?? ''),
        duration: int.tryParse(extraData['duration'] ?? ''),
        durationMs: int.tryParse(extraData['durationMs'] ?? ''),
        stickerId: extraData['stickerId'],
        contactUserId: extraData['contactUserId'],
        contactDisplayName: extraData['contactDisplayName'],
        contactAvatar: extraData['contactAvatar'],
        locationName: extraData['locationName'],
        locationAddress: extraData['locationAddress'],
        locationLatitude: double.tryParse(extraData['locationLatitude'] ?? ''),
        locationLongitude: double.tryParse(extraData['locationLongitude'] ?? ''),
        customType: extraData['customType'],
      );
    }

    final content = item.messageContent.trim();
    if (content.isEmpty || !content.startsWith('{') || !content.endsWith('}')) {
      return MessageExtra(
        fileName: _extractFavoritePlainText(item),
      );
    }
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return MessageExtra(
        fileId: map['fileId']?.toString(),
        fileUrl: map['fileUrl']?.toString(),
        fileName: map['fileName']?.toString(),
        mimeType: map['mimeType']?.toString(),
        fileType: map['fileType']?.toString(),
        fileSize: int.tryParse(map['fileSize']?.toString() ?? ''),
        thumbnailUrl: map['thumbnailUrl']?.toString(),
        thumbFileId: map['thumbFileId']?.toString(),
        width: int.tryParse(map['width']?.toString() ?? ''),
        height: int.tryParse(map['height']?.toString() ?? ''),
        duration: int.tryParse(map['duration']?.toString() ?? ''),
        durationMs: int.tryParse(map['durationMs']?.toString() ?? ''),
        stickerId: map['stickerId']?.toString(),
        contactUserId: map['contactUserId']?.toString(),
        contactDisplayName: map['contactDisplayName']?.toString(),
        contactAvatar: map['contactAvatar']?.toString(),
        locationName: map['locationName']?.toString(),
        locationAddress: map['locationAddress']?.toString(),
        locationLatitude: double.tryParse(map['locationLatitude']?.toString() ?? ''),
        locationLongitude: double.tryParse(map['locationLongitude']?.toString() ?? ''),
        customType: map['customType']?.toString(),
      );
    } catch (_) {
      return MessageExtra(
        fileName: _extractFavoritePlainText(item),
      );
    }
  }

  Map<String, String> _parseExtraFromFavorite(FavoriteItem item) {
    final extra = item.messageExtra.trim();
    if (extra.isEmpty || !extra.startsWith('{') || !extra.endsWith('}')) {
      return {};
    }
    try {
      final map = jsonDecode(extra) as Map<String, dynamic>;
      final result = <String, String>{};
      for (final entry in map.entries) {
        result[entry.key] = entry.value?.toString() ?? '';
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  String _extractFavoriteContent(FavoriteItem item) {
    final preview = item.messagePreview.trim();
    if (preview.isNotEmpty) {
      return preview;
    }
    
    final content = item.messageContent.trim();
    if (content.isEmpty) {
      return '';
    }
    
    if (content.startsWith('{') && content.endsWith('}')) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return map['content']?.toString() ??
               map['text']?.toString() ??
               map['fileName']?.toString() ??
               content;
      } catch (_) {
        return content;
      }
    }
    
    return content;
  }

  String _extractFavoritePlainText(FavoriteItem item) {
    final preview = item.messagePreview.trim();
    if (preview.isNotEmpty) {
      return preview;
    }
    
    final content = item.messageContent.trim();
    if (content.isEmpty) {
      return '';
    }
    
    if (content.startsWith('{') && content.endsWith('}')) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return map['fileName']?.toString() ?? map['text']?.toString() ?? '';
      } catch (_) {
        return '';
      }
    }
    return content;
  }

  MessageType _toMessageType(int type) {
    return switch (type) {
      1 => MessageType.text,
      2 => MessageType.image,
      3 => MessageType.voice,
      4 => MessageType.video,
      5 => MessageType.file,
      6 => MessageType.location,
      8 => MessageType.sticker,
      9 => MessageType.custom,
      _ => MessageType.text,
    };
  }

  Widget _buildMessageBubble(Message message, ChatHistoryItem historyItem, FavoriteItem item) {
    final keyword = _getSearchKeyword();
    final isTextWithKeyword = message.type == MessageType.text && keyword.isNotEmpty;
    
    if (isTextWithKeyword) {
      return GestureDetector(
        onTap: () => _handleMessageTap(historyItem, item),
        onLongPress: () => _showItemMenu(historyItem, item),
        behavior: HitTestBehavior.translucent,
        child: _CustomTextMessageBubble(
          message: message,
          keyword: keyword,
        ),
      );
    }
    
    return GestureDetector(
      onTap: () => _handleMessageTap(historyItem, item),
      onLongPress: () => _showItemMenu(historyItem, item),
      behavior: HitTestBehavior.translucent,
      child: MessageBubbleFactory.build(
        message,
        strings: AppLocalizations.of(context),
        onRetryMessage: (_) {},
        onOpenMessage: (_) => _handleMessageTap(historyItem, item),
        onLongPressMessage: (message, offset) => _showItemMenu(historyItem, item),
        showOutgoingStatusFooter: false,
        highlightKeyword: keyword.isNotEmpty ? keyword : null,
        showFileName: true,
        onOpenLink: _handleLinkTap,
      ),
    );
  }

  void _handleMessageTap(ChatHistoryItem historyItem, FavoriteItem item) {
    if (historyItem.messageType == MessageType.file ||
        historyItem.messageType == MessageType.image ||
        historyItem.messageType == MessageType.video) {
      _openMediaAnchor(historyItem, item);
      return;
    }
    final message = _toMessage(item, historyItem);
    if (_isLinkMessage(message)) {
      _openLinkMessage(message);
      return;
    }
  }

  void _handleLinkTap(String url) {
    if (!mounted) {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).chatOpenFailed)),
      );
      return;
    }
    context.pushNamed(
      RouteNames.browser,
      extra: BrowserPageArgs(
        url: uri.toString(),
        title: AppLocalizations.of(context).chatMessageDetailTitle,
        source: 'message',
      ),
    );
  }

  bool _isLinkMessage(Message message) {
    if (message.type == MessageType.custom) {
      final customType = message.extra.customType?.trim().toUpperCase() ?? '';
      if (customType == 'LINK' ||
          customType == 'URL' ||
          customType == 'WEB_LINK') {
        return true;
      }
    }
    final content = message.content.trim();
    if (content.isNotEmpty) {
      final directUrl = RegExp(r'^https?:\/\/\S+$', caseSensitive: false);
      final wwwUrl = RegExp(r'^www\.\S+$', caseSensitive: false);
      if (directUrl.hasMatch(content) || wwwUrl.hasMatch(content)) {
        return true;
      }
      if (content.startsWith('{') && content.endsWith('}')) {
        try {
          final map = jsonDecode(content) as Map<String, dynamic>;
          final url = map['url']?.toString().trim() ?? '';
          if (url.isNotEmpty) {
            return true;
          }
        } catch (e) {
        debugPrint('[Favorites] operation failed: $e');
      }
      }
    }
    return false;
  }

  void _openLinkMessage(Message message) {
    final strings = AppLocalizations.of(context);
    String rawUrl = '';
    final content = message.content.trim();
    if (content.startsWith('{') && content.endsWith('}')) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        rawUrl = map['url']?.toString().trim() ?? '';
      } catch (e) {
        debugPrint('[Favorites] operation failed: $e');
      }
    }
    if (rawUrl.isEmpty && !content.startsWith('{')) {
      rawUrl = content;
    }
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatOpenFailed)),
      );
      return;
    }
    final normalized = rawUrl.startsWith('www.') ? 'https://$rawUrl' : rawUrl;
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatOpenFailed)),
      );
      return;
    }
    context.pushNamed(
      RouteNames.browser,
      extra: BrowserPageArgs(
        url: uri.toString(),
        title: strings.chatMessageDetailTitle,
        source: 'message',
      ),
    );
  }

  String _getSearchKeyword() {
    return _searched ? _currentKeyword : _searchController.text.trim();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loading || !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty || _searched) {
        _search(reset: false);
      } else {
        _loadMoreInitial();
      }
    }
  }

  Future<void> _loadMoreInitial() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final keyword = _searchController.text.trim();
      final tab = _filter.toFavoriteTab();
      
      final page = await ref.read(favoriteRepositoryProvider).getFavorites(
        keyword: keyword,
        tab: tab,
        pageNo: _pageNo + 1,
        pageSize: _pageSize,
      );
      
      if (!mounted) {
        return;
      }
      setState(() {
        _records = <FavoriteItem>[..._records, ...page.items];
        _pageNo = _pageNo + 1;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _changeFilter(_FavoriteFilter filter) async {
    if (_filter == filter) {
      return;
    }
    setState(() {
      _filter = filter;
      _records = const [];
      _pageNo = 1;
      _hasMore = true;
    });
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      await _search(reset: true);
    } else {
      await _loadInitialData();
    }
  }

  Future<void> _search({required bool reset}) async {
    final keyword = _searchController.text.trim();
    final hasActiveFilter = _filter != _FavoriteFilter.all;
    final shouldSearch = keyword.isNotEmpty || hasActiveFilter;
    if (!shouldSearch) {
      if (reset) {
        setState(() {
          _records = const [];
          _searched = false;
          _currentKeyword = '';
          _pageNo = 1;
          _hasMore = true;
        });
        await _loadInitialData();
      }
      return;
    }
    if (_loading) {
      return;
    }
    final nextPage = reset ? 1 : _pageNo + 1;
    final strings = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      if (reset) {
        _searched = true;
        _currentKeyword = keyword;
      }
    });
    try {
      final tab = _filter.toFavoriteTab();
      final page = await ref.read(favoriteRepositoryProvider).getFavorites(
        keyword: keyword,
        tab: tab,
        pageNo: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _records = reset ? page.items : <FavoriteItem>[..._records, ...page.items];
        _pageNo = nextPage;
        _hasMore = page.hasMore;
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
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty || _searched) {
      await _search(reset: true);
    } else {
      await _loadInitialData();
    }
  }

  void _resetFilters() {
    setState(() {
      _startTime = null;
      _endTime = null;
      _filter = _FavoriteFilter.all;
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
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty || _searched) {
      return;
    }
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _pageNo = 1;
      _hasMore = true;
    });
    try {
      final tab = _filter.toFavoriteTab();
      final page = await ref.read(favoriteRepositoryProvider).getFavorites(
        keyword: '',
        tab: tab,
        pageNo: 1,
        pageSize: _pageSize,
      );
      
      var items = page.items;
      if (_startTime != null || _endTime != null) {
        items = items.where((item) {
          final rawTime = item.sendTime.trim().isNotEmpty
              ? item.sendTime
              : item.favoriteTime;
          if (rawTime.isEmpty) {
            return true;
          }
          DateTime? date = DateTime.tryParse(
            rawTime.contains(' ') ? rawTime.replaceFirst(' ', 'T') : rawTime,
          );
          if (date == null) {
            final millis = int.tryParse(rawTime);
            if (millis != null && millis > 0) {
              date = DateTime.fromMillisecondsSinceEpoch(
                rawTime.length <= 10 ? millis * 1000 : millis,
              );
            }
          }
          if (date == null) {
            return true;
          }
          if (_startTime != null && date.isBefore(_startTime!)) {
            return false;
          }
          if (_endTime != null && date.isAfter(_endTime!.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        }).toList();
      }
      
      if (!mounted) {
        return;
      }
      setState(() {
        _records = items;
        _pageNo = 1;
        _hasMore = items.length >= _pageSize;
        _loading = false;
        _searched = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
    }
  }

  void _openMediaAnchor(ChatHistoryItem historyItem, FavoriteItem item) {
    final strings = AppLocalizations.of(context);
    final messageId = historyItem.messageId.trim();
    if (messageId.isEmpty || messageId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupFilesForwardUnsupported)),
      );
      return;
    }
    final contentData = _parseContentData(item);
    final fileId = contentData['fileId'] ?? '';
    final fileUrl = contentData['fileUrl']?.isNotEmpty == true
        ? contentData['fileUrl']!
        : (contentData['url'] ?? '');
    final fileName = contentData['fileName'] ?? '';
    final mimeType = contentData['mimeType']?.isNotEmpty == true
        ? contentData['mimeType']!
        : (contentData['fileType'] ?? '');
    final fileSize = int.tryParse(contentData['fileSize'] ?? contentData['size'] ?? '0') ?? 0;

    if (historyItem.messageType == MessageType.image) {
      _previewImageFile(fileId, fileUrl, fileName);
      return;
    }
    if (historyItem.messageType == MessageType.video) {
      context.pushNamed(
        RouteNames.chatVideoPlayer,
        extra: VideoPlayerRouteArgs(
          url: fileUrl,
          fileId: fileId,
          title: fileName,
        ),
      );
      return;
    }
    if (historyItem.messageType == MessageType.file) {
      context.pushNamed(
        RouteNames.filePreview,
        extra: FilePreviewRouteArgs(
          fileId: fileId.isNotEmpty ? fileId : messageId,
          fileName: fileName,
          mimeType: mimeType.isNotEmpty ? mimeType : 'application/octet-stream',
          fileSize: fileSize,
          messageId: messageId,
          chatId: null,
          sourceType: 'file',
        ),
      );
      return;
    }
  }

  Map<String, String> _parseContentData(FavoriteItem item) {
    final extraData = _parseExtraFromFavorite(item);
    if (extraData.isNotEmpty) {
      return extraData;
    }
    
    final content = item.messageContent.trim();
    if (content.isEmpty) {
      return {};
    }
    if (content.startsWith('{') && content.endsWith('}')) {
      try {
        final map = <String, String>{};
        final pairs = content
            .substring(1, content.length - 1)
            .split(',')
            .where((s) => s.contains(':'));
        for (final pair in pairs) {
          final parts = pair.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().replaceAll(_quoteCharPattern, '');
            final value = parts.sublist(1).join(':').trim().replaceAll(_quoteCharPattern, '');
            map[key] = value;
          }
        }
        return map;
      } catch (e) {
        debugPrint('[Favorites] operation failed: $e');
      }
    }
    return {};
  }

  Future<void> _previewImageFile(String fileId, String fileUrl, String fileName) async {
    try {
      final url = fileId.isNotEmpty
          ? (await ref.read(fileRepositoryProvider).getPresignedGetUrl(fileId: fileId)).toString()
          : fileUrl;
      if (!mounted || url.isEmpty) {
        return;
      }
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'favorite-image-preview',
        barrierColor: Colors.black,
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Material(
            color: Colors.black,
            child: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        url,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[Favorites] show menu failed: $e');
    }
  }

  Future<void> _showItemMenu(ChatHistoryItem historyItem, FavoriteItem item) async {
    final strings = AppLocalizations.of(context);
    final canDownload = _canDownloadMessageType(historyItem.messageType);
    final canForward = _canForwardMessageType(historyItem.messageType);

    final menuItems = <Widget>[];
    if (canDownload) {
      menuItems.add(
        ListTile(
          leading: const Icon(Icons.download_rounded),
          title: Text(strings.groupFilesActionDownload),
          onTap: () {
            Navigator.of(context).pop('download');
            _downloadItem(item);
          },
        ),
      );
    }
    if (canForward) {
      menuItems.add(
        ListTile(
          leading: const Icon(Icons.forward_rounded),
          title: Text(strings.groupFilesActionForward),
          onTap: () {
            Navigator.of(context).pop('forward');
            _forwardItem(item);
          },
        ),
      );
    }
    menuItems.add(
      ListTile(
        leading: const Icon(Icons.delete_outline_rounded),
        title: Text(strings.favoriteCancelAction),
        onTap: () {
          Navigator.of(context).pop('unfavorite');
          _unfavoriteItem(item);
        },
      ),
    );

    if (menuItems.isEmpty) {
      return;
    }

    await showModalBottomSheet<String>(
      context: context,
      builder: (dialogContext) {
        return SafeArea(
          child: Material(
            color: ThemeColors.scaffoldBg(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: menuItems,
            ),
          ),
        );
      },
    );
  }

  bool _canDownloadMessageType(MessageType type) {
    return type == MessageType.file ||
        type == MessageType.image ||
        type == MessageType.video ||
        type == MessageType.voice;
  }

  bool _canForwardMessageType(MessageType type) {
    return type != MessageType.voice &&
        type != MessageType.location &&
        type != MessageType.system;
  }

  Future<void> _downloadItem(FavoriteItem item) async {
    final strings = AppLocalizations.of(context);
    try {
      final contentData = _parseContentData(item);
      String fileId = contentData['fileId'] ?? '';
      final fileName = contentData['fileName'] ?? _contentText(strings, item);
      
      Uri uri;
      if (fileId.isNotEmpty) {
        uri = await ref.read(fileRepositoryProvider).getPresignedGetUrl(fileId: fileId);
      } else {
        final directUrl = contentData['url']?.isNotEmpty == true
            ? contentData['url']!
            : item.messageContent.trim();
        if (directUrl.isEmpty) {
          throw StateError('missing file id and url');
        }
        fileId = item.messageId;
        uri = Uri.parse(directUrl);
      }
      
      await ref.read(fileDownloadServiceProvider).download(uri, suggestedFileName: fileName);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupFilesDownloadStarted)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.groupFilesDownloadFailed)));
    }
  }

  void _forwardItem(FavoriteItem item) {
    final strings = AppLocalizations.of(context);
    final favoriteId = item.favoriteId.trim();
    if (favoriteId.isEmpty || favoriteId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.favoriteOpenFailed)),
      );
      return;
    }
    context.pushNamed(
      RouteNames.chatForwardTarget,
      extra: ForwardTargetRouteArgs(favoriteId: favoriteId),
    );
  }

  Future<void> _unfavoriteItem(FavoriteItem item) async {
    final strings = AppLocalizations.of(context);
    if (item.favoriteId.trim().isEmpty || item.favoriteId == '0') {
      _showNotice(strings.favoriteOpenFailed);
      return;
    }
    try {
      await ref.read(favoritesControllerProvider.notifier).removeFavorite(item);
      if (!mounted) {
        return;
      }
      setState(() {
        _records = _records.where((r) => r.favoriteId != item.favoriteId).toList();
      });
      _showNotice(strings.favoriteCancelSuccess);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showNotice(strings.operationFailed(error.toString()));
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  String _contentText(AppLocalizations strings, FavoriteItem item) {
    if (item.messagePreview.isNotEmpty) {
      return item.messagePreview;
    }
    
    final content = item.messageContent.trim();
    if (content.isNotEmpty) {
      final contentData = _parseContentData(item);
      if (contentData.containsKey('fileName')) {
        return contentData['fileName']!;
      }
      if (contentData.containsKey('text')) {
        return contentData['text']!;
      }
    }
    
    return switch (item.messageType) {
      2 => strings.chatHistoryPreviewImage,
      3 => strings.chatHistoryPreviewVoice,
      4 => strings.chatHistoryPreviewVideo,
      5 => strings.chatHistoryPreviewFile,
      6 => strings.chatHistoryPreviewLocation,
      8 => strings.chatHistoryPreviewSticker,
      9 => strings.chatHistoryPreviewMessage,
      _ => strings.chatHistoryPreviewMessage,
    };
  }

  Color _avatarColorFor(String seed) {
    return getUserAvatarColor(seed);
  }

  Object? _safeParseJson(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is Map<String, dynamic> || raw is List) {
      return raw;
    }
    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    if (!((text.startsWith('{') && text.endsWith('}')) ||
        (text.startsWith('[') && text.endsWith(']')))) {
      return null;
    }
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
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
          color: ThemeColors.surfaceDim(context),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label $value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ),
            AppIcon(
              AppIconKind.chevronDown,
              size: 16,
              color: ThemeColors.textSecondary(context),
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
            AppIcon(
              AppIconKind.history,
              size: 56,
              color: ThemeColors.emptyText(context),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: ThemeColors.textSecondary(context),
              ),
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
    if (keyword.isEmpty || text.isEmpty) {
      return RichText(
        text: TextSpan(
          children: buildEmojiInlineSpans(
            text: text,
            textStyle: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: ThemeColors.chatBubbleIncomingText(context),
            ),
          ),
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: _buildHighlightedEmojiSpans(context),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedEmojiSpans(BuildContext context) {
    final normalized = normalizeEmojiDisplayText(text);
    final spans = <InlineSpan>[];
    final lowerKeyword = keyword.toLowerCase();

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

    for (final segment in segments) {
      if (segment.isEmoji) {
        final assets = ChatEmojiCatalog.candidateAssetsFor(
            segment.emojiToken ?? segment.text);
        if (assets.isNotEmpty) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: ChatEmojiAssetImage(assets: assets, size: 20),
            ),
          ));
        } else {
          spans.add(TextSpan(
              text: segment.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: ThemeColors.chatBubbleIncomingText(context),
              )));
        }
      } else {
        final lowerSource = segment.text.toLowerCase();
        var searchStart = 0;
        while (true) {
          final idx = lowerSource.indexOf(lowerKeyword, searchStart);
          if (idx < 0) {
            if (searchStart < segment.text.length) {
              spans.add(TextSpan(
                  text: segment.text.substring(searchStart),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: ThemeColors.chatBubbleIncomingText(context),
                  )));
            }
            break;
          }
          if (idx > searchStart) {
            spans.add(TextSpan(
                text: segment.text.substring(searchStart, idx),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: ThemeColors.chatBubbleIncomingText(context),
                )));
          }
          spans.add(TextSpan(
            text: segment.text.substring(idx, idx + keyword.length),
            style: TextStyle(
              color: ThemeColors.highlightText(context),
              backgroundColor: ThemeColors.highlightBg(context),
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

class _CustomTextMessageBubble extends StatelessWidget {
  const _CustomTextMessageBubble({
    required this.message,
    required this.keyword,
  });

  final Message message;
  final String keyword;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.isOutgoing;
    final alignment =
        isOutgoing ? Alignment.centerRight : Alignment.centerLeft;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: alignment,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isOutgoing
                ? ThemeColors.chatBubbleOutgoing(context)
                : ThemeColors.chatBubbleIncoming(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _HighlightedContent(
            text: message.content,
            keyword: keyword,
          ),
        ),
      ),
    );
  }
}

class _EmojiSegment {
  final String text;
  final bool isEmoji;
  final String? emojiToken;

  _EmojiSegment({required this.text, required this.isEmoji, this.emojiToken});
}

enum _FavoriteFilter {
  all(null),
  text('text'),
  image('image'),
  video('video'),
  file('file'),
  link('link');

  const _FavoriteFilter(this.apiValue);

  final String? apiValue;

  String label(AppLocalizations strings) {
    return switch (this) {
      _FavoriteFilter.all => strings.groupHistoryFilterAll,
      _FavoriteFilter.text => strings.groupHistoryFilterText,
      _FavoriteFilter.image => strings.groupHistoryFilterImage,
      _FavoriteFilter.video => strings.groupHistoryFilterVideo,
      _FavoriteFilter.file => strings.groupHistoryFilterFile,
      _FavoriteFilter.link => strings.groupHistoryFilterLink,
    };
  }

  String toFavoriteTab() {
    return switch (this) {
      _FavoriteFilter.all => 'default',
      _FavoriteFilter.text => 'normal',
      _FavoriteFilter.image => 'media',
      _FavoriteFilter.video => 'media',
      _FavoriteFilter.file => 'file',
      _FavoriteFilter.link => 'default',
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? ThemeColors.activeBg(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? ThemeColors.categoryActiveText(context)
                  : ThemeColors.categoryInactiveText(context),
            ),
          ),
        ),
      ),
    );
  }
}
