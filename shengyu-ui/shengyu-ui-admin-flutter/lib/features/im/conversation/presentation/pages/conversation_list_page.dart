import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/states/conversation_list_state.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/widgets/conversation_tile.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_empty_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_loading_view.dart';

class ConversationListPage extends ConsumerStatefulWidget {
  const ConversationListPage({super.key});

  @override
  ConsumerState<ConversationListPage> createState() =>
      _ConversationListPageState();
}

class _ConversationListPageState extends ConsumerState<ConversationListPage>
    with WidgetsBindingObserver {
  static const _foregroundSyncCooldownMs = 1500;
  static const _foregroundSyncStaleMs = 5000;
  static const _foregroundSyncAfterHideMs = 1200;
  static const _manualRefreshCooldownMs = 4000;
  static const _manualRefreshFreshSkipMs = 10000;
  static const _manualRefreshBackoffBaseMs = 1000;
  static const _manualRefreshBackoffMaxMs = 30000;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  _ConversationCategory _activeCategory = _ConversationCategory.latest;
  bool _isPinnedFolded = true;
  bool _refreshing = false;
  bool _inlineNoticeVisible = false;
  String _inlineNoticeText = '';
  String _suppressNextClickChatId = '';
  Timer? _inlineNoticeTimer;

  int _lastConversationSyncAt = 0;
  int _lastManualRefreshAt = 0;
  int _manualRefreshBlockedUntil = 0;
  int _refreshFailureCount = 0;
  int _lastOnShowRefreshAt = 0;
  int _lastPageHideAt = 0;

  static const _categories = <_ConversationCategoryItem>[
    _ConversationCategoryItem(
      category: _ConversationCategory.latest,
      icon: AppIconKind.history,
      color: Color(0xFF666666),
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.direct,
      icon: AppIconKind.personOutline,
      color: Color(0xFF666666),
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.group,
      icon: AppIconKind.groupsOutline,
      color: Color(0xFF666666),
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.atMe,
      icon: AppIconKind.at,
      color: Color(0xFF666666),
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.muted,
      icon: AppIconKind.muteOff,
      color: Color(0xFF666666),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      final error = await ref
          .read(conversationListControllerProvider.notifier)
          .load();
      if (error == null) {
        _markConversationSynced();
      }
      await _consumeGroupRemovalNotice();
      await _syncOnForegroundIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inlineNoticeTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_consumeGroupRemovalNotice());
      unawaited(_syncOnForegroundIfNeeded());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lastPageHideAt = DateTime.now().millisecondsSinceEpoch;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(conversationRealtimeBindingProvider);
    final strings = AppLocalizations.of(context);
    final state = ref.watch(conversationListControllerProvider);
    final filteredConversations = _applyFilter(state.conversations);
    final pinnedConversations = filteredConversations
        .where((item) => item.isPinned)
        .toList();
    final normalConversations = filteredConversations
        .where((item) => !item.isPinned)
        .toList();
    final displayedPinned = _isPinnedFolded && pinnedConversations.length > 5
        ? pinnedConversations.take(5).toList()
        : pinnedConversations;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.conversationTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF202531),
                          ),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: AppIconKind.sync,
                        onTap: _handleSyncBadge,
                      ),
                      const SizedBox(width: 16),
                      _HeaderIconButton(
                        icon: AppIconKind.qr,
                        onTap: _handleScan,
                      ),
                      const SizedBox(width: 16),
                      _HeaderIconButton(
                        icon: AppIconKind.groupAdd,
                        onTap: _handleInitiateGroup,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _handleSearch,
                          child: const AppIcon(
                            AppIconKind.search,
                            size: 16,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF202531),
                            ),
                            decoration: InputDecoration(
                              hintText: strings.searchHint,
                              border: InputBorder.none,
                              isCollapsed: true,
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF98A1B2),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _handleSearch(),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty)
                          InkWell(
                            onTap: _clearConversationFilter,
                            child: const AppIcon(
                              AppIconKind.close,
                              size: 16,
                              color: Color(0xFF98A1B2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final item in _categories)
                    _CategoryButton(
                      item: item,
                      active: _activeCategory == item.category,
                      label: item.category.label(strings),
                      onTap: () {
                        setState(() {
                          _activeCategory = item.category;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_inlineNoticeVisible)
              Container(
                color: const Color(0xFFEAF2FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _inlineNoticeText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF246BFD),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _hideInlineNotice,
                      child: const AppIcon(
                        AppIconKind.close,
                        size: 16,
                        color: Color(0xFF98A1B2),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: switch (state.status) {
                  ConversationListStatus.initial ||
                  ConversationListStatus.loading => const AppLoadingView(),
                  ConversationListStatus.failed => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.5,
                        child: AppErrorView(
                          error: state.error,
                          onRetry: _reloadConversations,
                        ),
                      ),
                    ],
                  ),
                  ConversationListStatus.ready => _buildConversationBody(
                    context: context,
                    strings: strings,
                    pinnedConversations: displayedPinned,
                    allPinnedCount: pinnedConversations.length,
                    normalConversations: normalConversations,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationBody({
    required BuildContext context,
    required AppLocalizations strings,
    required List<Conversation> pinnedConversations,
    required int allPinnedCount,
    required List<Conversation> normalConversations,
  }) {
    if (pinnedConversations.isEmpty && normalConversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: AppEmptyView(message: strings.emptyConversation),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (pinnedConversations.isNotEmpty) ...[
          Container(
            color: const Color(0xFFF7F8FB),
            child: Column(
              children: [
                for (var index = 0; index < pinnedConversations.length; index++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              index == pinnedConversations.length - 1 &&
                                  allPinnedCount <= 5
                              ? Colors.transparent
                              : const Color(0xFFF0F2F6),
                        ),
                      ),
                    ),
                    child: ConversationTile(
                      conversation: pinnedConversations[index],
                      highlightPinned: true,
                      onTap: () =>
                          _handleConversationTap(pinnedConversations[index]),
                      onLongPressStart: (details) => _showConversationMenuAt(
                        pinnedConversations[index],
                        details.globalPosition,
                      ),
                      onSecondaryTapDown: (details) => _showConversationMenuAt(
                        pinnedConversations[index],
                        details.globalPosition,
                      ),
                      onMouseLongPress: (position) => _showConversationMenuAt(
                        pinnedConversations[index],
                        position,
                        suppressNextTap: true,
                      ),
                    ),
                  ),
                if (allPinnedCount > 5)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isPinnedFolded = !_isPinnedFolded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isPinnedFolded ? '查看更多' : '收起',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF697386),
                            ),
                          ),
                          const SizedBox(width: 4),
                          AppIcon(
                            _isPinnedFolded
                                ? AppIconKind.chevronDown
                                : AppIconKind.chevronUp,
                            size: 14,
                            color: const Color(0xFF98A1B2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        Container(
          color: Colors.white,
          child: normalConversations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: AppEmptyView(message: strings.emptyConversation),
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < normalConversations.length;
                      index++
                    )
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: index == normalConversations.length - 1
                                  ? Colors.transparent
                                  : const Color(0xFFF0F2F6),
                            ),
                          ),
                        ),
                        child: ConversationTile(
                          conversation: normalConversations[index],
                          onTap: () => _handleConversationTap(
                            normalConversations[index],
                          ),
                          onLongPressStart: (details) =>
                              _showConversationMenuAt(
                                normalConversations[index],
                                details.globalPosition,
                              ),
                          onSecondaryTapDown: (details) =>
                              _showConversationMenuAt(
                                normalConversations[index],
                                details.globalPosition,
                              ),
                          onMouseLongPress: (position) =>
                              _showConversationMenuAt(
                                normalConversations[index],
                                position,
                                suppressNextTap: true,
                              ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  List<Conversation> _applyFilter(List<Conversation> conversations) {
    final keyword = _searchController.text.trim().toLowerCase();
    return conversations.where((conversation) {
      final categoryMatch = switch (_activeCategory) {
        _ConversationCategory.latest => true,
        _ConversationCategory.direct =>
          conversation.conversationType == ConversationType.direct,
        _ConversationCategory.group =>
          conversation.conversationType == ConversationType.group,
        _ConversationCategory.atMe => conversation.lastMessageHasAtMe,
        _ConversationCategory.muted => conversation.isMuted,
      };
      if (!categoryMatch) {
        return false;
      }
      if (keyword.isEmpty) {
        return true;
      }
      final title = conversation.title.trim().toLowerCase();
      final preview = conversation.lastMessagePreview.trim().toLowerCase();
      return title.contains(keyword) || preview.contains(keyword);
    }).toList();
  }

  Future<void> _handleRefresh() async {
    if (_refreshing) {
      return;
    }
    _refreshing = true;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      if (_manualRefreshBlockedUntil > now) {
        return;
      }
      if (now - _lastManualRefreshAt < _manualRefreshCooldownMs) {
        return;
      }
      _lastManualRefreshAt = now;
      if (_shouldSkipManualRefreshBecauseFresh(now)) {
        return;
      }
      final error = await ref
          .read(conversationListControllerProvider.notifier)
          .syncIncrementally();
      if (error == null) {
        _markConversationSynced();
        _refreshFailureCount = 0;
        _manualRefreshBlockedUntil = 0;
        return;
      }
      _applyRefreshBackoff(error);
    } finally {
      _refreshing = false;
    }
  }

  void _reloadConversations() {
    unawaited(() async {
      final error = await ref
          .read(conversationListControllerProvider.notifier)
          .load();
      if (error == null) {
        _markConversationSynced();
      }
    }());
  }

  void _clearConversationFilter() {
    _searchController.clear();
    setState(() {});
  }

  void _handleSearch() {
    _searchFocusNode.unfocus();
    context.pushNamed(
      RouteNames.globalChatSearch,
      extra: _searchController.text.trim(),
    );
  }

  void _handleSyncBadge() {
    unawaited(() async {
      final error = await ref
          .read(conversationListControllerProvider.notifier)
          .syncIncrementally();
      if (error == null) {
        _markConversationSynced();
      }
    }());
  }

  void _handleScan() {
    context.pushNamed(RouteNames.scan);
  }

  void _handleInitiateGroup() {
    context.pushNamed(RouteNames.initiateGroup);
  }

  void _showInlineNotice(String text) {
    _inlineNoticeTimer?.cancel();
    setState(() {
      _inlineNoticeText = text;
      _inlineNoticeVisible = true;
    });
    _inlineNoticeTimer = Timer(const Duration(seconds: 5), _hideInlineNotice);
  }

  void _hideInlineNotice() {
    if (!mounted) {
      return;
    }
    setState(() {
      _inlineNoticeVisible = false;
      _inlineNoticeText = '';
    });
  }

  Future<void> _handleConversationTap(Conversation conversation) async {
    if (_suppressNextClickChatId.isNotEmpty &&
        _suppressNextClickChatId == conversation.chatId) {
      _suppressNextClickChatId = '';
      return;
    }
    await _openConversation(conversation);
  }

  Future<void> _openConversation(Conversation conversation) async {
    ref
        .read(conversationListControllerProvider.notifier)
        .markConversationRead(conversation.chatId);
    unawaited(
      ref
          .read(conversationListControllerProvider.notifier)
          .markConversationReadRemotely(conversation.chatId),
    );
    if (!mounted) {
      return;
    }
    context.pushNamed(
      RouteNames.chat,
      extra: ChatEntryArgs.latest(
        chatId: conversation.chatId,
        conversationType: conversation.conversationType,
        targetId: conversation.targetId,
        title: conversation.title,
      ),
    );
  }

  Future<void> _showConversationMenuAt(
    Conversation conversation,
    Offset globalPosition, {
    bool suppressNextTap = false,
  }) async {
    if (suppressNextTap) {
      _suppressNextClickChatId = conversation.chatId;
    }
    final strings = AppLocalizations.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showMenu<_ConversationMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<_ConversationMenuAction>(
          enabled: false,
          height: 36,
          child: Text(
            conversation.title.trim().isEmpty
                ? conversation.chatId
                : conversation.title.trim(),
            style: const TextStyle(fontSize: 13, color: Color(0xFF697386)),
          ),
        ),
        PopupMenuItem<_ConversationMenuAction>(
          value: _ConversationMenuAction.pin,
          child: Text(
            conversation.isPinned ? '取消置顶' : strings.groupSettingsPin,
          ),
        ),
        PopupMenuItem<_ConversationMenuAction>(
          value: _ConversationMenuAction.unread,
          child: Text(conversation.unreadCount > 0 ? '标为已读' : '标为未读'),
        ),
        const PopupMenuItem<_ConversationMenuAction>(
          value: _ConversationMenuAction.delete,
          child: Text('删除会话', style: TextStyle(color: Color(0xFFFF4B4B))),
        ),
      ],
    );
    if (action == null || !mounted) {
      return;
    }
    final controller = ref.read(conversationListControllerProvider.notifier);
    try {
      switch (action) {
        case _ConversationMenuAction.pin:
          await ref
              .read(conversationRepositoryProvider)
              .pinConversation(
                chatId: conversation.chatId,
                pinned: !conversation.isPinned,
              );
          controller.patchConversationSettings(
            chatId: conversation.chatId,
            isPinned: !conversation.isPinned,
          );
          _showInlineNotice(!conversation.isPinned ? '已置顶会话' : '已取消置顶');
          break;
        case _ConversationMenuAction.unread:
          if (conversation.unreadCount > 0) {
            await controller.markConversationReadRemotely(conversation.chatId);
            _showInlineNotice('已标为已读');
          } else {
            controller.markConversationUnreadLocally(conversation.chatId);
            _showInlineNotice('已标为未读');
          }
          break;
        case _ConversationMenuAction.delete:
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('删除会话'),
              content: const Text('删除后将从当前用户会话列表移除。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await controller.deleteConversation(conversation.chatId);
            _showInlineNotice('会话已删除');
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _consumeGroupRemovalNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final notice = prefs.getString(StorageKeyRegistry.groupRemovalNotice) ?? '';
    final trimmed = notice.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await prefs.remove(StorageKeyRegistry.groupRemovalNotice);
    if (!mounted) {
      return;
    }
    _showInlineNotice(trimmed);
    final error = await ref
        .read(conversationListControllerProvider.notifier)
        .syncIncrementally();
    if (error == null) {
      _markConversationSynced();
    }
  }

  Future<void> _syncOnForegroundIfNeeded() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastOnShowRefreshAt <= _foregroundSyncCooldownMs) {
      return;
    }
    _lastOnShowRefreshAt = now;
    if (!_shouldSyncOnForeground(now)) {
      return;
    }
    final error = await ref
        .read(conversationListControllerProvider.notifier)
        .syncIncrementally();
    if (error == null) {
      _markConversationSynced();
    }
  }

  bool _shouldSyncOnForeground(int now) {
    final state = ref.read(conversationListControllerProvider);
    final hiddenDuration = _lastPageHideAt > 0
        ? now - _lastPageHideAt
        : 1 << 30;
    if (state.conversations.isEmpty) {
      return true;
    }
    final socketState = ref.read(imSocketClientProvider).state;
    if (socketState != ImSocketConnectionState.connected) {
      return true;
    }
    if (_lastConversationSyncAt <= 0) {
      return true;
    }
    if (now - _lastConversationSyncAt >= _foregroundSyncStaleMs) {
      return true;
    }
    if (hiddenDuration >= _foregroundSyncAfterHideMs) {
      return true;
    }
    return false;
  }

  bool _shouldSkipManualRefreshBecauseFresh(int now) {
    if (_lastConversationSyncAt <= 0) {
      return false;
    }
    return now - _lastConversationSyncAt < _manualRefreshFreshSkipMs;
  }

  void _applyRefreshBackoff(AppError error) {
    final retryAfterMs = _resolveRetryAfterMs(error);
    if (retryAfterMs > 0) {
      _manualRefreshBlockedUntil =
          DateTime.now().millisecondsSinceEpoch + retryAfterMs;
      return;
    }
    _refreshFailureCount = (_refreshFailureCount + 1).clamp(0, 6);
    final backoffMs =
        (_manualRefreshBackoffBaseMs *
                (1 <<
                    (_refreshFailureCount == 0 ? 0 : _refreshFailureCount - 1)))
            .clamp(0, _manualRefreshBackoffMaxMs);
    _manualRefreshBlockedUntil =
        DateTime.now().millisecondsSinceEpoch + backoffMs;
  }

  int _resolveRetryAfterMs(AppError error) {
    final cause = error.cause;
    if (cause is! DioException) {
      return 0;
    }
    final headers = cause.response?.headers;
    if (headers == null) {
      return 0;
    }
    final raw = headers.value('retry-after')?.trim() ?? '';
    if (raw.isEmpty) {
      return 0;
    }
    final seconds = int.tryParse(raw);
    if (seconds != null && seconds > 0) {
      return seconds * 1000;
    }
    final date = DateTime.tryParse(raw);
    if (date == null) {
      return 0;
    }
    return date.toLocal().millisecondsSinceEpoch -
        DateTime.now().millisecondsSinceEpoch;
  }

  void _markConversationSynced() {
    _lastConversationSyncAt = DateTime.now().millisecondsSinceEpoch;
  }
}

enum _ConversationCategory { latest, direct, group, atMe, muted }

extension on _ConversationCategory {
  String label(AppLocalizations strings) {
    return switch (this) {
      _ConversationCategory.latest => strings.conversationShortcutRecent,
      _ConversationCategory.direct => strings.conversationShortcutUsers,
      _ConversationCategory.group => strings.conversationShortcutGroups,
      _ConversationCategory.atMe => strings.conversationShortcutMention,
      _ConversationCategory.muted => strings.conversationShortcutMute,
    };
  }
}

class _ConversationCategoryItem {
  const _ConversationCategoryItem({
    required this.category,
    required this.icon,
    required this.color,
  });

  final _ConversationCategory category;
  final AppIconKind icon;
  final Color color;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final AppIconKind icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppIcon(icon, size: 22, color: const Color(0xFF202531)),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.item,
    required this.active,
    required this.label,
    required this.onTap,
  });

  final _ConversationCategoryItem item;
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFEAF2FF)
                    : const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: AppIcon(
                item.icon,
                size: 22,
                color: active ? const Color(0xFF3370FF) : item.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? const Color(0xFF246BFD)
                    : const Color(0xFF697386),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ConversationMenuAction { pin, unread, delete }
