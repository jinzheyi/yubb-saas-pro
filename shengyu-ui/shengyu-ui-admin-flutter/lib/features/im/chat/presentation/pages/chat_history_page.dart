import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/file_preview_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_bubble_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/providers/file_preview_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

// 预编译正则表达式，避免循环内重复构造
final _historyQuoteCharPattern = RegExp(r'''["']''');

class ChatHistoryPage extends ConsumerStatefulWidget {
  const ChatHistoryPage({
    super.key,
    this.chatArgs,
    this.groupArgs,
  })  : assert(chatArgs != null || groupArgs != null, 'chatArgs or groupArgs must be provided'),
        assert(!(chatArgs != null && groupArgs != null), 'only one of chatArgs or groupArgs can be provided');

  final ChatEntryArgs? chatArgs;
  final GroupSettingDetailArgs? groupArgs;

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
  String? _chatId;
  _HistoryFilter _filter = _HistoryFilter.all;
  String _currentKeyword = '';

  // Voice playback state
  String? _activePlayingVoiceMessageId;
  String? _activePausedVoiceMessageId;
  int _activeVoicePlaybackProgressMs = 0;
  int _activeVoicePlaybackDurationMs = 0;

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
        title: Text(strings.chatHistoryTitle),
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
                        hintText: strings.chatHistorySearchPlaceholder,
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
          for (final filter in _HistoryFilter.values)
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
              backgroundColor: ThemeColors.scaffoldBg(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
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
            : strings.chatHistoryEmptyIdle,
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
                  color: ThemeColors.emptyText(context),
                ),
              ),
            ),
          );
        }
        final item = _records[index];
        final message = _toMessage(item);
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
                    name: item.senderName,
                    color: _avatarColorFor(item.senderId),
                    avatarUrl: item.senderAvatar,
                    size: 40,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.messageType == MessageType.system
                              ? strings.chatGroupSystemSender
                              : (item.senderName.trim().isEmpty
                                  ? strings.chatHistoryUnknownUser
                                  : item.senderName.trim()),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ThemeColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(strings, item.sentAt),
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
                child: _buildMessageBubble(message, item),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData? _messageTypeIcon(MessageType type) {
    return switch (type) {
      MessageType.image => Icons.image_outlined,
      MessageType.video => Icons.videocam_outlined,
      MessageType.file => Icons.attach_file_outlined,
      MessageType.voice => Icons.mic_outlined,
      MessageType.location => Icons.location_on_outlined,
      MessageType.emoji => Icons.emoji_emotions_outlined,
      MessageType.sticker => Icons.sticky_note_2_outlined,
      MessageType.contactCard => Icons.person_outlined,
      _ => null,
    };
  }

  Message _toMessage(ChatHistoryItem item) {
    final extra = _parseMessageExtra(item);
    return Message(
      messageId: item.messageId,
      chatId: item.chatId,
      senderId: item.senderId,
      senderName: item.senderName,
      senderAvatar: item.senderAvatar,
      type: item.messageType,
      status: MessageStatus.delivered,
      content: item.content,
      sentAt: item.sentAt ?? DateTime.now(),
      isOutgoing: false,
      sequence: item.sequence,
      extra: extra,
    );
  }

  MessageExtra _parseMessageExtra(ChatHistoryItem item) {
    final extraData = _parseExtraFromItem(item);
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
        // 聊天记录页不显示未读红点
        voicePlayed: true,
      );
    }

    final content = item.content.trim();
    if (content.isEmpty || !content.startsWith('{') || !content.endsWith('}')) {
      return MessageExtra(
        fileName: _extractPlainText(item),
        voicePlayed: true,
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
        voicePlayed: true,
      );
    } catch (_) {
      return MessageExtra(
        fileName: _extractPlainText(item),
        voicePlayed: true,
      );
    }
  }

  Map<String, String> _parseExtraFromItem(ChatHistoryItem item) {
    final extra = item.extra?.trim() ?? '';
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

  String _extractPlainText(ChatHistoryItem item) {
    final content = item.content.trim();
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

  Widget _buildMessageBubble(Message message, ChatHistoryItem item) {
    final keyword = _getSearchKeyword();
    final isTextWithKeyword = message.type == MessageType.text && keyword.isNotEmpty;
    final isVoiceMessage = message.type == MessageType.voice;

    if (isTextWithKeyword) {
      return GestureDetector(
        onTap: () => _handleMessageTap(item),
        onLongPress: () => _showItemMenu(item),
        behavior: HitTestBehavior.translucent,
        child: _CustomTextMessageBubble(
          message: message,
          keyword: keyword,
        ),
      );
    }

    if (isVoiceMessage) {
      final messageKey = message.messageId;
      final isPlaying = messageKey.isNotEmpty && _activePlayingVoiceMessageId == messageKey;
      final isPaused = messageKey.isNotEmpty && _activePausedVoiceMessageId == messageKey;
      final progressMs = (isPlaying || isPaused) ? _activeVoicePlaybackProgressMs : 0;
      final durationMs = (isPlaying || isPaused) ? _activeVoicePlaybackDurationMs : 0;
      return MessageBubbleFactory.build(
        message,
        onRetryMessage: (_) {},
        onOpenMessage: (_) => _handleMessageTap(item),
        onPauseMessage: (_) => _pauseVoiceMessage(message),
        onResumeMessage: (_) => _resumeVoiceMessage(message),
        onReplayMessage: (_) => _replayVoiceMessage(message),
        voiceIsPlaying: isPlaying,
        voiceIsPaused: isPaused,
        voicePlaybackProgressMs: progressMs,
        voicePlaybackDurationMs: durationMs,
        onLongPressMessage: (_, __) => _showItemMenu(item),
        showOutgoingStatusFooter: false,
      );
    }

    return GestureDetector(
      onTap: () => _handleMessageTap(item),
      onLongPress: () => _showItemMenu(item),
      behavior: HitTestBehavior.translucent,
      child: MessageBubbleFactory.build(
        message,
        onRetryMessage: (_) {},
        onOpenMessage: (_) => _handleMessageTap(item),
        onLongPressMessage: (_, __) => _showItemMenu(item),
        showOutgoingStatusFooter: false,
        highlightKeyword: keyword.isNotEmpty ? keyword : null,
        showFileName: true,
        onOpenLink: _handleLinkTap,
      ),
    );
  }

  void _handleMessageTap(ChatHistoryItem item) {
    if (item.messageType == MessageType.file ||
        item.messageType == MessageType.image ||
        item.messageType == MessageType.video) {
      _openMediaAnchor(item);
      return;
    }
    if (item.messageType == MessageType.voice) {
      final message = _toMessage(item);
      _handleVoiceMessageTap(message);
      return;
    }
    final message = _toMessage(item);
    if (_isLinkMessage(message)) {
      _openLinkMessage(message);
      return;
    }
  }

  void _handleVoiceMessageTap(Message message) {
    final messageKey = message.messageId;
    if (messageKey.isNotEmpty && _activePlayingVoiceMessageId == messageKey) {
      _pauseVoiceMessage(message);
    } else if (messageKey.isNotEmpty && _activePausedVoiceMessageId == messageKey) {
      _resumeVoiceMessage(message);
    } else {
      _playVoiceMessage(message);
    }
  }

  Future<void> _playVoiceMessage(Message message) async {
    if (!mounted) return;
    final playback = ref.read(audioPlaybackServiceProvider);
    final messageKey = message.messageId;
    StreamSubscription<Duration>? positionSub;
    StreamSubscription<PlayerState>? stateSub;
    try {
      if (messageKey.isNotEmpty && _activePlayingVoiceMessageId == messageKey) {
        await playback.pause();
      } else if (_activePlayingVoiceMessageId != null ||
          _activePausedVoiceMessageId != null) {
        await playback.stop();
      }
      final url = message.extra.fileUrl;
      if (url == null || url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).chatVoicePlayUrlFailed)),
          );
        }
        return;
      }
      await playback.setUrl(url);
      if (!mounted) return;
      positionSub = playback.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() {
          _activeVoicePlaybackProgressMs = pos.inMilliseconds;
        });
      });
      stateSub = playback.playerStateStream.listen((state) {
        if (!mounted) return;
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          positionSub?.cancel();
          stateSub?.cancel();
          setState(() {
            _activePlayingVoiceMessageId = null;
            _activePausedVoiceMessageId = null;
            _activeVoicePlaybackProgressMs = 0;
          });
        } else if (!state.playing && _activePlayingVoiceMessageId == messageKey) {
          setState(() {
            _activePlayingVoiceMessageId = null;
            _activePausedVoiceMessageId = messageKey;
          });
        }
      });
      setState(() {
        _activePlayingVoiceMessageId = messageKey;
        _activePausedVoiceMessageId = null;
        _activeVoicePlaybackProgressMs = 0;
        _activeVoicePlaybackDurationMs =
            message.extra.durationMs ??
            ((message.extra.duration ?? 1).clamp(1, 60) * 1000);
      });
      await playback.play();
    } catch (_) {
      positionSub?.cancel();
      stateSub?.cancel();
      if (mounted) {
        setState(() {
          _activePlayingVoiceMessageId = null;
          _activePausedVoiceMessageId = null;
          _activeVoicePlaybackProgressMs = 0;
        });
      }
    }
  }

  Future<void> _pauseVoiceMessage(Message message) async {
    final messageKey = message.messageId;
    if (messageKey.isEmpty || _activePlayingVoiceMessageId != messageKey) {
      return;
    }
    final playback = ref.read(audioPlaybackServiceProvider);
    await playback.pause();
  }

  Future<void> _resumeVoiceMessage(Message message) async {
    final messageKey = message.messageId;
    if (messageKey.isEmpty || _activePausedVoiceMessageId != messageKey) {
      return;
    }
    final playback = ref.read(audioPlaybackServiceProvider);
    await playback.play();
    if (mounted) {
      setState(() {
        _activePlayingVoiceMessageId = messageKey;
        _activePausedVoiceMessageId = null;
      });
    }
  }

  Future<void> _replayVoiceMessage(Message message) async {
    final playback = ref.read(audioPlaybackServiceProvider);
    await playback.stop();
    if (!mounted) return;
    setState(() {
      _activePlayingVoiceMessageId = null;
      _activePausedVoiceMessageId = null;
      _activeVoicePlaybackProgressMs = 0;
    });
    await _playVoiceMessage(message);
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
          debugPrint('[ChatHistory] parse link message failed: $e');
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
        debugPrint('[ChatHistory] parse json failed: $e');
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
      final effectiveChatId = await _resolveChatId();
      final nextPage = _pageNo + 1;
      final records = await ref.read(messageRepositoryProvider).searchChatHistory(
            chatId: effectiveChatId,
            keyword: '',
            category: _filter.apiValue,
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
        _records = <ChatHistoryItem>[..._records, ...records];
        _pageNo = nextPage;
        _hasMore = records.length >= _pageSize;
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

  Future<void> _changeFilter(_HistoryFilter filter) async {
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
    final hasActiveFilter = _filter != _HistoryFilter.all;
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
      final effectiveChatId = await _resolveChatId();
      final records = await ref.read(messageRepositoryProvider).searchChatHistory(
            chatId: effectiveChatId,
            keyword: keyword,
            category: _filter.apiValue,
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

  Future<String> _resolveChatId() async {
    if (_chatId != null && _chatId!.isNotEmpty) {
      return _chatId!;
    }
    if (widget.groupArgs != null) {
      final resolvedChatId = await ref
          .read(groupSettingsRepositoryProvider)
          .ensureGroupChatId(widget.groupArgs!.groupId);
      _chatId = resolvedChatId;
      return resolvedChatId;
    }
    return widget.chatArgs!.chatId;
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
      _filter = _HistoryFilter.all;
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
      final effectiveChatId = await _resolveChatId();
      final records = await ref.read(messageRepositoryProvider).searchChatHistory(
            chatId: effectiveChatId,
            keyword: '',
            category: _filter.apiValue,
            startTime: _startTime == null
                ? null
                : '${DateFormat('yyyy-MM-dd').format(_startTime!)} 00:00:00',
            endTime: _endTime == null
                ? null
                : '${DateFormat('yyyy-MM-dd').format(_endTime!)} 23:59:59',
            pageNo: 1,
            pageSize: _pageSize,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _records = records;
        _pageNo = 1;
        _hasMore = records.length >= _pageSize;
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

  void _openChatAnchor(ChatHistoryItem item) {
    if (item.messageId.trim().isEmpty || item.messageId.trim() == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).chatHistoryLocateFailed),
        ),
      );
      return;
    }
    final conversationType = widget.groupArgs != null
        ? ConversationType.group
        : widget.chatArgs!.conversationType;
    final targetId = widget.groupArgs != null
        ? widget.groupArgs!.groupId
        : widget.chatArgs!.targetId;
    final title = widget.groupArgs != null
        ? widget.groupArgs!.groupName
        : widget.chatArgs!.title;

    context.pushNamed(
      RouteNames.chat,
      extra: ChatEntryArgs(
        chatId: _chatId ?? widget.chatArgs?.chatId ?? '',
        conversationType: conversationType,
        targetId: targetId,
        title: title,
        entryMode: ChatEntryMode.anchor,
        anchorSequence: item.sequence.trim().isNotEmpty ? item.sequence : null,
        anchorMessageId: item.messageId,
        highlightedMessageId: item.messageId,
      ),
    );
  }

  void _openMediaAnchor(ChatHistoryItem item) {
    final strings = AppLocalizations.of(context);
    final messageId = item.messageId.trim();
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

    if (item.messageType == MessageType.image) {
      _previewImageFile(fileId, fileUrl, fileName);
      return;
    }
    if (item.messageType == MessageType.video) {
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
    if (item.messageType == MessageType.file) {
      context.pushNamed(
        RouteNames.filePreview,
        extra: FilePreviewRouteArgs(
          fileId: fileId.isNotEmpty ? fileId : messageId,
          fileName: fileName,
          mimeType: mimeType.isNotEmpty ? mimeType : 'application/octet-stream',
          fileSize: fileSize,
          messageId: messageId,
          chatId: _chatId,
          sourceType: 'file',
        ),
      );
      return;
    }
  }

  Map<String, String> _parseContentData(ChatHistoryItem item) {
    final content = item.content.trim();
    
    final extraData = _parseExtraFromItem(item);
    if (extraData.isNotEmpty) {
      return extraData;
    }
    
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
            final key = parts[0].trim().replaceAll(_historyQuoteCharPattern, '');
            final value = parts.sublist(1).join(':').trim().replaceAll(_historyQuoteCharPattern, '');
            map[key] = value;
          }
        }
        return map;
      } catch (e) {
        debugPrint('[ChatHistory] parse json failed: $e');
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
        barrierLabel: 'history-image-preview',
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
      debugPrint('[ChatHistory] show menu failed: $e');
    }
  }

  Future<void> _showItemMenu(ChatHistoryItem item) async {
    final strings = AppLocalizations.of(context);
    final canDownload = _canDownloadMessageType(item.messageType);
    final canForward = _canForwardMessageType(item.messageType);

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
        leading: const Icon(Icons.arrow_back_rounded),
        title: const Text('定位到聊天位置'),
        onTap: () {
          Navigator.of(context).pop('locate');
          _openChatAnchor(item);
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

  Future<void> _downloadItem(ChatHistoryItem item) async {
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
            : item.content.trim();
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

  void _forwardItem(ChatHistoryItem item) {
    final strings = AppLocalizations.of(context);
    final messageId = item.messageId.trim();
    if (messageId.isEmpty || messageId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupFilesForwardUnsupported)),
      );
      return;
    }
    context.pushNamed(
      RouteNames.chatForwardTarget,
      extra: ForwardTargetRouteArgs(
        messageIds: <String>[messageId],
        initialForwardType: 1,
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
      final contentData = _parseContentData(item);
      if (contentData.containsKey('fileName')) {
        return contentData['fileName']!;
      }
      if (contentData.containsKey('text')) {
        return contentData['text']!;
      }
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
                style: TextStyle(fontSize: 13, color: ThemeColors.textPrimary(context)),
              ),
            ),
            AppIcon(
              AppIconKind.chevronDown,
              size: 16,
              color: ThemeColors.chevronColor(context),
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
              style: TextStyle(fontSize: 15, color: ThemeColors.emptyText(context)),
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
              color: ThemeColors.textPrimary(context),
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
    final defaultTextColor = ThemeColors.textPrimary(context);

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
                color: defaultTextColor,
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
                    color: defaultTextColor,
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
                  color: defaultTextColor,
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
            color: isOutgoing ? const Color(0xFF246BFD) : ThemeColors.chatBubbleIncoming(context),
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

enum _HistoryFilter {
  all(null),
  text('text'),
  image('image'),
  video('video'),
  file('file'),
  link('link');

  const _HistoryFilter(this.apiValue);

  final String? apiValue;

  String label(AppLocalizations strings) {
    return switch (this) {
      _HistoryFilter.all => strings.groupHistoryFilterAll,
      _HistoryFilter.text => strings.groupHistoryFilterText,
      _HistoryFilter.image => strings.groupHistoryFilterImage,
      _HistoryFilter.video => strings.groupHistoryFilterVideo,
      _HistoryFilter.file => strings.groupHistoryFilterFile,
      _HistoryFilter.link => strings.groupHistoryFilterLink,
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
            color: selected ? const Color(0xFF246BFD) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : ThemeColors.categoryInactiveText(context),
            ),
          ),
        ),
      ),
    );
  }
}
