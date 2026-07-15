import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/camera_capture_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/states/conversation_list_state.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/widgets/conversation_skeleton.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/widgets/conversation_tile.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_empty_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/pages/tenant_switch_page.dart';

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
  bool _showContextMenu = false;
  double _menuX = 0;
  double _menuY = 0;
  Conversation? _selectedConversation;
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
      icon: ShengyuIconFont.zuixingengxin,
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.direct,
      icon: ShengyuIconFont.yonghu,
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.group,
      icon: ShengyuIconFont.yonghu1,
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.atMe,
      icon: ShengyuIconFont.aite,
    ),
    _ConversationCategoryItem(
      category: _ConversationCategory.muted,
      icon: ShengyuIconFont.miandarao,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      // 先执行 load（有缓存时跳过 API）
      final error = await ref
          .read(conversationListControllerProvider.notifier)
          .load();
      if (!mounted) return;
      if (error == null) {
        _markConversationSynced();
      }
      // 无论 load 是否跳过 API，都执行一次增量同步，确保从聊天页返回时获取最新未读数
      await ref
          .read(conversationListControllerProvider.notifier)
          .syncIncrementally();
      if (!mounted) return;
      await _consumeGroupRemovalNotice();
      if (!mounted) return;
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
      // 回前台：检查 WebSocket 连接、刷新角标、sync 会话列表
      unawaited(_handleResumeFromBackground());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lastPageHideAt = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// 回前台时的恢复逻辑
  Future<void> _handleResumeFromBackground() async {
    if (!mounted) return;

    // 1. 检查 WebSocket 连接状态，如果断连则触发重连
    final socketClient = ref.read(imSocketClientProvider);
    if (socketClient.state != ImSocketConnectionState.connected) {
      debugPrint('[ConversationListPage] WebSocket not connected on resume, triggering reconnect');
      unawaited(socketClient.reconnect());
    }

    // 2. 强制刷新角标数据（忽略冷却期）
    ref.read(badgeServiceProvider.notifier).forceRefresh();
    final dio = ref.read(dioProvider);
    await ref.read(badgeServiceProvider.notifier).initBadgeData(dio);

    // 3. 执行常规的会话列表 sync
    if (!mounted) return;
    unawaited(_consumeGroupRemovalNotice());
    unawaited(_syncOnForegroundIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(conversationRealtimeBindingProvider);
    _listenGroupMemberRemovedSignal(ref, context);
    final strings = AppLocalizations.of(context);
    // 精确订阅：仅监听 status 和 error 字段，用于页面状态切换
    final listStatus = ref.watch(conversationListControllerProvider.select((state) => state.status));
    final listError = ref.watch(conversationListControllerProvider.select((state) => state.error));
    // 精确订阅：仅监听 conversations 字段，避免 status/error 变化触发不必要的 rebuild
    final conversations = ref.watch(conversationListControllerProvider.select((state) => state.conversations));
    final filteredConversations = _applyFilter(conversations);
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
      backgroundColor: ThemeColors.scaffoldBg(context),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 租户切换栏（飞书风格）
                _buildTenantSwitcher(context, ref),
                Container(
                  color: ThemeColors.surface(context),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.conversationTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: ThemeColors.textPrimary(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          _HeaderGlyphButton(
                            icon: ShengyuIconFont.saomiao,
                            onTap: _handleScan,
                          ),
                          const SizedBox(width: 20),
                          _HeaderGlyphButton(
                            icon: ShengyuIconFont.duihua,
                            onTap: _handleInitiateGroup,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: ThemeColors.searchBarBg(context),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: _handleSearch,
                              child: Icon(
                                ShengyuIconFont.chaxun,
                                size: 16,
                                color: ThemeColors.searchIcon(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                textInputAction: TextInputAction.search,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeColors.searchText(context),
                                ),
                                decoration: InputDecoration(
                                  hintText: strings.searchHint,
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
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _handleSearch(),
                              ),
                            ),
                            if (_searchController.text.trim().isNotEmpty)
                              InkWell(
                                onTap: _handleSearch,
                                child: Icon(
                                  ShengyuIconFont.fasong,
                                  size: 16,
                                  color: ThemeColors.searchIcon(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: ThemeColors.surface(context),
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
                    color: ThemeColors.noticeBg(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _inlineNoticeText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: ThemeColors.noticeText(context),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _hideInlineNotice,
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: _buildListBody(
                      context,
                      strings,
                      listStatus,
                      listError,
                      conversations,
                      filteredConversations,
                      pinnedConversations,
                      normalConversations,
                      displayedPinned,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showContextMenu) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenu,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: _menuX,
              top: _menuY,
              child: _ConversationContextMenu(
                title: (_selectedConversation?.title.trim().isNotEmpty ?? false)
                    ? _selectedConversation!.title.trim()
                    : _selectedConversation?.chatId ?? '',
                pinned: _selectedConversation?.isPinned ?? false,
                unread: (_selectedConversation?.unreadCount ?? 0) > 0,
                isGroupRemoved: _selectedConversation?.isGroupKicked == true ||
                    _selectedConversation?.isGroupDisbanded == true ||
                    _selectedConversation?.isGroupLeft == true,
                onPinTap: () => _handleMenuAction(_ConversationMenuAction.pin),
                onUnreadTap: () =>
                    _handleMenuAction(_ConversationMenuAction.unread),
                onDeleteTap: () =>
                    _handleMenuAction(_ConversationMenuAction.delete),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTenantSwitcher(BuildContext context, WidgetRef ref) {
    // 直接从 AuthSession 读取 tenantName（登录/切换租户时已返回）
    final session = ref.watch(authSessionProvider);
    final tenantName = session.tenantName ?? '';

    return GestureDetector(
      onTap: () => TenantSwitchPage.showAsLeftSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: ThemeColors.surface(context),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1677FF),
              child: Text(
                tenantName.isNotEmpty ? tenantName[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tenantName.isNotEmpty ? tenantName : '加载中...',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    AppLocalizations strings,
    ConversationListStatus listStatus,
    AppError? listError,
    List<Conversation> conversations,
    List<Conversation> filteredConversations,
    List<Conversation> pinnedConversations,
    List<Conversation> normalConversations,
    List<Conversation> displayedPinned,
  ) {
    // 关键优化：如果有数据（无论来自缓存还是网络），直接显示
    // 不显示骨架屏
    if (conversations.isNotEmpty) {
      return _buildConversationBody(
        context: context,
        strings: strings,
        pinnedConversations: displayedPinned,
        allPinnedCount: pinnedConversations.length,
        normalConversations: normalConversations,
      );
    }

    // 无数据时根据状态显示
    return switch (listStatus) {
      ConversationListStatus.initial ||
      ConversationListStatus.loading => const ConversationSkeleton(),
      ConversationListStatus.failed => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: AppErrorView(
              error: listError,
              onRetry: _reloadConversations,
            ),
          ),
        ],
      ),
      ConversationListStatus.ready => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: AppEmptyView(message: strings.emptyConversation),
          ),
        ],
      ),
    };
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
            color: ThemeColors.surfaceDim(context),
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
                              : ThemeColors.divider(context),
                        ),
                      ),
                    ),
                    child: ConversationTile(
                      conversation: pinnedConversations[index],
                      highlightPinned: true,
                      onTap: () =>
                          _handleConversationTap(pinnedConversations[index]),
                      onLongPressStart: (details) =>
                          _openConversationContextMenu(
                            pinnedConversations[index],
                            details.globalPosition,
                          ),
                      onSecondaryTapDown: (details) =>
                          _openConversationContextMenu(
                            pinnedConversations[index],
                            details.globalPosition,
                          ),
                      onMouseLongPress: (position) =>
                          _openConversationContextMenu(
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
                            style: TextStyle(
                              fontSize: 13,
                              color: ThemeColors.categoryInactiveText(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isPinnedFolded
                                ? ShengyuIconFont.zhankaishouqiZhankai
                                : ShengyuIconFont.shouqi,
                            size: 12,
                            color: ThemeColors.searchIcon(context),
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
          color: ThemeColors.surface(context),
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
                                  : ThemeColors.divider(context),
                            ),
                          ),
                        ),
                        child: ConversationTile(
                          conversation: normalConversations[index],
                          onTap: () => _handleConversationTap(
                            normalConversations[index],
                          ),
                          onLongPressStart: (details) =>
                              _openConversationContextMenu(
                                normalConversations[index],
                                details.globalPosition,
                              ),
                          onSecondaryTapDown: (details) =>
                              _openConversationContextMenu(
                                normalConversations[index],
                                details.globalPosition,
                              ),
                          onMouseLongPress: (position) =>
                              _openConversationContextMenu(
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

  void _listenGroupMemberRemovedSignal(
    WidgetRef ref,
    BuildContext context,
  ) {
    final signal = ref.watch(groupMemberRemovedSignalProvider);
    if (signal == null || !context.mounted) {
      return;
    }
    final strings = AppLocalizations.of(context);
    String reasonText;
    switch (signal.reason) {
      case 'group_disbanded':
        reasonText = strings.groupDissolved;
        break;
      case 'kicked_from_group':
        reasonText = strings.chatGroupRemovedCannotSend;
        break;
      default:
        return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(reasonText)));
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

  void _handleSearch() {
    _searchFocusNode.unfocus();
    context.pushNamed(
      RouteNames.globalChatSearch,
      extra: _searchController.text.trim(),
    );
  }

  void _handleScan() {
    if (kIsWeb) {
      context.pushNamed(RouteNames.joinGroup);
      return;
    }
    context.pushNamed(
      RouteNames.chatCameraCapture,
      extra: const CameraCaptureRouteArgs(initialMode: CameraCaptureMode.qrScan),
    );
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

    // 后台预加载消息数据（不阻塞UI）
    unawaited(_preloadChatWindow(conversation));

    // 延迟 50ms 跳转，给预加载留出时间
    await Future.delayed(const Duration(milliseconds: 50));

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

  /// 后台预加载聊天窗口数据
  ///
  /// 使用预加载模式从 Drift 数据库加载本地缓存的消息
  /// 预加载失败不影响正常进入聊天页
  Future<void> _preloadChatWindow(Conversation conversation) async {
    try {
      final loadChatWindowUseCase = ref.read(loadChatWindowUseCaseProvider);
      await loadChatWindowUseCase.call(
        OpenChatCommand(
          chatId: conversation.chatId,
          conversationType: conversation.conversationType,
          entryMode: ChatEntryMode.latest,
          isPreload: true,
        ),
      );
    } catch (e) {
      // 预加载失败静默忽略，不影响正常进入
    }
  }

  void _openConversationContextMenu(
    Conversation conversation,
    Offset globalPosition, {
    bool suppressNextTap = false,
  }) {
    if (suppressNextTap) {
      _suppressNextClickChatId = conversation.chatId;
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    setState(() {
      _selectedConversation = conversation;
      _menuX = globalPosition.dx.clamp(0, screenWidth - 160);
      _menuY = globalPosition.dy;
      _showContextMenu = true;
    });
  }

  void _closeMenu() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showContextMenu = false;
      _selectedConversation = null;
    });
  }

  Future<void> _handleMenuAction(_ConversationMenuAction action) async {
    final strings = AppLocalizations.of(context);
    final conversation = _selectedConversation;
    if (conversation == null) {
      return;
    }
    _closeMenu();
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
          _showInlineNotice(!conversation.isPinned ? strings.conversationPinnedNotice : strings.conversationUnpinnedNotice);
          break;
        case _ConversationMenuAction.unread:
          if (conversation.unreadCount > 0) {
            await controller.markConversationReadRemotely(conversation.chatId);
            _showInlineNotice(strings.conversationMarkedReadNotice);
          } else {
            controller.markConversationUnreadLocally(conversation.chatId);
            _showInlineNotice(strings.conversationMarkedUnreadNotice);
          }
          break;
        case _ConversationMenuAction.delete:
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(strings.conversationDeleteDialogTitle),
              content: Text(strings.conversationDeleteDialogContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(strings.cancelAction),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(strings.confirmAction),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await controller.deleteConversation(conversation.chatId);
            _showInlineNotice(strings.conversationDeletedNotice);
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.operationFailed(error.toString()))));
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
    if (_lastConversationSyncAt > 0 &&
        now - _lastConversationSyncAt <= _foregroundSyncCooldownMs) {
      return;
    }
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
  });

  final _ConversationCategory category;
  final IconData icon;
}

class _HeaderGlyphButton extends StatelessWidget {
  const _HeaderGlyphButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Icon(icon, size: 22, color: ThemeColors.headerIcon(context)),
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
                    ? ThemeColors.activeBg(context)
                    : ThemeColors.categoryInactiveBg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                size: 22,
                color: active ? ThemeColors.categoryActiveText(context) : ThemeColors.categoryInactiveText(context),
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
                    ? ThemeColors.categoryActiveText(context)
                    : ThemeColors.categoryInactiveText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationContextMenu extends StatelessWidget {
  const _ConversationContextMenu({
    required this.title,
    required this.pinned,
    required this.unread,
    required this.isGroupRemoved,
    required this.onPinTap,
    required this.onUnreadTap,
    required this.onDeleteTap,
  });

  final String title;
  final bool pinned;
  final bool unread;
  final bool isGroupRemoved;
  final VoidCallback onPinTap;
  final VoidCallback onUnreadTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: ThemeColors.popupMenuBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeColors.popupMenuBorder(context), width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: ThemeColors.menuItemBg(context),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ThemeColors.menuText(context),
                ),
              ),
            ),
            if (!isGroupRemoved) ...[
              _MenuTextButton(label: pinned ? strings.pinConversation : strings.unpinConversation, onTap: onPinTap),
              _MenuTextButton(
                label: unread ? strings.markAsRead : strings.markAsUnread,
                onTap: onUnreadTap,
              ),
            ],
            _MenuTextButton(
              label: strings.deleteConversation,
              color: const Color(0xFFFF4D4F),
              onTap: onDeleteTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTextButton extends StatelessWidget {
  const _MenuTextButton({
    required this.label,
    required this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(label, style: TextStyle(fontSize: 15, color: color ?? ThemeColors.textPrimary(context))),
      ),
    );
  }
}

enum _ConversationMenuAction { pin, unread, delete }
