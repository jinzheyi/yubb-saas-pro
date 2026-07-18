import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';
import 'package:shengyu_ui_admin_im/core/platform/local_file_size_loader.dart';
import 'package:shengyu_ui_admin_im/core/platform/local_uri_bytes_loader.dart';
import 'package:shengyu_ui_admin_im/core/platform/media_picker_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_outbound_sender.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/file_preview_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_combine_detail_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/initiate_group_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/select_contact_card_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/select_location_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_paths.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/optimistic_message_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_detail_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_composer_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_message_action.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_more_panel_action.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/read_receipt_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_page_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/read_receipt_summary_store_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_timeline_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_media_content_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/chat_page_timer_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_key_cache.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_composer.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_page_panels.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_timeline.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/sticker_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_skeleton.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.args});

  final ChatEntryArgs args;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  static const int _maxStickerCount = 150;
  static const int _maxForwardSelectionCount = 50;
  static const int _minVoiceDurationMs = 1000;
  static const int _maxVoiceDurationMs = 60000;
  static const int _maxVoiceSize = 10 * 1024 * 1024;
  static const int _voiceDurationOverflowToleranceMs = 1500;
  static const double _voiceCancelThreshold = 60;
  static const Duration _voicePlayedSyncDebounce = Duration(milliseconds: 300);
  static final _directUrlPattern = RegExp(r'^https?:\/\/\S+$', caseSensitive: false);
  static final _wwwUrlPattern = RegExp(r'^www\.\S+$', caseSensitive: false);
  static const Duration _voicePlayedCompensateInterval = Duration(seconds: 12);
  static const int _voicePlayedSyncBatchSize = 30;
  static const int _voicePlayedCompensateMaxIds = 80;
  static const int _voicePlayedCompensateBatchSize = 40;
  static const Duration _typingTimeout = Duration(seconds: 3);
  static const Duration _typingDebounce = Duration(milliseconds: 500);
  bool _isMorePanelVisible = false;
  bool _isEmojiPanelVisible = false;
  bool _isSelectionMode = false;
  bool _isVoiceMode = false;
  bool _isMentionPanelVisible = false;
  bool _isFullExpanded = false;
  bool _isRecording = false;
  bool _isCancelReady = false;
  bool _isVoicePressActive = false;
  final Set<String> _selectedMessageIds = <String>{};
  final Map<String, String> _mentionNameToUserId = <String, String>{};
  QuoteInfo? _quoteInfo;
  String? _activeHighlightedMessageId;
  String? _suppressNextOpenMessageId;
  String? _dismissedGroupNoticeSignature;
  String _mentionKeyword = '';
  Duration _recallWindow = const Duration(minutes: 2);
  List<StickerItem> _cachedFavoriteStickers = const <StickerItem>[];
  int _composerLineCount = 1;
  int _voicePressSession = 0;
  int _voicePlaybackSession = 0;
  int _recordingElapsedMs = 0;
  int _reeditNowTs = DateTime.now().millisecondsSinceEpoch;
  double _recordingAmplitude = -160;
  double _recordStartY = 0;
  DateTime? _recordStartAt;
  StreamSubscription<Amplitude>? _recordAmplitudeSubscription;
  StreamSubscription<Duration>? _voicePositionSubscription;
  StreamSubscription<Duration?>? _voiceDurationSubscription;
  StreamSubscription<PlayerState>? _voicePlayerStateSubscription;
  /// 统一 Timer 管理器（替代分散的 Timer? 字段）
  late final ChatPageTimerManager _timerManager;
  late final TextEditingController _mentionSearchController;
  late final FocusNode _composerFocusNode;
  final Map<String, bool> _voicePlayedPendingSync = <String, bool>{};
  String? _activePlayingVoiceMessageId;
  String? _activePausedVoiceMessageId;
  int _activeVoicePlaybackProgressMs = 0;
  int _activeVoicePlaybackDurationMs = 0;
  ProviderSubscription<ChatTimelineState>? _timelineSubscription;
  bool _voicePlayedSyncInFlight = false;
  bool _voicePlayedCompensateInFlight = false;
  bool _isTimelineAtBottom = true;
  bool _keepBottomOnNextLayout = false;
  double _lastViewInsetsBottom = 0;
  late final ScrollController _timelineScrollController;
  late final MessageKeyCache _messageItemKeys;
  int _lastSyncedMessageCount = 0;
  final Set<String> _transientSystemNotifyKeys = <String>{};
  double _lastTimelineScrollTop = 0;
  int _lastHistoryLoadTriggerAt = 0;
  bool _initialBottomAlignmentPending = true;
  final Map<String, _TypingEntry> _typingEntries = <String, _TypingEntry>{};
  late final ActiveConversationService _activeConversationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageItemKeys = MessageKeyCache(maxSize: 100);
    _timerManager = ChatPageTimerManager();
    _activeConversationService = ref.read(activeConversationServiceProvider.notifier);
    _timelineScrollController = ScrollController()
      ..addListener(_handleTimelineScroll);
    _mentionSearchController = TextEditingController();
    _composerFocusNode = FocusNode();
    _activeHighlightedMessageId =
        widget.args.highlightedMessageId ?? widget.args.anchorMessageId;
    _timelineSubscription = ref.listenManual<ChatTimelineState>(
      chatTimelineControllerProvider(widget.args.chatId),
      (previous, next) {
        _handleTimelineStateChanged(previous, next);
      },
    );

    // ===== 关键路径：首帧前初始化 =====
    // 1. 立即启动非阻塞型 Timer（打字清理、语音补偿等）
    _startVoicePlayedCompensation();
    _startTypingCleanupTimer();

    // 2. 延迟到首帧渲染完成后执行，避免阻塞首帧
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 激活当前会话（角标处理）
      _activateCurrentConversation();
      // 初始化聊天页面（关键路径：加载消息数据）
      unawaited(_initializeChatPage());
    });

    // 3. 次优先级任务：延迟到第二帧后执行（贴纸预热、撤回配置、语音补偿恢复）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_warmupStickerCatalog());
        unawaited(_restoreVoicePlayedCompensationOnce());
        unawaited(_loadRecallConfig());
        // ReeditTicker 依赖消息列表，延迟启动
        _startReeditTicker();
      });
    });
  }

  /// 激活当前会话（用于角标智能处理）
  void _activateCurrentConversation() {
    if (!mounted) return;
    final chatId = widget.args.chatId;

    // 从 BadgeState 读取该会话进入时的未读数（单一数据源）
    final badgeState = ref.read(badgeServiceProvider);
    final unreadAtEntry = badgeState.conversationBadges[chatId] ?? 0;

    // 激活当前会话（告知 Tab 栏需要扣除的未读数）
    _activeConversationService.activateChat(chatId, unreadCount: unreadAtEntry);

    // 清除该会话的角标（用户已在聊天页，消息应视为已读）
    ref.read(badgeServiceProvider.notifier).clearConversationBadge(chatId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 回前台：检查 WebSocket 连接并重试发送中消息
      unawaited(_handleResumeFromBackground());
    }
  }

  /// 回前台时的恢复逻辑（根治方案）
  Future<void> _handleResumeFromBackground() async {
    // 在每次使用 ref 之前都检查 mounted，避免 widget disposed 后访问 ref
    if (!mounted) return;

    // 1. 如果 WebSocket 未连接，触发重连（authSucceeded 事件会自动处理 pullMessagesAfterReconnect）
    final socketClient = ref.read(imSocketClientProvider);
    if (socketClient.state != ImSocketConnectionState.connected) {
      debugPrint('[ChatPage] WebSocket not connected on resume, triggering reconnect');
      unawaited(socketClient.reconnect());
      // 重连成功后，authSucceeded 事件会自动触发 pullMessagesAfterReconnect
      return;
    }

    // 2. WebSocket 已连接：直接拉取离线消息（后台期间可能收到的对方消息）
    if (!mounted) return;
    try {
      final command = OpenChatCommand.fromArgs(widget.args);
      final timelineController = ref.read(
        chatTimelineControllerProvider(widget.args.chatId).notifier,
      );
      await timelineController.pullMessagesAfterReconnect(command: command);
    } catch (e) {
      // controller 可能已被 dispose（多层导航场景），安全忽略
      debugPrint('[ChatPage] Resume handler skipped: $e');
    }
  }

  @override
  void dispose() {
    // 立即移除 lifecycle observer，避免已 disposed 的页面仍收到回前台事件
    WidgetsBinding.instance.removeObserver(this);

    final chatId = widget.args.chatId;

    // 延迟注销当前对话，避免在 widget tree finalizing 期间修改 provider 状态
    Future.microtask(() => _activeConversationService.deactivateChat());

    // 不在 dispose 中手动 invalidate provider
    // 原因：多层同名 chatId 导航时（如名片分享链），dispose 会 invalidate
    // 仍在被其他 ChatPage 使用的 provider 实例，导致状态被重置为 initial
    // Riverpod family-scoped provider 在所有 listener 消失后会自动 GC
    // 统一取消所有 Timer（通过 TimerManager 管理）
    _timerManager.cancelAll();
    _recordAmplitudeSubscription?.cancel();
    _voicePositionSubscription?.cancel();
    _voiceDurationSubscription?.cancel();
    _voicePlayerStateSubscription?.cancel();
    _timelineSubscription?.close();
    unawaited(_flushVoicePlayedSyncQueue(force: true));
    _timelineScrollController.dispose();
    _mentionSearchController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  /// 智能返回：优先使用 pop 回到来源页（搜索结果页/会话列表等），
  /// 无法 pop 时降级到会话列表，避免路由栈循环跳转
  void _handleBackToConversations(BuildContext context) {
    if (!context.mounted) return;
    // 优先尝试 pop，能回到来源页（search / conversations）
    if (context.canPop()) {
      context.pop();
    } else {
      // 无法 pop 时（如直接从外部 deep link 进入），降级到会话列表
      context.goNamed(RouteNames.conversations);
    }
  }

  Future<void> _initializeChatPage() async {
    await ref.read(chatControllerProvider(widget.args.chatId).notifier).initialize(widget.args);
    // 记录当前会话为已读可见（替代 ChatReceiptController）
    ref.read(chatReceiptLastVisibleChatIdProvider(widget.args.chatId).notifier).state = widget.args.chatId;
    await _rehydrateReeditHints();
    if (!mounted) {
      return;
    }
    _handleInitialViewport();
  }

  void _handleTimelineStateChanged(
    ChatTimelineState? previous,
    ChatTimelineState next,
  ) {
    if (!mounted || next.messages.isEmpty) {
      return;
    }
    if (widget.args.conversationType == ConversationType.group) {
      final recentOutgoingMessageIds = next.messages
          .where(_isReadReceiptMessageConfirmed)
          .map(_resolveReadReceiptTargetMessageId)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      unawaited(
        ref
            .read(readReceiptSummaryStoreProvider.notifier)
            .prefetchSummaries(recentOutgoingMessageIds),
      );
    }
    if (_initialBottomAlignmentPending &&
        widget.args.entryMode != ChatEntryMode.anchor &&
        widget.args.entryMode != ChatEntryMode.restore) {
      _ensureInitialBottomVisibility();
    }
    if (previous == null || previous.messages.isEmpty) {
      return;
    }
    final previousLastKey = _messageIdentityKey(previous.messages.last);
    final nextLastKey = _messageIdentityKey(next.messages.last);
    if (previousLastKey.isEmpty || nextLastKey.isEmpty) {
      return;
    }
    final appendedToTail =
        next.messages.length > previous.messages.length &&
        previousLastKey != nextLastKey;
    if (!appendedToTail) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_isTimelineAtBottom) {
        _scrollTimelineToBottom();
      }
    });
  }

  String _messageIdentityKey(Message message) {
    final messageId = message.messageId.trim();
    if (messageId.isNotEmpty) {
      return messageId;
    }
    return message.clientMessageId?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    if (viewInsetsBottom != _lastViewInsetsBottom) {
      final shouldKeepBottom = _isTimelineAtBottom || _keepBottomOnNextLayout;
      _lastViewInsetsBottom = viewInsetsBottom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !shouldKeepBottom) {
          return;
        }
        _scrollTimelineToBottom();
        _keepBottomOnNextLayout = false;
      });
    }
    ref.watch(chatRealtimeBindingProvider(widget.args.chatId));
    ref.listen<ChatRuntimeNotice?>(chatRuntimeNoticeProvider(widget.args.chatId), (prev, next) {
      if (next == null || next.chatId != widget.args.chatId || !mounted) {
        return;
      }
      ref.read(chatRuntimeNoticeProvider(widget.args.chatId).notifier).state = null;
      final groupId = _resolveGroupId(
        widget.args.conversationType == ConversationType.group,
      );
      if (groupId != null && groupId.trim().isNotEmpty) {
        final args = GroupContextArgs(groupId: groupId, groupName: '');
        ref.invalidate(groupSettingsControllerProvider(args));
        ref.invalidate(groupMembersFutureProvider(groupId));
      }
      _showAttachmentError(context, next.message);
      if (next.redirectToConversations) {
        final router = GoRouter.of(context);
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (!mounted) {
            return;
          }
          router.goNamed(RouteNames.conversations);
        });
      }
    });
    ref.listen<ChatRealtimeSignal?>(chatRealtimeSignalProvider(widget.args.chatId), (prev, next) {
      if (next == null || next.chatId != widget.args.chatId || !mounted) {
        return;
      }
      ref.read(chatRealtimeSignalProvider(widget.args.chatId).notifier).state = null;
      _handleRealtimeSignal(next);
    });
    // ===== 精确订阅优化：仅监听实际使用的字段，减少 60-70% 不必要 rebuild =====
    final strings = ref.watch(appStringsProvider);
    // 仅订阅页面状态字段：每个字段独立订阅，避免无关字段变化触发 rebuild
    final pageStatus = ref.watch(chatControllerProvider(widget.args.chatId).select((state) => state.pageStatus));
    final pendingAction = ref.watch(chatControllerProvider(widget.args.chatId).select((state) => state.pendingAction));
    final isReadOnly = ref.watch(chatControllerProvider(widget.args.chatId).select((state) => state.isReadOnly));
    final pageError = ref.watch(chatControllerProvider(widget.args.chatId).select((state) => state.error));
    final chatTitleFromState = ref.watch(chatControllerProvider(widget.args.chatId).select((state) => state.chatTitle));
    final entryArgs = ref.watch(chatControllerProvider(widget.args.chatId).select((state) => state.entryArgs));
    // 仅订阅消息时间线字段：messages、status、viewportState 独立订阅
    final timelineMessages = ref.watch(chatTimelineControllerProvider(widget.args.chatId).select((state) => state.messages));
    final timelineStatus = ref.watch(chatTimelineControllerProvider(widget.args.chatId).select((state) => state.status));
    final timelineViewportState = ref.watch(chatTimelineControllerProvider(widget.args.chatId).select((state) => state.viewportState));
    final timelineError = ref.watch(chatTimelineControllerProvider(widget.args.chatId).select((state) => state.error));
    final timelineQuotePreviewCache = ref.watch(chatTimelineControllerProvider(widget.args.chatId).select((state) => state.quotePreviewCache));
    // 仅订阅已读回执汇总
    final readReceiptSummaryState = ref.watch(readReceiptSummaryStoreProvider);
    // 仅订阅媒体选择状态：isPicking
    final isMediaPicking = ref.watch(chatMediaControllerProvider(widget.args.chatId).select((state) => state.isPicking));
    final composer = ref.watch(chatComposerControllerProvider);
    // 仅订阅会话列表
    final conversations = ref.watch(conversationListControllerProvider.select((state) => state.conversations));

    final chatTitle = chatTitleFromState ?? strings.chatTitle;
    final isBusy =
        pendingAction == ChatPendingAction.sendingMessage ||
        isMediaPicking;
    final isGroupChat = widget.args.conversationType == ConversationType.group;
    final conversation = _resolveConversation(conversations);
    final groupId = _resolveGroupId(isGroupChat);
    final groupSettingsState = groupId == null
        ? null
        : ref.watch(
            groupSettingsControllerProvider(
              GroupContextArgs(groupId: groupId, groupName: chatTitle),
            ),
          );
    final groupNoticeText = _resolveGroupNoticeText(groupSettingsState);
    final groupMembersAsync = groupId == null
        ? const AsyncValue<List<GroupMember>>.data(<GroupMember>[])
        : ref.watch(groupMembersFutureProvider(groupId));
    final currentUserId = ref.watch(authSessionProvider).userId;
    final groupMembers = groupMembersAsync.valueOrNull ?? const <GroupMember>[];
    final groupRestrictionHint = _resolveGroupSendRestrictionHint(
      groupSettingsState: groupSettingsState,
      currentUserId: currentUserId,
      conversation: conversation,
    );
    final canMentionAll = _resolveCanMentionAll(
      members: groupMembers,
      currentUserId: currentUserId,
    );
    // 增量同步消息 Key：仅处理新增消息，避免每次 build 遍历全量消息
    final currentCount = timelineMessages.length;
    if (currentCount != _lastSyncedMessageCount) {
      final start = _lastSyncedMessageCount > 0 && currentCount > _lastSyncedMessageCount
          ? _lastSyncedMessageCount
          : 0;
      for (var index = start; index < currentCount; index++) {
        final msg = timelineMessages[index];
        final renderKey = _messageRenderKey(msg, index);
        _messageItemKeys.putIfAbsent(renderKey, GlobalKey.new);
      }
      _lastSyncedMessageCount = currentCount;
      _messageItemKeys.evict(); // LRU 回收超出限制的旧 Key
    }
    final timelineMessageKeys = _messageItemKeys;
    final filteredMentionMembers = _filterMentionMembers(
      members: groupMembers,
      keyword: _mentionKeyword,
    );
    final memberCount = _resolveMemberCount(
      context,
      conversation: conversation,
      groupSettingsState: groupSettingsState,
    );
    final shouldShowEditableComposer =
        !_isSelectionMode &&
        !isReadOnly &&
        groupRestrictionHint == null;
    final fullExpandedComposerOnly =
        shouldShowEditableComposer && _isFullExpanded;
    final composerWidget = ChatComposer(
      composer: composer,
      focusNode: _composerFocusNode,
      isSending: isBusy,
      hintText: strings.inputMessage,
      quoteInfo: _quoteInfo,
      onClearQuote: _clearQuoteReply,
      onTapInput: () {
        if (_isMorePanelVisible) {
          setState(() {
            _isMorePanelVisible = false;
          });
        }
      },
      onChanged: (value) {
        _updateComposerLineCount(value);
        _handleComposerChanged(
          value,
          isGroupChat: isGroupChat,
          groupId: groupId,
          isReadOnly: isReadOnly,
        );
      },
      onTapVoice: () {
        if (!_ensureConversationWritable(context)) {
          return;
        }
        if (_isMorePanelVisible || _isEmojiPanelVisible) {
          setState(() {
            _isMorePanelVisible = false;
            _isEmojiPanelVisible = false;
          });
        }
        if (_isMentionPanelVisible) {
          _closeMentionPanel();
        }
        setState(() {
          _isVoiceMode = !_isVoiceMode;
        });
      },
      fullExpanded: _isFullExpanded,
      showExpandAction: _showExpandIcon(composer.textController.text),
      composerHeight: _composerHeight(),
      onToggleExpand: _toggleFullExpand,
      voiceMode: _isVoiceMode,
      isRecording: _isRecording,
      isCancelReady: _isCancelReady,
      onVoicePressStart: _startVoiceRecording,
      onVoicePressMove: _updateVoiceRecordingGesture,
      onVoicePressEnd: _finishVoiceRecording,
      onVoicePressCancel: _cancelVoiceRecording,
      onTapEmoji: () {
        final shouldKeepBottom = _isTimelineAtBottom;
        setState(() {
          _isEmojiPanelVisible = !_isEmojiPanelVisible;
          _isVoiceMode = false;
          _keepBottomOnNextLayout = shouldKeepBottom;
          if (_isEmojiPanelVisible) {
            _isMorePanelVisible = false;
          }
        });
        if (_isEmojiPanelVisible && _isMentionPanelVisible) {
          _closeMentionPanel();
        }
        if (_isEmojiPanelVisible) {
          _composerFocusNode.unfocus();
        }
        if (shouldKeepBottom) {
          _scheduleBottomStick();
        }
      },
      onSend: (value) async {
        if (!_ensureConversationWritable(context)) {
          return;
        }
        // Clear composer synchronously before sending to avoid text overlap
        // with the optimistic message in the timeline.
        final trimmedValue = value.trim();
        if (trimmedValue.isEmpty) {
          return;
        }
        composer.clear();
        _updateComposerLineCount('');
        _clearQuoteReply();
        _resetMentionState();
        if (_isMorePanelVisible || _isEmojiPanelVisible || _isFullExpanded) {
          setState(() {
            _isMorePanelVisible = false;
            _isEmojiPanelVisible = false;
            _isFullExpanded = false;
          });
        }
        final mentionPayload = _buildMentionPayload(trimmedValue);
        final sent = await ref
            .read(chatControllerProvider(widget.args.chatId).notifier)
            .sendText(
              trimmedValue,
              quoteInfo: _quoteInfo,
              atUserIds: mentionPayload.atUserIds,
              mentions: mentionPayload.mentions,
            );
        if (!sent) {
          if (!context.mounted) {
            return;
          }
          final error = ref.read(chatControllerProvider(widget.args.chatId)).error;
          if (_handleGroupLifecycleRequestError(
            context,
            error,
            fallbackNotice: strings.chatGroupRemovedCannotSend,
          )) {
            return;
          }
          final errorMessage = error?.message.trim() ?? '';
          _showAttachmentError(
            context,
            errorMessage.isNotEmpty ? errorMessage : strings.messageFailed,
          );
          return;
        }
      },
      onOpenAttachmentMenu: () {
        final shouldKeepBottom = _isTimelineAtBottom;
        setState(() {
          _isMorePanelVisible = !_isMorePanelVisible;
          _keepBottomOnNextLayout = shouldKeepBottom;
          if (_isMorePanelVisible) {
            _isEmojiPanelVisible = false;
          }
        });
        if ((_isMorePanelVisible || _isEmojiPanelVisible) &&
            _isMentionPanelVisible) {
          _closeMentionPanel();
        }
        if (shouldKeepBottom) {
          _scheduleBottomStick();
        }
      },
    );
    final composerPanel = !_isVoiceMode && _isMentionPanelVisible
        ? ChatMentionPanel(
            searchController: _mentionSearchController,
            items: filteredMentionMembers,
            loading: groupMembersAsync.isLoading,
            canMentionAll: canMentionAll,
            onKeywordChanged: (value) {
              setState(() {
                _mentionKeyword = value;
              });
            },
            onClose: _closeMentionPanel,
            onSelectAll: () => _applyMentionSelection(
              mentionName: ref.read(appStringsProvider).chatMentionAllMembers,
              userId: '-1',
            ),
            onSelectItem: _applyMentionMemberSelection,
          )
        : !_isVoiceMode && _isEmojiPanelVisible
        ? ChatEmojiStickerPanel(
            stickerRepository: ref.read(stickerRepositoryProvider),
            fileRepository: ref.read(fileRepositoryProvider),
            mediaPickerService: ref.read(mediaPickerServiceProvider),
            currentUserId: ref.read(authSessionProvider).userId,
            maxStickerCount: _maxStickerCount,
            onManage: () => context.pushNamed(RouteNames.chatStickerManage),
            onInsertEmoji: (emojiCode) {
              _insertEmojiIntoComposer(composer, emojiCode);
            },
            onDeleteEmoji: () {
              _deleteEmojiFromComposer(composer);
            },
            onSendSticker: (payload) async {
              if (!_ensureConversationWritable(context)) {
                return false;
              }
              final sent = await ref
                  .read(chatControllerProvider(widget.args.chatId).notifier)
                  .sendSticker(payload);
              if (!sent && context.mounted) {
                final error = ref.read(chatControllerProvider(widget.args.chatId)).error;
                if (_handleGroupLifecycleRequestError(
                  context,
                  error,
                  fallbackNotice: strings.chatGroupRemovedCannotSend,
                )) {
                  return false;
                }
                final errorMessage = error?.message.trim() ?? '';
                _showAttachmentError(
                  context,
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : strings.messageFailed,
                );
              }
              return sent;
            },
            onShowNotice: (text) => _showAttachmentError(context, text),
            onShowSuccessNotice: (text) =>
                _showAttachmentSuccess(context, text),
          )
        : _isMorePanelVisible
        ? ChatMorePanel(
            strings: strings,
            onExecuteAction: (action) async {
              setState(() {
                _isMorePanelVisible = false;
              });
              await _handleMorePanelAction(
                ref: ref,
                action: action,
                pageState: ChatPageState(
                  entryArgs: entryArgs,
                  pageStatus: pageStatus,
                  pendingAction: pendingAction,
                  isReadOnly: isReadOnly,
                  error: pageError,
                  chatTitle: chatTitleFromState,
                ),
                chatTitle: chatTitle,
              );
            },
          )
        : null;
    final composerPanels = composerPanel == null
        ? const <Widget>[]
        : <Widget>[composerPanel];
    final body = switch (pageStatus) {
      ChatPageStatus.initial ||
      ChatPageStatus.initializing => const MessageSkeleton(),
      ChatPageStatus.failed => AppErrorView(
        error: pageError,
        onRetry: () {
          unawaited(_initializeChatPage());
        },
      ),
      ChatPageStatus.ready =>
        fullExpandedComposerOnly
            ? Column(
                children: [
                  Expanded(child: composerWidget),
                  ...composerPanels,
                ],
              )
            : Column(
                children: [
                  if (!_isSelectionMode && groupNoticeText.isNotEmpty)
                    ChatGroupNoticeBanner(
                      notice: groupNoticeText,
                      onTap: () => _openGroupAnnouncement(
                        context,
                        groupId: groupId,
                        groupName: chatTitle,
                      ),
                      onDismiss: () {
                        setState(() {
                          _dismissedGroupNoticeSignature =
                              _groupNoticeSignature(groupNoticeText);
                        });
                      },
                    ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: ThemeColors.surfaceDim(context)),
                      child: switch (timelineStatus) {
                        ChatTimelineStatus.failed => AppErrorView(
                          error: timelineError,
                          onRetry: () {
                            unawaited(_initializeChatPage());
                          },
                        ),
                        _ => ChatTimeline(
                          messages: timelineMessages,
                          messageItemKeys: timelineMessageKeys,
                          controller: _timelineScrollController,
                          quotePreviewCache: timelineQuotePreviewCache,
                          highlightedMessageId: _activeHighlightedMessageId,
                          selectionMode: _isSelectionMode,
                          selectedMessageIds: _selectedMessageIds,
                          isLoadingOlder:
                              timelineStatus ==
                              ChatTimelineStatus.loading,
                          onLoadOlder: timelineViewportState?.hasMoreBefore == true
                              ? () async {
                                  final notice = strings.chatNoMoreMessages;
                                  final beforeCount = timelineMessages.length;
                                  await ref
                                      .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
                                      .loadOlder(chatId: entryArgs.chatId);
                                  if (!mounted || !context.mounted) {
                                    return;
                                  }
                                  final nextTimeline = ref.read(
                                    chatTimelineControllerProvider(widget.args.chatId),
                                  );
                                  if (beforeCount == nextTimeline.messages.length &&
                                      nextTimeline.viewportState?.hasMoreBefore ==
                                          false) {
                                    _showAttachmentError(context, notice);
                                  }
                                }
                              : null,
                          onRetryMessage: (message) async {
                            if (message.type == MessageType.text) {
                              final retried = await ref
                                  .read(chatControllerProvider(widget.args.chatId).notifier)
                                  .retryFailedMessage(
                                    message.clientMessageId ??
                                        message.messageId,
                                  );
                              if (retried && context.mounted) {
                                _showAttachmentError(
                                  context,
                                  strings.chatRetryingMessage,
                                );
                              }
                              return;
                            }
                            if (message.type == MessageType.voice) {
                              final retried = await _retryVoiceMessage(message);
                              if (!retried && context.mounted) {
                                _showAttachmentError(
                                  context,
                                  strings.chatVoiceUploadRetry,
                                );
                              }
                              return;
                            }
                            final handled = await ref
                                .read(chatMediaControllerProvider(widget.args.chatId).notifier)
                                .retryFailedMessage(
                                  failedMessage: message,
                                  entryArgs: entryArgs,
                                  chatTitle: chatTitle,
                                );
                            if (!handled) {
                              final error = ref
                                  .read(chatMediaControllerProvider(widget.args.chatId))
                                  .error;
                              if (error != null && context.mounted) {
                                if (_handleGroupLifecycleRequestError(
                                  context,
                                  error,
                                  fallbackNotice:
                                      strings.chatGroupRemovedCannotSend,
                                )) {
                                  return;
                                }
                                _showAttachmentError(context, error.message);
                              }
                            }
                          },
                          onOpenMessage: (message) {
                            if (_isSelectionMode) {
                              _toggleSelection(message);
                              return;
                            }
                            _openMessagePreview(context, message);
                          },
                          onPauseVoiceMessage: (message) {
                            unawaited(_pauseVoicePlayback(message));
                          },
                          onResumeVoiceMessage: (message) {
                            unawaited(_resumeVoicePlayback(message));
                          },
                          onReplayVoiceMessage: (message) {
                            unawaited(_replayVoicePlayback(message));
                          },
                          onLongPressMessage: (message, globalPosition) {
                            if (_isSelectionMode) {
                              _toggleSelection(message);
                              return;
                            }
                            _suppressNextOpenMessageId = _messageSelectionKey(
                              message,
                            );
                            _showMessageActions(
                              context,
                              message,
                              globalPosition: globalPosition,
                            );
                          },
                          activePlayingVoiceMessageId:
                              _activePlayingVoiceMessageId,
                          activePausedVoiceMessageId:
                              _activePausedVoiceMessageId,
                          activeVoicePlaybackProgressMs:
                              _activeVoicePlaybackProgressMs,
                          activeVoicePlaybackDurationMs:
                              _activeVoicePlaybackDurationMs,
                          onOpenReadReceipt: isGroupChat
                              ? (message) => _showReadReceiptSheet(
                                  context,
                                  chatTitle: chatTitle,
                                  message: message,
                                )
                              : null,
                          onToggleSelection: _toggleSelection,
                          onOpenMentionUser: _openMentionUserProfile,
                          onOpenQuotedMessage: _openQuotedMessage,
                          onOpenLink: _handleTextLinkTap,
                          onReeditRecalledMessage: _handleReeditAfterRecall,
                          reeditNowTs: _reeditNowTs,
                          showSenderNamesForIncoming: isGroupChat,
                          watermarkText: _resolveCurrentUserDisplayName(
                            currentUserId,
                          ),
                          outgoingFooterLabelBuilder: isGroupChat
                              ? (message) => _buildReadReceiptEntryText(
                                  message,
                                  strings,
                                  readReceiptSummaryState,
                                )
                              : null,
                        ),
                      },
                    ),
                  ),
                  if (_isSelectionMode)
                    ChatMultiSelectToolbar(
                      onForward: () => _confirmSelectionForward(context),
                      onDelete: () => _deleteSelectedMessages(context),
                    )
                  else if (isReadOnly || groupRestrictionHint != null)
                    ChatReadonlyFooter(
                      hintText: isReadOnly
                          ? _resolveReadOnlyHint()
                          : groupRestrictionHint!,
                    )
                  else ...[
                    composerWidget,
                    ...composerPanels,
                  ],
                ],
              ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackToConversations(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FA),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _isSelectionMode
              ? _buildSelectionAppBar(strings)
              : ChatPageHeader(
                  title: chatTitle,
                  subtitle: isGroupChat
                      ? _resolveGroupSubtitle(context, memberCount: memberCount)
                      : _resolveSingleChatSubtitle(
                          context,
                          conversation: conversation,
                        ),
                  onBack: () => _handleBackToConversations(context),
                  onInitiateGroup: () {
                    context.pushNamed(
                      RouteNames.initiateGroup,
                      extra: const InitiateGroupArgs.create(),
                    );
                  },
                  onOpenSettings: () {
                    if (isGroupChat) {
                      context.pushNamed(
                        RouteNames.groupSettings,
                        extra: GroupContextArgs(
                          groupId: widget.args.targetId ?? widget.args.chatId,
                          groupName: chatTitle,
                        ),
                      );
                      return;
                    }
                    if (widget.args.targetId == null ||
                        widget.args.targetId!.isEmpty) {
                      return;
                    }
                    context.pushNamed(
                      RouteNames.chatSettings,
                      extra: ChatEntryArgs.latest(
                        chatId: widget.args.chatId,
                        conversationType: widget.args.conversationType,
                        targetId: widget.args.targetId,
                        title: chatTitle,
                      ),
                    );
                  },
                ),
        ),
        body:
            Stack(children: [body, if (_isRecording) _buildRecordingOverlay()]),
      ),
    );
  }

  void _handleRealtimeSignal(ChatRealtimeSignal signal) {
    switch (signal.action) {
      case 'voice_played':
        _handleVoicePlayedSignal(signal.payload);
        return;
      case 'typing':
        _handleTypingSignal(signal.payload);
        return;
      case 'group_member_mute_changed':
      case 'group_mute_all_changed':
      case 'group_member_added':
      case 'group_member_removed':
      case 'group_owner_transferred':
      case 'group_disbanded':
        _handleGroupSystemSignal(signal);
        return;
      default:
        return;
    }
  }

  void _handleVoicePlayedSignal(Map<String, Object?> payload) {
    final messageId = payload['messageId']?.toString().trim() ?? '';
    if (messageId.isEmpty || messageId == '0') {
      return;
    }
    final incomingChatId = payload['chatId']?.toString().trim() ?? '';
    if (incomingChatId.isNotEmpty &&
        incomingChatId != '0' &&
        incomingChatId != widget.args.chatId.trim()) {
      return;
    }
    _voicePlayedPendingSync.remove(messageId);
    ref
        .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
        .markVoicePlayed(messageId: messageId);
    unawaited(_persistVoicePlayed(messageId));
  }

  void _handleTypingSignal(Map<String, Object?> payload) {
    final senderId = payload['senderId']?.toString().trim() ?? '';
    final currentUserId = ref.read(authSessionProvider).userId.trim();
    if (senderId.isEmpty || senderId == currentUserId) {
      return;
    }
    final senderName = payload['senderName']?.toString().trim() ?? '';
    final displayName = senderName.isNotEmpty ? senderName : senderId;
    setState(() {
      _typingEntries[senderId] = _TypingEntry(
        userId: senderId,
        userName: displayName,
        timestamp: DateTime.now(),
      );
    });
  }

  void _handleGroupSystemSignal(ChatRealtimeSignal signal) {
    if (widget.args.conversationType != ConversationType.group) {
      return;
    }
    final payload = signal.payload;
    final notifyGroupId = payload['groupId']?.toString().trim() ?? '';
    final currentGroupId = _resolveGroupId(true)?.trim() ?? '';
    if (notifyGroupId.isEmpty ||
        currentGroupId.isEmpty ||
        notifyGroupId != currentGroupId) {
      return;
    }
    final args = GroupContextArgs(groupId: notifyGroupId, groupName: '');
    final groupSettingsNotifier = ref.read(
      groupSettingsControllerProvider(args).notifier,
    );
    final groupMembersNotifier = ref.read(
      groupMembersControllerProvider(args).notifier,
    );

    if (signal.action == 'group_mute_all_changed') {
      final muted =
          payload['muted'] == true ||
          payload['muted']?.toString() == '1' ||
          payload['muted']?.toString().toLowerCase() == 'true';
      groupSettingsNotifier.applyRealtimeMuteAll(muted);
    }

    if (signal.action == 'group_member_mute_changed') {
      final memberUserId = payload['memberUserId']?.toString().trim() ?? '';
      final currentUserId = ref.read(authSessionProvider).userId.trim();
      if (memberUserId.isNotEmpty && memberUserId == currentUserId) {
        final muted =
            payload['muted'] == true ||
            payload['muted']?.toString() == '1' ||
            payload['muted']?.toString().toLowerCase() == 'true';
        groupSettingsNotifier.applyRealtimeCurrentUserMute(
          muted
              ? _normalizeNotifyTime(payload['muteEndTime']?.toString())
              : null,
        );
      }
    }

    if (signal.action == 'group_member_added') {
      final currentUserId = ref.read(authSessionProvider).userId.trim();
      final memberUserIds = payload['memberUserIds'];
      var currentUserAdded = false;
      if (memberUserIds is List) {
        for (final item in memberUserIds) {
          final nextId = item?.toString().trim() ?? '';
          if (nextId.isNotEmpty && nextId == currentUserId) {
            currentUserAdded = true;
            break;
          }
        }
      }
      if (currentUserAdded) {
        groupSettingsNotifier.markMembershipRestored();
        unawaited(
          ref
              .read(conversationListControllerProvider.notifier)
              .syncIncrementally(),
        );
        unawaited(groupSettingsNotifier.load());
        unawaited(groupMembersNotifier.load());
      } else {
        // 其他成员加入，仅局部刷新成员列表
        unawaited(groupMembersNotifier.load());
      }
    }

    if (signal.action == 'group_member_removed') {
      final memberUserId = payload['memberUserId']?.toString().trim() ?? '';
      final currentUserId = ref.read(authSessionProvider).userId.trim();
      if (memberUserId.isNotEmpty && memberUserId == currentUserId) {
        _redirectAfterRemovedFromGroup(
          context,
          ref.read(appStringsProvider).chatGroupRemovedCannotSend,
        );
        return;
      }
      // 其他成员移除，仅局部刷新成员列表
      unawaited(groupMembersNotifier.load());
    }

    if (signal.action == 'group_disbanded') {
      _redirectAfterRemovedFromGroup(context, ref.read(appStringsProvider).groupDissolved);
      return;
    }

    final tipText = _resolveGroupSystemSignalText(signal);
    if (tipText.isEmpty) {
      return;
    }
    final eventKey = _groupSystemSignalKey(signal, tipText);
    if (_transientSystemNotifyKeys.contains(eventKey)) {
      return;
    }
    _transientSystemNotifyKeys.add(eventKey);
    final now = DateTime.now();
    ref
        .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
        .appendSingleMessage(
          Message(
            messageId:
                'system_notify_${now.microsecondsSinceEpoch}_${eventKey.hashCode}',
            chatId: widget.args.chatId,
            senderId: '0',
            senderName: '',
            type: MessageType.system,
            status: MessageStatus.sent,
            content: tipText,
            sentAt: now,
            isOutgoing: false,
          ),
        );

    if (signal.action == 'group_owner_transferred') {
      final currentUserId = ref.read(authSessionProvider).userId.trim();
      final oldOwnerId = payload['oldOwnerId']?.toString().trim() ?? '';
      final newOwnerId = payload['newOwnerId']?.toString().trim() ?? '';
      final strings = ref.read(appStringsProvider);
      if (newOwnerId.isNotEmpty && newOwnerId == currentUserId) {
        _showAttachmentError(context, strings.chatGroupYouAreNewOwner);
      } else if (oldOwnerId.isNotEmpty && oldOwnerId == currentUserId) {
        _showAttachmentError(context, strings.chatGroupYouTransferredOwner);
      }
      // 群主变更需要全量刷新群设置
      unawaited(
        ref.read(conversationListControllerProvider.notifier).syncIncrementally(),
      );
      unawaited(groupSettingsNotifier.load());
      unawaited(groupMembersNotifier.load());
    }
  }

  String _groupSystemSignalKey(ChatRealtimeSignal signal, String tipText) {
    final payload = signal.payload;
    return [
      signal.action,
      payload['groupId']?.toString().trim() ?? '',
      payload['memberUserId']?.toString().trim() ?? '',
      payload['oldOwnerId']?.toString().trim() ?? '',
      payload['newOwnerId']?.toString().trim() ?? '',
      payload['muted']?.toString().trim() ?? '',
      payload['muteEndTime']?.toString().trim() ?? '',
      payload['tipContent']?.toString().trim() ?? '',
      tipText,
    ].join('|');
  }

  String _resolveGroupSystemSignalText(ChatRealtimeSignal signal) {
    final strings = ref.read(appStringsProvider);
    final payload = signal.payload;
    final tipContent = payload['tipContent']?.toString().trim() ?? '';
    if (tipContent.isNotEmpty) {
      return tipContent;
    }
    final renderedI18n = _renderSystemNotifyI18n(payload['i18n']);
    if (renderedI18n.isNotEmpty) {
      return renderedI18n;
    }
    switch (signal.action) {
      case 'group_mute_all_changed':
        final muted =
            payload['muted'] == true ||
            payload['muted']?.toString() == '1' ||
            payload['muted']?.toString().toLowerCase() == 'true';
        return muted
            ? strings.chatGroupMuteAllEnabled
            : strings.chatGroupMuteAllDisabled;
      case 'group_member_mute_changed':
        final muted =
            payload['muted'] == true ||
            payload['muted']?.toString() == '1' ||
            payload['muted']?.toString().toLowerCase() == 'true';
        final memberUserId = payload['memberUserId']?.toString().trim() ?? '';
        final currentUserId = ref.read(authSessionProvider).userId.trim();
        if (memberUserId.isNotEmpty && memberUserId == currentUserId) {
          if (!muted) {
            return strings.chatGroupYouUnmuted;
          }
          final muteEndTime = _normalizeNotifyTime(
            payload['muteEndTime']?.toString(),
          );
          if (muteEndTime != null && muteEndTime.isAfter(DateTime.now())) {
            return strings.chatGroupMutedUntil(_formatMuteUntil(muteEndTime));
          }
          return strings.chatGroupMutedNoSend;
        }
        return muted
            ? strings.chatGroupMemberMutedGeneric
            : strings.chatGroupMemberUnmutedGeneric;
      case 'group_member_added':
        return strings.chatGroupMemberAdded;
      case 'group_member_removed':
        return strings.chatGroupMemberRemoved;
      case 'group_owner_transferred':
        return strings.chatGroupOwnerTransferred;
      default:
        return '';
    }
  }

  DateTime? _normalizeNotifyTime(String? raw) {
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null || value <= 0) {
      return null;
    }
    final millis = value > 9999999999 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  }

  String _renderSystemNotifyI18n(Object? rawI18n) {
    if (rawI18n is! Map) {
      return '';
    }
    final eventKey = rawI18n['eventKey']?.toString().trim() ?? '';
    if (eventKey.isEmpty) {
      return '';
    }
    final params = rawI18n['params'];
    final paramMap = params is Map
        ? params.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          )
        : const <String, String>{};
    final strings = ref.read(appStringsProvider);
    switch (eventKey) {
      case 'im.system.group_owner_transferred':
        final name = paramMap['newOwnerName']?.trim() ?? '';
        return name.isEmpty
            ? strings.chatGroupOwnerTransferred
            : strings.chatGroupOwnerTransferredTo(name);
      case 'im.system.group_member_added_one':
        final firstName = paramMap['firstName']?.trim() ?? '';
        return firstName.isEmpty
            ? strings.chatGroupMemberAdded
            : strings.chatGroupMemberAddedOne(firstName);
      case 'im.system.group_member_added_two':
        final firstName = paramMap['firstName']?.trim() ?? '';
        final secondName = paramMap['secondName']?.trim() ?? '';
        if (firstName.isEmpty || secondName.isEmpty) {
          return strings.chatGroupMemberAdded;
        }
        return strings.chatGroupMemberAddedTwo(firstName, secondName);
      case 'im.system.group_member_added_many':
        final firstName = paramMap['firstName']?.trim() ?? '';
        final secondName = paramMap['secondName']?.trim() ?? '';
        final otherCount = int.tryParse(paramMap['otherCount']?.trim() ?? '');
        if (firstName.isEmpty || secondName.isEmpty || otherCount == null) {
          return strings.chatGroupMemberAdded;
        }
        return strings.chatGroupMemberAddedMany(
          firstName,
          secondName,
          otherCount,
        );
      case 'im.system.group_member_removed':
        final memberName = paramMap['memberName']?.trim() ?? '';
        return memberName.isEmpty
            ? strings.chatGroupMemberRemoved
            : strings.chatGroupMemberRemovedNamed(memberName);
      case 'im.system.group_member_role_set_admin':
        final operatorName = paramMap['operatorName']?.trim() ?? '';
        final targetName = paramMap['targetName']?.trim() ?? '';
        if (operatorName.isEmpty || targetName.isEmpty) {
          return strings.chatGroupMemberRoleSetAdmin;
        }
        return strings.chatGroupMemberRoleSetAdminNamed(
          operatorName,
          targetName,
        );
      case 'im.system.group_member_role_set_member':
        final operatorName = paramMap['operatorName']?.trim() ?? '';
        final targetName = paramMap['targetName']?.trim() ?? '';
        if (operatorName.isEmpty || targetName.isEmpty) {
          return strings.chatGroupMemberRoleSetMember;
        }
        return strings.chatGroupMemberRoleSetMemberNamed(
          operatorName,
          targetName,
        );
      case 'im.system.group_member_muted':
        final memberName = paramMap['memberName']?.trim() ?? '';
        return memberName.isEmpty
            ? strings.chatGroupMemberMutedGeneric
            : strings.chatGroupMemberMutedNamed(memberName);
      case 'im.system.group_member_muted_until':
        final memberName = paramMap['memberName']?.trim() ?? '';
        final muteEndTime = paramMap['muteEndTime']?.trim() ?? '';
        if (memberName.isEmpty || muteEndTime.isEmpty) {
          return strings.chatGroupMemberMutedGeneric;
        }
        return strings.chatGroupMemberMutedUntil(memberName, muteEndTime);
      case 'im.system.group_member_unmuted':
        final memberName = paramMap['memberName']?.trim() ?? '';
        return memberName.isEmpty
            ? strings.chatGroupMemberUnmutedGeneric
            : strings.chatGroupMemberUnmutedNamed(memberName);
      case 'im.system.group_mute_all_enabled':
        return strings.chatGroupMuteAllEnabled;
      case 'im.system.group_mute_all_disabled':
        return strings.chatGroupMuteAllDisabled;
      default:
        return '';
    }
  }

  Widget _buildRecordingOverlay() {
    final strings = AppLocalizations.of(context);
    final elapsed = Duration(milliseconds: _recordingElapsedMs);
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final bars = List<int>.generate(5, (index) => index);
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 164,
              height: 172,
              decoration: BoxDecoration(
                color: _isCancelReady
                    ? const Color(0xCCF54A45)
                    : const Color(0xB3000000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    _isCancelReady ? AppIconKind.delete : AppIconKind.mic,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$minutes:$seconds / 01:00',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isCancelReady
                          ? const Color(0xFFFFE58F)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isCancelReady)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final bar in bars)
                          Container(
                            width: 4,
                            height: _barHeight(bar),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6FA),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  if (!_isCancelReady) const SizedBox(height: 10),
                  Text(
                    _isCancelReady
                        ? strings.chatRecordingReleaseToCancelShort
                        : strings.chatRecordingSlideToCancel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _barHeight(int index) {
    final base = ((_recordingAmplitude + 160) / 160).clamp(0.0, 1.0);
    final value = 6 + ((index + 1) * 3) + base * 12;
    return value < 6 ? 6 : value;
  }

  Conversation? _resolveConversation(List<Conversation> conversations) {
    for (final item in conversations) {
      if (item.chatId == widget.args.chatId) {
        return item;
      }
    }
    return null;
  }

  String? _resolveGroupId(bool isGroupChat) {
    if (!isGroupChat) {
      return null;
    }
    final targetId = widget.args.targetId?.trim() ?? '';
    if (targetId.isNotEmpty) {
      return targetId;
    }
    final chatId = widget.args.chatId.trim();
    if (chatId.isNotEmpty) {
      return chatId;
    }
    return null;
  }

  String _resolveGroupNoticeText(GroupSettingsState? groupSettingsState) {
    final notice = groupSettingsState?.notice.trim() ?? '';
    if (notice.isEmpty) {
      return '';
    }
    if (_dismissedGroupNoticeSignature == _groupNoticeSignature(notice)) {
      return '';
    }
    return notice;
  }

  String? _resolveGroupSendRestrictionHint({
    required GroupSettingsState? groupSettingsState,
    required String currentUserId,
    required Conversation? conversation,
  }) {
    if (widget.args.conversationType != ConversationType.group) {
      return null;
    }
    final strings = ref.read(appStringsProvider);
    if (conversation != null) {
      if (conversation.isGroupLeft) {
        return strings.groupLeftCannotSend;
      }
      if (conversation.isGroupKicked) {
        return strings.groupKickedCannotSend;
      }
      if (conversation.isGroupDisbanded) {
        return strings.groupDisbandedCannotSend;
      }
    }
    if (groupSettingsState == null) {
      return null;
    }
    if (groupSettingsState.membershipBlocked) {
      return strings.chatGroupRemovedCannotSend;
    }
    final muteEndTime = groupSettingsState.currentUserMuteEndTime?.toLocal();
    if (muteEndTime != null && muteEndTime.isAfter(DateTime.now())) {
      return strings.chatGroupMutedUntil(_formatMuteUntil(muteEndTime));
    }
    final canBypassMuteAll =
        groupSettingsState.currentUserRoleCode == 1 ||
        groupSettingsState.currentUserRoleCode == 2;
    if (groupSettingsState.muteAll && !canBypassMuteAll) {
      return strings.chatGroupMuteAllEnabled;
    }
    return null;
  }

  String? _resolveMemberCount(
    BuildContext context, {
    required Conversation? conversation,
    required GroupSettingsState? groupSettingsState,
  }) {
    final count =
        groupSettingsState?.memberCount ?? conversation?.groupMemberCount ?? 0;
    if (count <= 0) {
      return null;
    }
    return AppLocalizations.of(context).contactsCountPeople(count);
  }

  String _groupNoticeSignature(String notice) => notice.trim();

  String? _resolveGroupSubtitle(
    BuildContext context, {
    required String? memberCount,
  }) {
    final typingText = _resolveTypingText(context, isGroupChat: true);
    if (typingText != null) {
      return typingText;
    }
    return memberCount;
  }

  String _resolveSingleChatSubtitle(
    BuildContext context, {
    required Conversation? conversation,
  }) {
    final typingText = _resolveTypingText(context, isGroupChat: false);
    if (typingText != null) {
      return typingText;
    }
    if (conversation == null) {
      return AppLocalizations.of(context).chatPresenceOffline;
    }
    if (conversation.online) {
      return _buildPresenceOnlineText(context, conversation.onlineDeviceTypes);
    }
    final lastActiveTime = conversation.lastActiveTime ?? 0;
    if (lastActiveTime > 0) {
      return _buildPresenceLastActiveText(context, lastActiveTime);
    }
    return AppLocalizations.of(context).chatPresenceOffline;
  }

  String? _resolveTypingText(
    BuildContext context, {
    required bool isGroupChat,
  }) {
    if (_typingEntries.isEmpty) {
      return null;
    }
    final strings = AppLocalizations.of(context);
    final now = DateTime.now();
    final active = _typingEntries.values
        .where((item) => now.difference(item.timestamp) < _typingTimeout)
        .toList(growable: false);
    if (active.isEmpty) {
      return null;
    }
    if (!isGroupChat) {
      return strings.chatTypingDirect;
    }
    if (active.length == 1) {
      return strings.chatTypingNamed(active.first.userName);
    }
    final names = active.take(3).map((item) => item.userName).toList();
    final joined = strings.localeName.toLowerCase().startsWith('zh')
        ? names.join('、')
        : names.join(', ');
    if (active.length > 3) {
      return strings.chatTypingNamedMany(joined);
    }
    return strings.chatTypingNamed(joined);
  }

  String _buildPresenceOnlineText(BuildContext context, List<int> deviceTypes) {
    final strings = AppLocalizations.of(context);
    final hasMobile = deviceTypes.contains(1);
    final hasWeb = deviceTypes.any((item) => item == 2 || item == 3);
    if (hasMobile && hasWeb) {
      return strings.chatPresenceMultiDeviceOnline;
    }
    if (hasMobile) {
      return strings.chatPresenceMobileOnline;
    }
    if (hasWeb) {
      return strings.chatPresenceWebOnline;
    }
    return strings.chatPresenceOnline;
  }

  String _buildPresenceLastActiveText(BuildContext context, int timestamp) {
    final strings = AppLocalizations.of(context);
    if (timestamp <= 0) {
      return strings.chatPresenceOffline;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    if (diff < 2 * 60 * 1000) {
      return strings.chatPresenceJustNowActive;
    }
    if (diff < 60 * 60 * 1000) {
      return strings.chatPresenceMinutesAgoActive(
        (diff / (60 * 1000)).floor().clamp(1, 59),
      );
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';
    if (diff < 24 * 60 * 60 * 1000) {
      return strings.chatPresenceTodayActiveAt(time);
    }
    if (diff < 48 * 60 * 60 * 1000) {
      return strings.chatPresenceYesterdayActiveAt(time);
    }
    if (diff < 7 * 24 * 60 * 60 * 1000) {
      final weekdays = <String>[
        strings.chatPresenceSunday,
        strings.chatPresenceMonday,
        strings.chatPresenceTuesday,
        strings.chatPresenceWednesday,
        strings.chatPresenceThursday,
        strings.chatPresenceFriday,
        strings.chatPresenceSaturday,
      ];
      return strings.chatPresenceWeekdayActiveAt(
        weekdays[dt.weekday % 7],
        time,
      );
    }
    return strings.chatPresenceRecentlyActive;
  }

  bool _resolveCanMentionAll({
    required List<GroupMember> members,
    required String currentUserId,
  }) {
    for (final member in members) {
      if (member.userId == currentUserId) {
        return member.role == 1 || member.role == 2;
      }
    }
    return false;
  }

  List<ChatMentionPanelItem> _filterMentionMembers({
    required List<GroupMember> members,
    required String keyword,
  }) {
    if (members.isEmpty) {
      return const <ChatMentionPanelItem>[];
    }
    final mentionItems = _buildMentionPanelItems(members);
    final trimmedKeyword = keyword.trim().toLowerCase();
    if (trimmedKeyword.isEmpty) {
      return mentionItems;
    }
    return mentionItems
        .where((item) {
          final displayName = item.displayName.trim().toLowerCase();
          final mentionName = item.mentionName.trim().toLowerCase();
          final userName = item.userName.trim().toLowerCase();
          return displayName.contains(trimmedKeyword) ||
              mentionName.contains(trimmedKeyword) ||
              userName.contains(trimmedKeyword);
        })
        .toList(growable: false);
  }

  List<ChatMentionPanelItem> _buildMentionPanelItems(
    List<GroupMember> members,
  ) {
    final nameCounter = <String, int>{};
    for (final member in members) {
      final displayName = _buildMentionDisplayName(member);
      if (displayName.isEmpty) {
        continue;
      }
      nameCounter.update(displayName, (value) => value + 1, ifAbsent: () => 1);
    }

    final items = <ChatMentionPanelItem>[];
    for (final member in members) {
      final displayName = _buildMentionDisplayName(member);
      final userId = member.userId.trim();
      if (displayName.isEmpty || userId.isEmpty) {
        continue;
      }
      items.add(
        ChatMentionPanelItem(
          userId: userId,
          displayName: displayName,
          mentionName: _buildMentionAlias(
            displayName: displayName,
            userName: member.userName.trim(),
            userId: userId,
            duplicateCount: nameCounter[displayName] ?? 1,
          ),
          userName: member.userName.trim(),
          avatarUrl: member.avatarUrl,
        ),
      );
    }
    return items;
  }

  static const int _composerExpandTriggerLine = 3;
  static const int _composerMaxLines = 9;
  static const double _composerMinHeight = 40;
  static const double _composerLineHeight = 24;
  static const double _composerVerticalPadding = 16;
  static const double _composerMaxHeight = 232;
  static const double _composerWrapUnitsPerLine = 13;

  bool _showExpandIcon(String text) {
    return !_isVoiceMode &&
        text.trim().isNotEmpty &&
        _composerLineCount >= _composerExpandTriggerLine;
  }

  double _composerHeight() {
    final normalizedLineCount = _composerLineCount.clamp(1, _composerMaxLines);
    final height =
        _composerVerticalPadding + normalizedLineCount * _composerLineHeight;
    if (height < _composerMinHeight) {
      return _composerMinHeight;
    }
    if (height > _composerMaxHeight) {
      return _composerMaxHeight;
    }
    return height;
  }

  void _updateComposerLineCount(String text) {
    final nextLineCount = _estimateComposerLineCount(text);
    if (nextLineCount == _composerLineCount) {
      return;
    }
    setState(() {
      _composerLineCount = nextLineCount;
    });
  }

  int _estimateComposerLineCount(String text) {
    final normalizedText = text.replaceAll('\r\n', '\n');
    if (normalizedText.isEmpty) {
      return 1;
    }
    final segments = normalizedText.split('\n');
    var lineCount = 0;
    for (final segment in segments) {
      final units = _measureComposerTextUnits(segment);
      final wrappedLines = units <= 0
          ? 1
          : (units / _composerWrapUnitsPerLine).ceil();
      lineCount += wrappedLines;
    }
    if (lineCount < 1) {
      return 1;
    }
    if (lineCount > _composerMaxLines) {
      return _composerMaxLines;
    }
    return lineCount;
  }

  double _measureComposerTextUnits(String text) {
    return EmojiComposerTextEditingController.measureVisualWidthUnits(text);
  }

  void _toggleFullExpand() {
    setState(() {
      _isFullExpanded = !_isFullExpanded;
      if (_isFullExpanded) {
        _isMorePanelVisible = false;
        _isEmojiPanelVisible = false;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _composerFocusNode.requestFocus();
    });
  }

  void _handleComposerChanged(
    String value, {
    required bool isGroupChat,
    required String? groupId,
    required bool isReadOnly,
  }) {
    _handleTypingComposerChanged(
      value,
      isGroupChat: isGroupChat,
      groupId: groupId,
      isReadOnly: isReadOnly,
    );
    if (!isGroupChat || _isVoiceMode || isReadOnly) {
      if (_isMentionPanelVisible) {
        _closeMentionPanel();
      }
      return;
    }
    final query = _resolveMentionTailQuery(value);
    if (query == null || groupId == null || groupId.trim().isEmpty) {
      if (_isMentionPanelVisible) {
        _closeMentionPanel();
      }
      return;
    }
    final nextKeyword = query.trim();
    if (!_isMentionPanelVisible) {
      setState(() {
        _isMorePanelVisible = false;
        _isEmojiPanelVisible = false;
        _isMentionPanelVisible = true;
        _mentionKeyword = nextKeyword;
      });
      _mentionSearchController
        ..text = nextKeyword
        ..selection = TextSelection.collapsed(offset: nextKeyword.length);
      return;
    }
    if (_mentionKeyword != nextKeyword ||
        _mentionSearchController.text != nextKeyword) {
      setState(() {
        _mentionKeyword = nextKeyword;
      });
      _mentionSearchController
        ..text = nextKeyword
        ..selection = TextSelection.collapsed(offset: nextKeyword.length);
    }
  }

  void _handleTypingComposerChanged(
    String value, {
    required bool isGroupChat,
    required String? groupId,
    required bool isReadOnly,
  }) {
    if (_isVoiceMode || isReadOnly) {
      _timerManager.cancel('typingSend');
      return;
    }
    if (value.trim().isEmpty) {
      _timerManager.cancel('typingSend');
      return;
    }
    final session = ref.read(authSessionProvider);
    final targetId = widget.args.targetId?.trim() ?? '';
    final resolvedGroupId = isGroupChat ? (groupId?.trim() ?? '') : '';
    final receiverId = isGroupChat ? '0' : targetId;
    if ((!isGroupChat && targetId.isEmpty) ||
        session.userId.trim().isEmpty ||
        session.tenantId.trim().isEmpty) {
      return;
    }
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final senderName = profile?.nickname.trim().isNotEmpty == true
        ? profile!.nickname.trim()
        : '';
    _timerManager.cancel('typingSend');
    _timerManager.setOnce('typingSend', Timer(_typingDebounce, () {
      unawaited(
        ref
            .read(socketOutboundSenderProvider)
            .sendTypingIfConnected(
              senderId: session.userId,
              receiverId: receiverId,
              groupId: resolvedGroupId.isEmpty ? '0' : resolvedGroupId,
              tenantId: session.tenantId,
              senderName: senderName,
            ),
      );
    }));
  }

  void _startTypingCleanupTimer() {
    _timerManager.cancel('typingCleanup');
    _timerManager.setPeriodic('typingCleanup', Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _typingEntries.isEmpty) {
        return;
      }
      final now = DateTime.now();
      final expiredKeys = _typingEntries.entries
          .where(
            (entry) => now.difference(entry.value.timestamp) >= _typingTimeout,
          )
          .map((entry) => entry.key)
          .toList(growable: false);
      if (expiredKeys.isEmpty) {
        return;
      }
      setState(() {
        for (final key in expiredKeys) {
          _typingEntries.remove(key);
        }
      });
    }));
  }

  String? _resolveMentionTailQuery(String text) {
    if (text.isEmpty) {
      return null;
    }
    var tailStart = text.length - 1;
    while (tailStart >= 0) {
      final char = text[tailStart];
      if (char == ' ' || char == '\n' || char == '\r' || char == '\t') {
        break;
      }
      tailStart--;
    }
    final token = text.substring(tailStart + 1);
    if (token.isEmpty || !token.startsWith('@')) {
      return null;
    }
    if (token.length == 1) {
      return '';
    }
    return token.substring(1);
  }

  void _closeMentionPanel() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isMentionPanelVisible = false;
      _mentionKeyword = '';
    });
    _mentionSearchController.clear();
  }

  void _resetMentionState() {
    _mentionNameToUserId.clear();
    if (_isMentionPanelVisible) {
      _closeMentionPanel();
      return;
    }
    _mentionKeyword = '';
    _mentionSearchController.clear();
  }

  String _buildMentionDisplayName(GroupMember member) {
    final nickname = member.nickname.trim();
    if (nickname.isNotEmpty) {
      return nickname;
    }
    return member.userName.trim();
  }

  String _buildMentionAlias({
    required String displayName,
    required String userName,
    required String userId,
    required int duplicateCount,
  }) {
    if (displayName.isEmpty) {
      return userName.isNotEmpty ? userName : userId;
    }
    if (duplicateCount <= 1) {
      return displayName;
    }
    final suffix = userName.isNotEmpty ? userName : userId;
    if (suffix.isEmpty) {
      return displayName;
    }
    return '$displayName($suffix)';
  }

  void _applyMentionMemberSelection(ChatMentionPanelItem item) {
    final mentionName = item.mentionName.trim();
    final userId = item.userId.trim();
    if (mentionName.isEmpty || userId.isEmpty) {
      return;
    }
    _applyMentionSelection(mentionName: mentionName, userId: userId);
  }

  void _applyMentionSelection({
    required String mentionName,
    required String userId,
  }) {
    final composer = ref.read(chatComposerControllerProvider);
    final currentText = composer.textController.text;
    final query = _resolveMentionTailQuery(currentText);
    final nextText = query == null
        ? '$currentText@$mentionName '
        : '${currentText.substring(0, currentText.length - query.length - 1)}@$mentionName ';
    _mentionNameToUserId[mentionName] = userId;
    composer.textController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
    _closeMentionPanel();
  }

  ({List<String> atUserIds, List<MentionSegment> mentions})
  _buildMentionPayload(String text) {
    final mentions = <MentionSegment>[];
    final atUserIds = <String>[];
    for (final range in _parseMentionRanges(text)) {
      final mentionName = text.substring(range.startIndex + 1, range.endIndex);
      final userId = _mentionNameToUserId[mentionName];
      if (userId == null || userId.isEmpty) {
        continue;
      }
      if (!atUserIds.contains(userId)) {
        atUserIds.add(userId);
      }
      mentions.add(
        MentionSegment(
          userId: userId,
          nickname: mentionName,
          startIndex: range.startIndex,
          endIndex: range.endIndex,
        ),
      );
    }
    return (atUserIds: atUserIds, mentions: mentions);
  }

  List<_MentionRange> _parseMentionRanges(String text) {
    final mentions = <_MentionRange>[];
    var index = 0;
    while (index < text.length) {
      if (text[index] != '@') {
        index++;
        continue;
      }
      final nextIndex = index + 1;
      if (nextIndex >= text.length) {
        index++;
        continue;
      }
      final nextChar = text[nextIndex];
      if (_isMentionBoundary(nextChar) || nextChar == '@') {
        index++;
        continue;
      }
      var endIndex = nextIndex;
      while (endIndex < text.length) {
        final currentChar = text[endIndex];
        if (_isMentionBoundary(currentChar) || currentChar == '@') {
          break;
        }
        endIndex++;
      }
      if (endIndex > nextIndex) {
        mentions.add(_MentionRange(startIndex: index, endIndex: endIndex));
        index = endIndex;
        continue;
      }
      index++;
    }
    return mentions;
  }

  bool _isMentionBoundary(String value) =>
      value == ' ' || value == '\t' || value == '\n' || value == '\r';

  void _openMentionUserProfile(String userId, String displayName) {
    final resolvedUserId = userId.trim();
    if (resolvedUserId.isEmpty || resolvedUserId == '0' || !mounted) {
      return;
    }
    context.pushNamed(
      RouteNames.contactsProfile,
      pathParameters: <String, String>{'userId': resolvedUserId},
      extra: <String, String>{'name': displayName.trim(), 'departmentName': ''},
    );
  }

  void _openGroupAnnouncement(
    BuildContext context, {
    required String? groupId,
    required String groupName,
  }) {
    if (groupId == null || groupId.trim().isEmpty) {
      return;
    }
    context.pushNamed(
      RouteNames.groupAnnouncement,
      extra: GroupSettingDetailArgs(groupId: groupId, groupName: groupName),
    );
  }

  AppBar _buildSelectionAppBar(AppLocalizations strings) {
    return AppBar(
      toolbarHeight: 44,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: Border(
        bottom: BorderSide(color: ThemeColors.divider(context), width: 0.5),
      ),
      leadingWidth: 80,
      leading: InkWell(
        onTap: _exitSelectionMode,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.cancelAction,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 0,
      centerTitle: true,
      title: Text(
        strings.chatSelectedCount(_selectedMessageIds.length),
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ThemeColors.textPrimary(context),
        ),
      ),
    );
  }

  Future<void> _deleteSelectedMessages(BuildContext context) async {
    final strings = ref.read(appStringsProvider);
    final selectedMessages = _selectedMessages;
    if (selectedMessages.isEmpty) {
      _showAttachmentError(context, strings.chatChooseDeleteMessage);
      return;
    }
    final confirmed = await _showLegacyConfirmDialog(
      context,
      title: strings.chatMultiDeleteTitle,
      content: strings.chatMultiDeleteContent(selectedMessages.length),
    );
    if (confirmed != true) {
      return;
    }
    try {
      final timelineController = ref.read(
        chatTimelineControllerProvider(widget.args.chatId).notifier,
      );
      for (final message in selectedMessages) {
        final selectionKey = _messageSelectionKey(message);
        if (selectionKey.isEmpty) {
          continue;
        }
        timelineController.removeByAnyMessageId(selectionKey);
      }
      _exitSelectionMode();
      if (!mounted) {
        return;
      }
      _showAttachmentSuccess(this.context, strings.chatDeleteSuccess);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showAttachmentError(this.context, strings.chatDeleteFailed);
    }
  }

  void _openMessagePreview(BuildContext context, Message message) {
    final suppressedId = _suppressNextOpenMessageId;
    if (suppressedId != null &&
        suppressedId.isNotEmpty &&
        suppressedId == _messageSelectionKey(message)) {
      _suppressNextOpenMessageId = null;
      return;
    }
    if (_isLinkMessage(message)) {
      unawaited(_openLinkMessage(message));
      return;
    }
    if (message.type == MessageType.voice &&
        message.status == MessageStatus.failed) {
      unawaited(_retryVoiceMessage(message));
      return;
    }
    if (message.type == MessageType.voice &&
        message.status == MessageStatus.sending) {
      return;
    }
    if (message.type == MessageType.voice) {
      final messageKey = message.clientMessageId ?? message.messageId;
      if (messageKey.isNotEmpty && _activePlayingVoiceMessageId == messageKey) {
        unawaited(_pauseVoicePlayback(message));
      } else if (messageKey.isNotEmpty &&
          _activePausedVoiceMessageId == messageKey) {
        unawaited(_resumeVoicePlayback(message));
      } else {
        unawaited(_playVoicePlayback(message));
      }
      return;
    }
    if (_isContactCardMessage(message)) {
      final userId = message.extra.contactUserId;
      if (userId == null || userId.isEmpty) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatContactMissing,
        );
        return;
      }
      context.pushNamed(
        RouteNames.contactsProfile,
        pathParameters: <String, String>{'userId': userId},
        extra: <String, String>{
          'name': message.extra.contactDisplayName ?? message.senderName,
          'departmentName': message.extra.contactDepartmentName ?? '',
        },
      );
      return;
    }
    if (message.type == MessageType.location) {
      _openLocationMessage(context, message);
      return;
    }
    if (message.type == MessageType.image) {
      unawaited(_openImageMessagePreview(context, message));
      return;
    }
    if (message.type == MessageType.custom) {
      if (_isContactCardMessage(message)) {
        final userId = message.extra.contactUserId;
        if (userId == null || userId.isEmpty) {
          _showAttachmentError(
            context,
            ref.read(appStringsProvider).chatContactMissing,
          );
          return;
        }
        context.pushNamed(
          RouteNames.contactsProfile,
          pathParameters: <String, String>{'userId': userId},
          extra: <String, String>{
            'name': message.extra.contactDisplayName ?? message.senderName,
            'departmentName': message.extra.contactDepartmentName ?? '',
          },
        );
        return;
      }
      if (message.extra.customType?.toUpperCase() == 'FORWARD_COMBINE') {
        final messageId = message.messageId.trim();
        if (messageId.isNotEmpty && messageId != '0') {
          context.pushNamed(
            RouteNames.chatForwardCombineDetail,
            extra: ForwardCombineDetailRouteArgs(
              messageId: messageId,
              trace: <String>[messageId],
            ),
          );
          return;
        }
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatOpenFailed,
        );
      }
      return;
    }
    if (message.type == MessageType.sticker ||
        message.type == MessageType.emoji) {
      return;
    }
    if (message.type != MessageType.file &&
        message.type != MessageType.video &&
        message.type != MessageType.voice) {
      return;
    }
    final previewUrl = _resolvePreviewFileUrl(message);
    final fileId = message.extra.fileId?.trim() ?? '';
    if (fileId.isEmpty && previewUrl.isEmpty) {
      _showAttachmentError(
        context,
        ref.read(appStringsProvider).chatOpenFailed,
      );
      return;
    }
    if (message.type == MessageType.video) {
      context.pushNamed(
        RouteNames.chatVideoPlayer,
        extra: VideoPlayerRouteArgs(
          url: previewUrl,
          fileId: fileId,
          title: _previewFileNameFor(message),
        ),
      );
      return;
    }
    context.pushNamed(
      RouteNames.filePreview,
      extra: FilePreviewRouteArgs(
        fileId: fileId,
        fileName: _previewFileNameFor(message),
        mimeType: _previewMimeTypeFor(message),
        fileSize: message.extra.fileSize ?? 0,
        fileUrl: previewUrl.isEmpty ? null : previewUrl,
        messageId: message.messageId,
        chatId: message.chatId,
        sourceType: message.type.name,
      ),
    );
  }

  Future<void> _openImageMessagePreview(
    BuildContext context,
    Message message,
  ) async {
    final strings = ref.read(appStringsProvider);
    var url = _resolvePreviewFileUrl(message);
    final fileId = message.extra.fileId?.trim() ?? '';
    if (fileId.isNotEmpty) {
      try {
        final signed = await ref
            .read(fileRepositoryProvider)
            .getPresignedGetUrl(fileId: fileId);
        url = signed.toString();
      } catch (e) {
        debugPrint('[ChatPage] get presigned url failed: $e');
      }
    }
    if (url.trim().isEmpty) {
      if (context.mounted) {
        _showAttachmentError(context, strings.chatOpenFailed);
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'image-preview',
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
                  errorBuilder: (context, error, stackTrace) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        url,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _playVoicePlayback(Message message) async {
    final strings = ref.read(appStringsProvider);
    final messageKey = message.clientMessageId ?? message.messageId;
    if (messageKey.isEmpty) {
      return;
    }
    if (_activePlayingVoiceMessageId == messageKey) {
      return;
    }
    final localPath = await _resolveVoicePlaybackUrl(message);
    if (localPath == null) {
      if (mounted) {
        _showAttachmentError(context, strings.chatVoiceFileUnavailable);
      }
      return;
    }
    final playback = ref.read(audioPlaybackServiceProvider);
    final session = ++_voicePlaybackSession;
    try {
      await playback.stop();
      await _bindVoicePlayback(messageKey, session);
      // 本地缓存文件使用 setFilePath，否则使用 setUrl
      if (localPath.startsWith('/') || localPath.startsWith('file://')) {
        await playback.setFilePath(localPath);
      } else {
        await playback.setUrl(localPath);
      }
      await playback.seek(Duration.zero);
      if (!mounted || session != _voicePlaybackSession) {
        return;
      }
      setState(() {
        _activePlayingVoiceMessageId = messageKey;
        _activePausedVoiceMessageId = null;
        _activeVoicePlaybackProgressMs = 0;
        _activeVoicePlaybackDurationMs =
            message.extra.durationMs ??
            ((message.extra.duration ?? 1).clamp(1, 60) * 1000);
      });
      await playback.play();
      _markVoicePlayedOnOpen(message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showAttachmentError(context, strings.chatVoicePlayUrlFailed);
    }
  }

  Future<void> _pauseVoicePlayback(Message message) async {
    final messageKey = message.clientMessageId ?? message.messageId;
    if (messageKey.isEmpty || _activePlayingVoiceMessageId != messageKey) {
      return;
    }
    final playback = ref.read(audioPlaybackServiceProvider);
    await playback.pause();
  }

  Future<void> _resumeVoicePlayback(Message message) async {
    final messageKey = message.clientMessageId ?? message.messageId;
    if (messageKey.isEmpty) {
      return;
    }
    if (_activePausedVoiceMessageId != messageKey) {
      await _playVoicePlayback(message);
      return;
    }
    final playback = ref.read(audioPlaybackServiceProvider);
    await playback.play();
  }

  Future<void> _replayVoicePlayback(Message message) async {
    final messageKey = message.clientMessageId ?? message.messageId;
    if (messageKey.isNotEmpty &&
        (_activePlayingVoiceMessageId == messageKey ||
            _activePausedVoiceMessageId == messageKey)) {
      final playback = ref.read(audioPlaybackServiceProvider);
      try {
        await playback.seek(Duration.zero);
        if (!mounted) {
          return;
        }
        setState(() {
          _activePlayingVoiceMessageId = messageKey;
          _activePausedVoiceMessageId = null;
          _activeVoicePlaybackProgressMs = 0;
          _activeVoicePlaybackDurationMs =
              message.extra.durationMs ??
              ((message.extra.duration ?? 1).clamp(1, 60) * 1000);
        });
        await playback.play();
        _markVoicePlayedOnOpen(message);
        return;
      } catch (_) {
        // fallback to full reload path
      }
    }
    await _playVoicePlayback(message);
  }

  Future<String?> _resolveVoicePlaybackUrl(Message message) async {
    final fileId = message.extra.fileId?.trim() ?? '';
    String url;
    if (fileId.isNotEmpty && fileId != '0') {
      url = (await ref
              .read(fileRepositoryProvider)
              .getPresignedGetUrl(fileId: fileId))
          .toString();
    } else {
      final directUrl = message.extra.fileUrl?.trim() ?? '';
      if (directUrl.isEmpty) {
        return null;
      }
      url = directUrl;
    }

    // 优先使用本地缓存，缓存未命中时后台下载后返回本地路径
    final localPath = await AudioCacheManager.getAudioFile(url);
    return localPath;
  }

  Future<void> _bindVoicePlayback(String messageKey, int session) async {
    final playback = ref.read(audioPlaybackServiceProvider);
    await _voicePositionSubscription?.cancel();
    await _voiceDurationSubscription?.cancel();
    await _voicePlayerStateSubscription?.cancel();
    _voicePositionSubscription = playback.positionStream.listen((position) {
      if (!mounted || session != _voicePlaybackSession) {
        return;
      }
      setState(() {
        if (_activePlayingVoiceMessageId == messageKey ||
            _activePausedVoiceMessageId == messageKey) {
          _activeVoicePlaybackProgressMs = position.inMilliseconds;
        }
      });
    });
    _voiceDurationSubscription = playback.durationStream.listen((duration) {
      if (!mounted || duration == null || session != _voicePlaybackSession) {
        return;
      }
      setState(() {
        if (_activePlayingVoiceMessageId == messageKey ||
            _activePausedVoiceMessageId == messageKey) {
          _activeVoicePlaybackDurationMs = duration.inMilliseconds;
        }
      });
    });
    _voicePlayerStateSubscription = playback.playerStateStream.listen((state) {
      if (!mounted || session != _voicePlaybackSession) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          if (_activePlayingVoiceMessageId == messageKey ||
              _activePausedVoiceMessageId == messageKey) {
            _activePlayingVoiceMessageId = null;
            _activePausedVoiceMessageId = null;
            _activeVoicePlaybackProgressMs = 0;
            _activeVoicePlaybackDurationMs = 0;
          }
        });
        return;
      }
      if (state.playing) {
        setState(() {
          _activePlayingVoiceMessageId = messageKey;
          _activePausedVoiceMessageId = null;
        });
        return;
      }
      if (state.processingState == ProcessingState.ready &&
          _activePlayingVoiceMessageId == messageKey) {
        setState(() {
          _activePausedVoiceMessageId = messageKey;
          _activePlayingVoiceMessageId = null;
        });
      }
    });
  }

  void _markVoicePlayedOnOpen(Message message) {
    final messageId = message.messageId.trim();
    if (message.isOutgoing ||
        messageId.isEmpty ||
        messageId == '0' ||
        (message.extra.voicePlayed ?? false)) {
      return;
    }
    ref
        .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
        .markVoicePlayed(messageId: messageId);
    unawaited(_persistVoicePlayed(messageId));
    _scheduleVoicePlayedSync(messageId);
  }

  Future<void> _persistVoicePlayed(String messageId) async {
    if (messageId.isEmpty || messageId == '0') {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voicePlayedStorageKey(messageId), '1');
  }

  Future<bool> _hasVoiceBeenPlayed(String messageId) async {
    if (messageId.isEmpty || messageId == '0') {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_voicePlayedStorageKey(messageId)) == '1';
  }

  String _voicePlayedStorageKey(String messageId) =>
      '${StorageKeyRegistry.voicePlayedPrefix}.$messageId';

  void _scheduleVoicePlayedSync(String messageId) {
    if (messageId.isEmpty || messageId == '0') {
      return;
    }
    _voicePlayedPendingSync.putIfAbsent(messageId, () => true);
    if (!_timerManager.isActive('voicePlayedSync')) {
      _timerManager.setOnce('voicePlayedSync', Timer(_voicePlayedSyncDebounce, () {
        unawaited(_flushVoicePlayedSyncQueue());
      }));
    }
  }

  Future<void> _flushVoicePlayedSyncQueue({bool force = false}) async {
    if (force) {
      _timerManager.cancel('voicePlayedSync');
    }
    if (_voicePlayedSyncInFlight) {
      if (!force && _voicePlayedPendingSync.isNotEmpty) {
        _scheduleNextVoicePlayedSync();
      }
      return;
    }
    if (_voicePlayedPendingSync.isEmpty) {
      return;
    }
    _voicePlayedSyncInFlight = true;
    final repository = ref.read(messageRepositoryProvider);
    try {
      while (_voicePlayedPendingSync.isNotEmpty) {
        final batchIds = _takeVoicePlayedSyncBatch(_voicePlayedSyncBatchSize);
        if (batchIds.isEmpty) {
          break;
        }
        try {
          if (batchIds.length == 1) {
            await repository.markVoicePlayed(messageId: batchIds.first);
          } else {
            await repository.markVoicePlayedBatch(messageIds: batchIds);
          }
        } catch (_) {
          for (final id in batchIds) {
            _voicePlayedPendingSync.putIfAbsent(id, () => true);
          }
          break;
        }
      }
    } finally {
      _voicePlayedSyncInFlight = false;
    }
    if (!force && _voicePlayedPendingSync.isNotEmpty) {
      _scheduleNextVoicePlayedSync();
    }
  }

  void _scheduleNextVoicePlayedSync() {
    if (!_timerManager.isActive('voicePlayedSync')) {
      _timerManager.setOnce('voicePlayedSync', Timer(_voicePlayedSyncDebounce, () {
        unawaited(_flushVoicePlayedSyncQueue());
      }));
    }
  }

  List<String> _takeVoicePlayedSyncBatch(int maxSize) {
    final keys = _voicePlayedPendingSync.keys
        .take(maxSize)
        .toList(growable: false);
    for (final key in keys) {
      _voicePlayedPendingSync.remove(key);
    }
    return keys;
  }

  void _startVoicePlayedCompensation() {
    _timerManager.cancel('voicePlayedCompensate');
    _timerManager.setPeriodic('voicePlayedCompensate', Timer.periodic(
      _voicePlayedCompensateInterval,
      (_) => unawaited(_restoreVoicePlayedCompensationOnce()),
    ));
  }

  Future<void> _restoreVoicePlayedCompensationOnce() async {
    final chatId = widget.args.chatId.trim();
    if (chatId.isEmpty || chatId == '0' || _voicePlayedCompensateInFlight) {
      return;
    }
    final pendingVoiceIds = await _collectUnplayedVoiceMessageIds(
      _voicePlayedCompensateMaxIds,
    );
    if (!mounted || pendingVoiceIds.isEmpty) {
      return;
    }
    _voicePlayedCompensateInFlight = true;
    try {
      final repository = ref.read(messageRepositoryProvider);
      var offset = 0;
      while (offset < pendingVoiceIds.length) {
        if (!mounted) break;
        final batch = pendingVoiceIds
            .skip(offset)
            .take(_voicePlayedCompensateBatchSize)
            .toList(growable: false);
        offset += _voicePlayedCompensateBatchSize;
        if (batch.isEmpty) {
          continue;
        }
        final playedIds = await repository.getVoicePlayedStatus(
          chatId: chatId,
          messageIds: batch,
        );
        if (playedIds.isEmpty) {
          continue;
        }
        for (final playedId in playedIds) {
          if (!mounted) break;
          _voicePlayedPendingSync.remove(playedId);
          await _persistVoicePlayed(playedId);
          ref
              .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
              .markVoicePlayed(messageId: playedId);
        }
      }
    } catch (_) {
      // Ignore compensation failure and retry on next interval.
    } finally {
      _voicePlayedCompensateInFlight = false;
    }
  }

  Future<List<String>> _collectUnplayedVoiceMessageIds(int limit) async {
    if (!mounted) return <String>[];
    final result = <String>[];
    final seen = <String>{};
    final List<Message> messages;
    try {
      messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    } catch (_) {
      return <String>[];
    }
    for (final item in messages.reversed) {
      if (item.isOutgoing || item.type != MessageType.voice) {
        continue;
      }
      final messageId = item.messageId.trim();
      if (messageId.isEmpty ||
          messageId == '0' ||
          item.extra.voicePlayed == true ||
          seen.contains(messageId)) {
        continue;
      }
      if (await _hasVoiceBeenPlayed(messageId)) {
        continue;
      }
      seen.add(messageId);
      result.add(messageId);
      if (result.length >= limit) {
        break;
      }
    }
    return result;
  }

  Future<void> _loadRecallConfig() async {
    try {
      final seconds = await ref
          .read(messageRepositoryProvider)
          .getRecallWindowSeconds();
      if (!mounted || seconds <= 0) {
        return;
      }
      setState(() {
        _recallWindow = Duration(seconds: seconds);
      });
    } catch (_) {
      // Keep local default.
    }
  }

  Future<void> _showReadReceiptSheet(
    BuildContext context, {
    required String chatTitle,
    required Message message,
  }) {
    final messageId = _resolveReadReceiptTargetMessageId(message);
    if (messageId.isEmpty) {
      return Future<void>.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ReadReceiptBottomSheet(
          messageId: messageId,
          chatTitle: chatTitle,
          messagePreview: _buildQuotePreview(message),
          isVoiceMessage: message.type == MessageType.voice,
          initialSummary: ref
              .read(readReceiptSummaryStoreProvider.notifier)
              .getSummary(messageId),
          repository: ref.read(messageRepositoryProvider),
          onSummaryLoaded: (summary) {
            ref.read(readReceiptSummaryStoreProvider.notifier).hydrate(summary);
          },
          onShowNotice: (text) => _showAttachmentError(context, text),
        );
      },
    );
  }

  String _resolveReadReceiptTargetMessageId(Message message) {
    final messageId = message.messageId.trim();
    if (messageId.isNotEmpty && messageId != '0') {
      return messageId;
    }
    final clientMessageId = message.clientMessageId?.trim() ?? '';
    if (clientMessageId.isNotEmpty && clientMessageId != '0') {
      return clientMessageId;
    }
    return '';
  }

  bool _isReadReceiptMessageConfirmed(Message message) {
    if (!message.isOutgoing) {
      return false;
    }
    if (message.status == MessageStatus.sending ||
        message.status == MessageStatus.failed) {
      return false;
    }
    return _resolveReadReceiptTargetMessageId(message).isNotEmpty;
  }

  String _buildReadReceiptEntryText(
    Message message,
    AppLocalizations strings,
    ReadReceiptSummaryStoreState readReceiptSummaryState,
  ) {
    final defaultLabel = switch (message.status) {
      MessageStatus.sending => strings.messageSending,
      MessageStatus.sent => strings.messageSent,
      MessageStatus.delivered => strings.messageDelivered,
      MessageStatus.read => strings.messageRead,
      MessageStatus.recalled => strings.chatPreviewRecalled,
      MessageStatus.failed => strings.messageFailed,
    };
    if (!_isReadReceiptMessageConfirmed(message)) {
      return defaultLabel;
    }
    final messageId = _resolveReadReceiptTargetMessageId(message);
    if (messageId.isEmpty) {
      return defaultLabel;
    }
    final summary = readReceiptSummaryState.entries[messageId]?.summary;
    if (summary != null) {
      final unread = summary.unreadCount;
      if (unread > 0) {
        return strings.chatReadReceiptUnread(unread);
      }
      return strings.chatReadReceiptReadLabel;
    }
    return defaultLabel;
  }

  String _previewFileNameFor(Message message) {
    final fileName = message.extra.fileName?.trim() ?? '';
    if (fileName.isNotEmpty) {
      return fileName;
    }
    final pathName = basenameFromUrlOrPath(_resolvePreviewFileUrl(message));
    if (pathName.isNotEmpty) {
      return pathName;
    }
    final content = message.content.trim();
    if (content.isNotEmpty && !content.startsWith('{')) {
      return content;
    }
    if (message.type == MessageType.voice) {
      final format = message.extra.fileType?.trim() ?? 'mp3';
      return 'voice.$format';
    }
    return switch (message.type) {
      MessageType.image => 'image',
      MessageType.video => 'video',
      MessageType.sticker || MessageType.emoji => 'sticker',
      _ => 'file',
    };
  }

  String _previewMimeTypeFor(Message message) {
    final mimeType = message.extra.fileType?.trim() ?? '';
    if (mimeType.isNotEmpty) {
      return mimeType;
    }
    final fileName = _previewFileNameFor(message).toLowerCase();
    if (message.type == MessageType.image ||
        message.type == MessageType.sticker ||
        message.type == MessageType.emoji ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.webp') ||
        fileName.endsWith('.gif')) {
      return 'image/*';
    }
    if (fileName.endsWith('.mp4') ||
        fileName.endsWith('.mov') ||
        fileName.endsWith('.m4v') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mkv') ||
        fileName.endsWith('.webm')) {
      return 'video/*';
    }
    if (message.type == MessageType.voice ||
        fileName.endsWith('.mp3') ||
        fileName.endsWith('.wav') ||
        fileName.endsWith('.aac') ||
        fileName.endsWith('.m4a') ||
        fileName.endsWith('.ogg')) {
      return 'audio/*';
    }
    return 'application/octet-stream';
  }

  Future<void> _handleMorePanelAction({
    required WidgetRef ref,
    required ChatMorePanelAction action,
    required ChatPageState pageState,
    required String chatTitle,
  }) async {
    if (action != ChatMorePanelAction.favorite &&
        !_ensureConversationWritable(context)) {
      return;
    }
    if (action == ChatMorePanelAction.call) {
      _openCallPage(context, chatTitle: chatTitle, callType: CallType.video);
      return;
    }
    if (action == ChatMorePanelAction.favorite) {
      context.pushNamed(RouteNames.favorites);
      return;
    }

    final mediaController = ref.read(chatMediaControllerProvider(widget.args.chatId).notifier);
    ChatMorePanelResult result;
    switch (action) {
      case ChatMorePanelAction.album:
        await mediaController.pickAndUploadImage(
          entryArgs: pageState.entryArgs,
          chatTitle: chatTitle,
        );
        result = const ChatMorePanelResult();
      case ChatMorePanelAction.camera:
        await mediaController.captureWithCustomCameraAndUpload(
          entryArgs: pageState.entryArgs,
          chatTitle: chatTitle,
          context: context,
        );
        result = const ChatMorePanelResult();
      case ChatMorePanelAction.file:
        await mediaController.pickAndUploadFile(
          entryArgs: pageState.entryArgs,
          chatTitle: chatTitle,
        );
        result = const ChatMorePanelResult();
      case ChatMorePanelAction.location:
        result = const ChatMorePanelResult(
          followUpAction: ChatMorePanelFollowUpAction.openLocationPicker,
        );
      case ChatMorePanelAction.contact:
        result = const ChatMorePanelResult(
          followUpAction: ChatMorePanelFollowUpAction.openContactPicker,
        );
      case ChatMorePanelAction.favorite:
      case ChatMorePanelAction.call:
        result = const ChatMorePanelResult();
    }

    final error = ref.read(chatMediaControllerProvider(widget.args.chatId)).error;
    if (error != null && mounted) {
      if (_handleGroupLifecycleRequestError(
        context,
        error,
        fallbackNotice: ref.read(appStringsProvider).chatGroupRemovedCannotSend,
      )) {
        return;
      }
      _showAttachmentError(context, error.message);
      return;
    }
    final noticeMessage = result.noticeMessage;
    if (noticeMessage != null && noticeMessage.isNotEmpty && mounted) {
      _showAttachmentError(context, noticeMessage);
    }
    if (!context.mounted) {
      return;
    }
    switch (result.followUpAction) {
      case ChatMorePanelFollowUpAction.openLocationPicker:
        await _showLocationPicker();
      case ChatMorePanelFollowUpAction.openContactPicker:
        await _showContactPicker();
      case null:
        break;
    }
  }

  void _showAttachmentError(BuildContext context, String message) {
    _showLegacyToast(context, message);
  }

  String _resolveCurrentUserDisplayName(String currentUserId) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final nickname = profile?.nickname.trim() ?? '';
    if (nickname.isNotEmpty) {
      return nickname;
    }
    return currentUserId.trim().isEmpty ? '' : currentUserId.trim();
  }

  void _showAttachmentSuccess(BuildContext context, String message) {
    _showLegacyToast(context, message, success: true);
  }

  void _showLegacyToast(
    BuildContext context,
    String message, {
    bool success = false,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || message.trim().isEmpty) {
      return;
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final mediaQuery = MediaQuery.of(overlayContext);
        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: mediaQuery.size.width - 72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC1F2329),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (success) ...[
                      const AppIcon(
                        AppIconKind.checkCircle,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      entry.remove();
    });
  }

  Future<bool?> _showLegacyConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
  }) {
    final strings = ref.read(appStringsProvider);
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'legacy-confirm',
      barrierColor: const Color(0x66000000),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      content,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF646A73),
                      ),
                    ),
                  ),
                  Container(height: 0.5, color: const Color(0xFFE5E6EB)),
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(false),
                            child: Center(
                              child: Text(
                                cancelText ?? strings.cancelAction,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1F2329),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 0.5, color: const Color(0xFFE5E6EB)),
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(true),
                            child: Center(
                              child: Text(
                                confirmText ?? strings.confirmAction,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1677FF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showForwardConfirmDialog(
    BuildContext context, {
    required String title,
    required String targetLabel,
    required String previewText,
    required String confirmText,
  }) {
    final strings = ref.read(appStringsProvider);
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'forward-confirm',
      barrierColor: const Color(0x66000000),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2329),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE5E6EB),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3F5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: const AppIcon(
                                    AppIconKind.arrowForward,
                                    size: 20,
                                    color: Color(0xFF8F959E),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  targetLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2329),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 15),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            previewText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF646A73),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.5, color: const Color(0xFFE5E6EB)),
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(false),
                            child: Center(
                              child: Text(
                                strings.cancelAction,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1F2329),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 0.5, color: const Color(0xFFE5E6EB)),
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(true),
                            child: Center(
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1677FF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCallPage(
    BuildContext context, {
    required String chatTitle,
    required CallType callType,
  }) {
    final args = CallLaunchArgs.outgoing(
      callSessionId: '',
      chatId: widget.args.chatId,
      callType: callType,
      title: chatTitle,
    );
    context.pushNamed(RouteNames.callOutgoing, extra: args);
  }

  Future<void> _showMessageActions(
    BuildContext context,
    Message message, {
    Offset? globalPosition,
  }) {
    final actionController = ref.read(chatMessageActionControllerProvider(widget.args.chatId));
    final strings = ref.read(appStringsProvider);
    if (message.type == MessageType.system) {
      return Future.value();
    }
    final availableActions = _resolveMessageActions(context, message);
    if (availableActions.isEmpty) {
      return Future.value();
    }
    Future<void> actionHandler(
      BuildContext sheetContext,
      ChatMessageAction action,
    ) async {
      final navigator = Navigator.of(sheetContext);
      navigator.pop();
      if (action == ChatMessageAction.forward) {
        await _openForwardTargetPage(context, [message]);
        return;
      }
      if (action == ChatMessageAction.quote) {
        if (!_ensureConversationWritable(context)) {
          return;
        }
        _startQuoteReply(message);
        return;
      }
      if (action == ChatMessageAction.multi) {
        _enterSelectionMode(message);
        return;
      }
      if (action == ChatMessageAction.recall) {
        await _confirmRecallMessage(context, message);
        return;
      }
      if (action == ChatMessageAction.delete) {
        await _confirmDeleteMessage(context, message);
        return;
      }
      if (action == ChatMessageAction.favoriteSticker) {
        await _favoriteStickerMessage(context, message);
        return;
      }
      final result = await actionController.handleAction(
        action: action,
        message: message,
        copiedNotice: strings.chatCopySuccess,
        favoritedNotice: strings.chatFavoriteSuccess,
        deletedNotice: strings.chatDeleteSuccess,
      );
      if (!mounted || !context.mounted) {
        return;
      }
      if (result.noticeMessage.isNotEmpty) {
        if (action == ChatMessageAction.favorite) {
          _showAttachmentSuccess(context, result.noticeMessage);
        } else {
          _showAttachmentError(context, result.noticeMessage);
        }
      }
    }

    if (globalPosition == null) {
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChatMessageActionSheet(
                actions: availableActions,
                onSelectAction: (action) => actionHandler(sheetContext, action),
              ),
            ),
          );
        },
      );
    }
    return _showFloatingMessageActionMenu(
      context,
      actions: availableActions,
      globalPosition: globalPosition,
      onSelectAction: actionHandler,
    );
  }

  Future<void> _showFloatingMessageActionMenu(
    BuildContext context, {
    required List<({ChatMessageAction action, Object icon, String label})>
    actions,
    required Offset globalPosition,
    required Future<void> Function(
      BuildContext menuContext,
      ChatMessageAction action,
    )
    onSelectAction,
  }) {
    final mediaQuery = MediaQuery.of(context);
    const itemWidth = 70.0;
    const itemHeight = 70.0;
    const edgePadding = 10.0;
    final maxMenuWidth = mediaQuery.size.width - edgePadding * 2;
    final itemsPerRow = (maxMenuWidth / itemWidth).floor().clamp(
      1,
      actions.length,
    );
    final actualItemsPerRow = actions.length < itemsPerRow
        ? actions.length
        : itemsPerRow;
    final menuWidth = actualItemsPerRow * itemWidth;
    final rowCount = (actions.length / actualItemsPerRow).ceil();
    final menuHeight = rowCount * itemHeight;
    final headerTop = mediaQuery.padding.top + kToolbarHeight + 10;
    const footerHeight = 120.0;
    final minLeft = edgePadding;
    final maxLeft = mediaQuery.size.width - menuWidth - edgePadding;
    final minTop = headerTop;
    final availableBottom =
        mediaQuery.size.height - mediaQuery.padding.bottom - footerHeight - 10;
    var left = globalPosition.dx - menuWidth / 2;
    if (left < minLeft) {
      left = minLeft;
    } else if (left > maxLeft) {
      left = maxLeft;
    }
    var top = globalPosition.dy - menuHeight - 10;
    if (top < minTop) {
      top = globalPosition.dy + 10;
      if (top + menuHeight > availableBottom) {
        top = availableBottom - menuHeight;
        if (top < minTop) {
          top = globalPosition.dy - menuHeight / 2;
          if (top < minTop) {
            top = minTop;
          }
          if (top + menuHeight > availableBottom) {
            top = availableBottom - menuHeight;
          }
        }
      }
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'message-actions',
      barrierColor: const Color(0x1A000000),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: Container(
                  width: menuWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE5E6EB),
                      width: 0.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ChatMessageActionSheet(
                    actions: actions,
                    compact: true,
                    onSelectAction: (action) =>
                        onSelectAction(dialogContext, action),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<({ChatMessageAction action, Object icon, String label})>
  _resolveMessageActions(BuildContext context, Message message) {
    final strings = AppLocalizations.of(context);
    final isVoiceRestricted = message.type == MessageType.voice;
    final isLocationRestricted = message.type == MessageType.location;
    final canFavoriteMessage =
        _hasValidServerMessageId(message) && _canFavoriteMessageByType(message);
    final canCollectSticker = _canAddMessageToSticker(message);
    final alreadyCollectedSticker =
        canCollectSticker && _isMessageAlreadyCollectedToSticker(message);
    final canRecall = _canRecallMessage(message);

    final actions = <({ChatMessageAction action, Object icon, String label})>[
      if (isVoiceRestricted) ...[
        (
          action: ChatMessageAction.quote,
          icon: AppIconKind.quote,
          label: strings.chatActionQuote,
        ),
        (
          action: ChatMessageAction.delete,
          icon: AppIconKind.delete,
          label: strings.chatActionDelete,
        ),
      ] else if (isLocationRestricted) ...[
        (
          action: ChatMessageAction.forward,
          icon: AppIconKind.redo,
          label: strings.chatForwardMenu,
        ),
        (
          action: ChatMessageAction.quote,
          icon: AppIconKind.quote,
          label: strings.chatActionQuote,
        ),
        (
          action: ChatMessageAction.delete,
          icon: AppIconKind.delete,
          label: strings.chatActionDelete,
        ),
      ] else ...[
        if (message.type == MessageType.text)
          (
            action: ChatMessageAction.copy,
            icon: AppIconKind.copy,
            label: strings.chatActionCopy,
          ),
        (
          action: ChatMessageAction.forward,
          icon: AppIconKind.redo,
          label: strings.chatForwardMenu,
        ),
        (
          action: ChatMessageAction.delete,
          icon: AppIconKind.delete,
          label: strings.chatActionDelete,
        ),
        if (canFavoriteMessage)
          (
            action: ChatMessageAction.favorite,
            icon: AppIconKind.starOutline,
            label: strings.chatActionFavorite,
          ),
        (
          action: ChatMessageAction.multi,
          icon: AppIconKind.checklist,
          label: strings.chatActionMultiSelect,
        ),
        if (canCollectSticker && !alreadyCollectedSticker)
          (
            action: ChatMessageAction.favoriteSticker,
            icon: AppIconKind.smile,
            label: strings.chatActionFavoriteSticker,
          ),
        (
          action: ChatMessageAction.quote,
          icon: AppIconKind.quote,
          label: strings.chatActionQuote,
        ),
      ],
    ];

    if (canRecall) {
      final deleteIndex = actions.indexWhere(
        (item) => item.action == ChatMessageAction.delete,
      );
      final recallItem = (
        action: ChatMessageAction.recall,
        icon: AppIconKind.undo,
        label: strings.chatActionRecall,
      );
      if (deleteIndex >= 0) {
        actions.insert(deleteIndex, recallItem);
      } else {
        actions.add(recallItem);
      }
    }
    return actions;
  }

  bool _hasValidServerMessageId(Message message) {
    final messageId = message.messageId.trim();
    return messageId.isNotEmpty && messageId != '0';
  }

  bool _canFavoriteMessageByType(Message message) {
    switch (message.type) {
      case MessageType.text:
      case MessageType.image:
      case MessageType.video:
      case MessageType.file:
        return true;
      case MessageType.custom:
        if (_isContactCardMessage(message)) {
          return false;
        }
        return _isLinkMessage(message);
      default:
        return false;
    }
  }

  bool _isContactCardMessage(Message message) {
    if (message.type == MessageType.contactCard) {
      return true;
    }
    return message.type == MessageType.custom &&
        (message.extra.customType?.trim().toUpperCase() ?? '') ==
            'CONTACT_CARD';
  }

  bool _isLinkMessage(Message message) {
    if (message.type == MessageType.text) {
      if (_looksLikeLinkContent(message.content)) {
        return true;
      }
      final parsed = _tryParseJsonObject(message.content);
      if (parsed != null) {
        final contentText = parsed['content']?.toString().trim() ?? '';
        if (_looksLikeLinkContent(contentText)) {
          return true;
        }
        return _resolveLinkUrlFromObject(parsed).isNotEmpty;
      }
      return false;
    }
    if (message.type != MessageType.custom) {
      return false;
    }
    final customType = message.extra.customType?.trim().toUpperCase() ?? '';
    if (customType == 'LINK' ||
        customType == 'URL' ||
        customType == 'WEB_LINK') {
      return true;
    }
    if (_looksLikeLinkContent(message.content)) {
      return true;
    }
    final parsedContent = _tryParseJsonObject(message.content);
    if (parsedContent != null &&
        _resolveLinkUrlFromObject(parsedContent).isNotEmpty) {
      return true;
    }
    return _resolveLinkUrlFromObject(_buildMessageExtraMap(message)).isNotEmpty;
  }

  bool _looksLikeLinkContent(String text) {
    final value = text.trim();
    if (value.isEmpty) {
      return false;
    }
    return _directUrlPattern.hasMatch(value) || _wwwUrlPattern.hasMatch(value);
  }

  Map<String, dynamic>? _tryParseJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        ((!trimmed.startsWith('{') || !trimmed.endsWith('}')) &&
            (!trimmed.startsWith('[') || !trimmed.endsWith(']')))) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (e) {
      debugPrint('[ChatPage] jsonDecode failed: $e');
    }
    return null;
  }

  String _resolveLinkUrlFromObject(Map<String, dynamic>? obj) {
    if (obj == null) {
      return '';
    }
    for (final key in const ['url', 'link', 'href']) {
      final value = obj[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    final nested = obj['content'];
    if (nested is String) {
      final value = nested.trim();
      if (_looksLikeLinkContent(value)) {
        return value;
      }
    } else if (nested is Map<String, dynamic>) {
      final value = _resolveLinkUrlFromObject(nested);
      if (value.isNotEmpty) {
        return value;
      }
    } else if (nested is Map) {
      final value = _resolveLinkUrlFromObject(
        nested.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  Map<String, dynamic> _buildMessageExtraMap(Message message) {
    return <String, dynamic>{
      if (message.extra.customType?.trim().isNotEmpty == true)
        'type': message.extra.customType!.trim(),
      if (message.extra.fileUrl?.trim().isNotEmpty == true)
        'url': message.extra.fileUrl!.trim(),
      if (message.extra.thumbnailUrl?.trim().isNotEmpty == true)
        'thumbUrl': message.extra.thumbnailUrl!.trim(),
    };
  }

  String _resolveLinkUrlFromMessage(Message message) {
    if (message.type == MessageType.text) {
      final direct = message.content.trim();
      if (_looksLikeLinkContent(direct)) {
        return direct;
      }
      final parsed = _tryParseJsonObject(message.content);
      if (parsed != null) {
        final contentText = parsed['content']?.toString().trim() ?? '';
        if (_looksLikeLinkContent(contentText)) {
          return contentText;
        }
        final nested = _resolveLinkUrlFromObject(parsed);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
      return '';
    }
    final parsedContent = _tryParseJsonObject(message.content);
    if (parsedContent != null) {
      final resolved = _resolveLinkUrlFromObject(parsedContent);
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
    return _resolveLinkUrlFromObject(_buildMessageExtraMap(message));
  }

  String _resolvePreviewFileUrl(Message message) {
    switch (message.type) {
      case MessageType.image:
      case MessageType.sticker:
      case MessageType.emoji:
      case MessageType.video:
        return extractMediaUrlFromRawContent(message.content);
      case MessageType.file:
        return extractMediaUrlFromRawContent(
          message.content,
          fallbackMixedContent: true,
        );
      default:
        return message.extra.fileUrl?.trim() ?? '';
    }
  }

  Future<void> _openLinkMessage(Message message) async {
    final strings = ref.read(appStringsProvider);
    final raw = _resolveLinkUrlFromMessage(message).trim();
    if (raw.isEmpty) {
      if (mounted) {
        _showAttachmentError(context, strings.chatOpenFailed);
      }
      return;
    }
    final normalized = raw.startsWith('www.') ? 'https://$raw' : raw;
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      if (mounted) {
        _showAttachmentError(context, strings.chatOpenFailed);
      }
      return;
    }
    if (!mounted) {
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

  void _handleTextLinkTap(String url) {
    if (!mounted) {
      return;
    }
    final strings = ref.read(appStringsProvider);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showAttachmentError(context, strings.chatOpenFailed);
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

  bool _canAddMessageToSticker(Message message) {
    if (message.type == MessageType.emoji ||
        message.type == MessageType.sticker) {
      return true;
    }
    if (message.type != MessageType.image) {
      return false;
    }
    final url = extractMediaUrlFromRawContent(message.content);
    if (url.isEmpty || !_hasValidServerMessageId(message)) {
      return false;
    }
    final lowerUrl = url.toLowerCase();
    final mimeType = message.extra.mimeType?.trim().toLowerCase() ?? '';
    final isAnimatedImage =
        mimeType.contains('gif') ||
        mimeType.contains('webp') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp');
    return isAnimatedImage;
  }

  bool _isMessageAlreadyCollectedToSticker(Message message) {
    final candidate = _resolveStickerCollectCandidate(message);
    if (candidate == null) {
      return false;
    }
    return _cachedFavoriteStickers.any((item) {
      if (candidate.stickerId.isNotEmpty &&
          item.stickerId == candidate.stickerId) {
        return true;
      }
      final itemFileId = item.fileId?.trim() ?? '';
      if (candidate.fileId.isNotEmpty && itemFileId == candidate.fileId) {
        return true;
      }
      final itemMd5 = item.md5?.trim() ?? '';
      if (candidate.md5.isNotEmpty && itemMd5 == candidate.md5) {
        return true;
      }
      return candidate.url.isNotEmpty && item.url.trim() == candidate.url;
    });
  }

  ({String stickerId, String fileId, String md5, String url})?
  _resolveStickerCollectCandidate(Message message) {
    switch (message.type) {
      case MessageType.sticker:
      case MessageType.emoji:
        return (
          stickerId: '',
          fileId: message.extra.fileId?.trim() ?? '',
          md5: message.extra.md5?.trim() ?? '',
          url: extractMediaUrlFromRawContent(message.content),
        );
      case MessageType.image:
        return (
          stickerId: '',
          fileId: message.extra.fileId?.trim() ?? '',
          md5: message.extra.md5?.trim() ?? '',
          url: extractMediaUrlFromRawContent(message.content),
        );
      default:
        return null;
    }
  }

  bool _canRecallMessage(Message message) {
    if (!message.isOutgoing || !_hasValidServerMessageId(message)) {
      return false;
    }
    if (message.type == MessageType.system) {
      return false;
    }
    return DateTime.now().difference(message.sentAt) <= _recallWindow;
  }

  Future<void> _favoriteStickerMessage(
    BuildContext context,
    Message message,
  ) async {
    final strings = ref.read(appStringsProvider);
    if (!_canAddMessageToSticker(message)) {
      _showAttachmentError(context, strings.chatStickerCannotAdd);
      return;
    }
    if (_isMessageAlreadyCollectedToSticker(message)) {
      _showAttachmentError(context, strings.chatStickerExists);
      return;
    }
    final repository = ref.read(stickerRepositoryProvider);
    try {
      if (_cachedFavoriteStickers.length >= _maxStickerCount) {
        _showAttachmentError(
          context,
          strings.chatMaxStickerReached(_maxStickerCount),
        );
        return;
      }
      if (message.type != MessageType.emoji &&
          !_hasValidServerMessageId(message)) {
        _showAttachmentError(context, strings.chatStickerCannotAdd);
        return;
      }
      final StickerItem sticker;
      if (message.type == MessageType.emoji) {
        var fileId = message.extra.fileId?.trim() ?? '';
        var url = message.extra.fileUrl?.trim().isNotEmpty == true
            ? message.extra.fileUrl!.trim()
            : message.content.trim();
        if (fileId.isEmpty && url.isNotEmpty) {
          final session = ref.read(authSessionProvider);
          final uploadBytes =
              (kIsWeb && (url.startsWith('blob:') || url.startsWith('data:')))
              ? await loadLocalUriBytes(url)
              : null;
          final upload = await ref
              .read(fileRepositoryProvider)
              .uploadAndCreateFile(
                taskId: DateTime.now().microsecondsSinceEpoch.toString(),
                purpose: UploadPurpose.stickerOriginal,
                scope: UploadScope.sticker(userId: session.userId),
                localUri: url,
                displayName: message.extra.fileName?.trim().isNotEmpty == true
                    ? message.extra.fileName!.trim()
                    : 'emoji',
                mimeType: _guessStickerMimeType(
                  rawPath: url,
                  fallback: message.extra.mimeType?.trim() ?? '',
                ),
                bytes: uploadBytes,
              );
          fileId = upload.file.fileId;
          url = upload.file.url;
        }
        if (fileId.isEmpty || url.isEmpty) {
          if (!mounted) {
            return;
          }
          _showAttachmentError(this.context, strings.chatStickerCannotAdd);
          return;
        }
        sticker = await repository.uploadSticker(
          fileId: fileId,
          url: url,
          name: message.extra.fileName?.trim().isNotEmpty == true
              ? message.extra.fileName!.trim()
              : 'emoji',
          md5: message.extra.md5?.trim() ?? '',
          mimeType: message.extra.mimeType?.trim() ?? '',
        );
      } else {
        sticker = await repository.collectSticker(messageId: message.messageId);
      }
      _mergeFavoriteSticker(sticker);
      if (!mounted) {
        return;
      }
      _showAttachmentSuccess(
        this.context,
        sticker.duplicated
            ? strings.chatStickerExists
            : strings.chatStickerAdded,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showAttachmentError(this.context, error.toString());
    }
  }

  String _guessStickerMimeType({
    required String rawPath,
    required String fallback,
  }) {
    final normalizedFallback = fallback.trim();
    if (normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }
    final lowerPath = rawPath.toLowerCase();
    if (lowerPath.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/png';
  }

  Future<void> _warmupStickerCatalog() async {
    try {
      final catalog = await ref
          .read(stickerRepositoryProvider)
          .getStickerCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _cachedFavoriteStickers = catalog.favorites;
      });
    } catch (_) {
      // ignore background warmup failure
    }
  }

  void _mergeFavoriteSticker(StickerItem sticker) {
    final next = <StickerItem>[..._cachedFavoriteStickers];
    final index = next.indexWhere(
      (item) => item.stickerId == sticker.stickerId,
    );
    if (index >= 0) {
      next[index] = sticker;
    } else {
      next.insert(0, sticker);
    }
    _cachedFavoriteStickers = next;
  }

  Future<void> _recallMessage(BuildContext context, Message message) async {
    final strings = ref.read(appStringsProvider);
    try {
      await ref
          .read(messageRepositoryProvider)
          .recallMessage(messageId: message.messageId);
      final recalled = _buildOptimisticRecalledMessage(message, strings);
      await _persistReeditHintForMessage(recalled);
      ref
          .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
          .applyRecalledMessage(recalled);
      final pageState = ref.read(chatControllerProvider(widget.args.chatId));
      ref
          .read(conversationListControllerProvider.notifier)
          .upsertLocalMessage(
            chatId: widget.args.chatId,
            title: pageState.chatTitle ?? pageState.entryArgs.title ?? '',
            conversationType: pageState.entryArgs.conversationType,
            targetId: pageState.entryArgs.targetId,
            messageId: recalled.messageId,
            messageSequence: recalled.sequence,
            preview: createConversationPreviewFormatter(
              ref.read(appLocaleProvider),
            ).call(
              type: recalled.type,
              content: recalled.content,
              customType: recalled.extra.customType,
              fileName: recalled.extra.fileName,
              systemEventKey: recalled.extra.systemEventKey,
              systemEventParams: recalled.extra.systemEventParams,
              conversationType: pageState.entryArgs.conversationType,
              isSelf: recalled.isOutgoing,
              senderName: recalled.senderName,
            ),
            messageType: recalled.type,
            senderName: recalled.senderName,
            isSelf: recalled.isOutgoing,
            customType: recalled.extra.customType,
            fileName: recalled.extra.fileName,
            systemEventKey: recalled.extra.systemEventKey,
            messageStatus: recalled.status,
            updatedAt: recalled.sentAt,
            resetUnread: true,
          );
      if (!mounted) {
        return;
      }
      _showAttachmentSuccess(this.context, strings.chatRecallSuccess);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showAttachmentError(this.context, strings.chatRecallFailed);
    }
  }

  Future<void> _confirmRecallMessage(
    BuildContext context,
    Message message,
  ) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await _showLegacyConfirmDialog(
      context,
      title: strings.chatRecallConfirmTitle,
      content: strings.chatRecallConfirmContent,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _recallMessage(this.context, message);
  }

  Future<void> _confirmDeleteMessage(
    BuildContext context,
    Message message,
  ) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await _showLegacyConfirmDialog(
      context,
      title: strings.chatDeleteConfirmTitle,
      content: strings.chatDeleteConfirmContent,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      final result = await ref
          .read(chatMessageActionControllerProvider(widget.args.chatId))
          .handleAction(
            action: ChatMessageAction.delete,
            message: message,
            copiedNotice: strings.chatCopySuccess,
            favoritedNotice: strings.chatFavoriteSuccess,
            deletedNotice: strings.chatDeleteSuccess,
          );
      if (!mounted) {
        return;
      }
      if (result.noticeMessage.isNotEmpty) {
        _showAttachmentSuccess(this.context, result.noticeMessage);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showAttachmentError(this.context, strings.chatDeleteFailed);
    }
  }

  Future<void> _rehydrateReeditHints() async {
    final session = ref.read(authSessionProvider);
    if (session.userId.isEmpty || session.tenantId.isEmpty) {
      return;
    }
    final timeline = ref.read(chatTimelineControllerProvider(widget.args.chatId));
    if (timeline.messages.isEmpty) {
      return;
    }
    final hydrated = await ref
        .read(reeditHintLocalStoreProvider)
        .rehydrateMessages(
          tenantId: session.tenantId,
          userId: session.userId,
          chatId: widget.args.chatId,
          messages: timeline.messages,
        );
    var changed = false;
    for (var i = 0; i < hydrated.length; i++) {
      if (hydrated[i].extra.reeditContent !=
              timeline.messages[i].extra.reeditContent ||
          hydrated[i].extra.reeditDeadlineTs !=
              timeline.messages[i].extra.reeditDeadlineTs) {
        changed = true;
        break;
      }
    }
    if (!changed) {
      return;
    }
    await ref
        .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
        .replaceAllMessages(hydrated);
  }

  Future<void> _persistReeditHintForMessage(Message message) async {
    final content = message.extra.reeditContent?.trim() ?? '';
    if (content.isEmpty) {
      return;
    }
    final session = ref.read(authSessionProvider);
    if (session.userId.isEmpty || session.tenantId.isEmpty) {
      return;
    }
    final ids = <String>{
      message.messageId.trim(),
      if (message.clientMessageId != null) message.clientMessageId!.trim(),
    }..removeWhere((item) => item.isEmpty);
    for (final id in ids) {
      await ref
          .read(reeditHintLocalStoreProvider)
          .persist(
            tenantId: session.tenantId,
            userId: session.userId,
            chatId: widget.args.chatId,
            messageId: id,
            content: content,
            deadlineTs: message.extra.reeditDeadlineTs,
          );
    }
  }

  Message _buildOptimisticRecalledMessage(
    Message message,
    AppLocalizations strings,
  ) {
    final canReedit = _canExtractReeditContent(message);
    final senderName = message.senderName.trim();
    return message.copyWith(
      type: MessageType.system,
      status: MessageStatus.recalled,
      content: message.isOutgoing
          ? strings.chatRecallSelfTip
          : strings.chatRecallOtherTip(
              senderName.isEmpty ? strings.chatOtherUser : senderName,
            ),
      extra: message.extra.copyWith(
        reeditContent: canReedit ? message.content.trim() : null,
        reeditDeadlineTs: canReedit
            ? DateTime.now()
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch
            : null,
      ),
    );
  }

  bool _canExtractReeditContent(Message message) {
    if (!message.isOutgoing || message.type != MessageType.text) {
      return false;
    }
    if (message.extra.quoteMessageId?.trim().isNotEmpty == true) {
      return false;
    }
    if (message.extra.forwardedFrom?.trim().isNotEmpty == true) {
      return false;
    }
    if (message.extra.customType?.toUpperCase() == 'FORWARD_COMBINE') {
      return false;
    }
    final content = message.content.trim();
    return content.isNotEmpty && !content.contains('撤回');
  }

  void _startQuoteReply(Message message) {
    final preview = _buildQuotePreview(message);
    setState(() {
      _isMorePanelVisible = false;
      _isEmojiPanelVisible = false;
      _isVoiceMode = false;
      _quoteInfo = QuoteInfo(
        messageId: message.messageId,
        senderName: _quoteSenderName(message),
        preview: preview,
      );
    });
  }

  bool _ensureConversationWritable(BuildContext context) {
    final pageState = ref.read(chatControllerProvider(widget.args.chatId));
    if (pageState.isReadOnly) {
      _showAttachmentError(context, _resolveReadOnlyHint());
      return false;
    }
    final conversationState = ref.read(conversationListControllerProvider);
    final conversation = _resolveConversation(conversationState.conversations);
    final groupId = _resolveGroupId(
      widget.args.conversationType == ConversationType.group,
    );
    final groupSettingsState = groupId == null
        ? null
        : ref.read(
            groupSettingsControllerProvider(
              GroupContextArgs(
                groupId: groupId,
                groupName:
                    pageState.chatTitle ??
                    ref.read(appStringsProvider).chatTitle,
              ),
            ),
          );
    final groupRestrictionHint = _resolveGroupSendRestrictionHint(
      groupSettingsState: groupSettingsState,
      currentUserId: ref.read(authSessionProvider).userId,
      conversation: conversation,
    );
    if (groupRestrictionHint != null) {
      _showAttachmentError(context, groupRestrictionHint);
      return false;
    }
    return true;
  }

  String _resolveReadOnlyHint() {
    final strings = ref.read(appStringsProvider);
    final serviceState = ref
        .read(chatControllerProvider(widget.args.chatId))
        .entryArgs
        .serviceState
        ?.trim()
        .toLowerCase();
    return switch (serviceState) {
      'closed' || 'ended' || 'finished' => strings.chatReadOnlyClosed,
      _ => strings.chatReadOnly,
    };
  }

  String _formatMuteUntil(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }

  String _quoteSenderName(Message message) {
    final senderName = message.senderName.trim();
    if (senderName.isNotEmpty) {
      return senderName;
    }
    final senderId = message.senderId.trim();
    if (senderId.isNotEmpty) {
      return senderId;
    }
    final chatId = message.chatId.trim();
    if (chatId.isNotEmpty) {
      return chatId;
    }
    return '?';
  }

  String _buildQuotePreview(Message message) {
    return createMessagePreviewFormatter(
      ref.read(appLocaleProvider),
    ).call(
      type: message.type,
      content: message.content,
      customType: message.extra.customType,
    );
  }

  void _clearQuoteReply() {
    if (_quoteInfo == null) {
      return;
    }
    setState(() {
      _quoteInfo = null;
    });
  }

  void _scheduleHighlightClear() {
    final highlightedMessageId = _activeHighlightedMessageId;
    if (highlightedMessageId == null || highlightedMessageId.isEmpty) {
      return;
    }
    _timerManager.setOnce('highlightClear', Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_activeHighlightedMessageId == highlightedMessageId) {
          _activeHighlightedMessageId = null;
        }
      });
    }));
  }

  void _handleInitialViewport() {
    final entryMode = widget.args.entryMode;
    final isAnchorEntry =
        entryMode == ChatEntryMode.anchor || entryMode == ChatEntryMode.restore;
    if (!isAnchorEntry) {
      _ensureInitialBottomVisibility();
      return;
    }
    final targetId = widget.args.highlightedMessageId?.trim().isNotEmpty == true
        ? widget.args.highlightedMessageId!.trim()
        : widget.args.anchorMessageId?.trim() ?? '';
    if (targetId.isEmpty) {
      _ensureInitialBottomVisibility();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) {
        return;
      }
      final alreadyFound = await _tryScrollToMessageKey(targetId);
      if (alreadyFound) {
        _scheduleHighlightClear();
        return;
      }
      // 消息不在当前窗口，尝试以锚点重新加载窗口
      await _reloadWithAnchor(targetId);
      if (!mounted) return;
      final stillFound = await _tryScrollToMessageKey(targetId);
      if (stillFound) {
        _scheduleHighlightClear();
        return;
      }
      // 仍找不到，渐进式加载历史消息
      final loadedAndFound = await _loadUntilMessageFound(
        messageId: targetId,
        maxRounds: 15,
      );
      if (loadedAndFound && mounted) {
        // 定位成功，从此刻开始计时高亮
        _scheduleHighlightClear();
        return;
      }
      if (mounted) {
        // 最终降级：检查后端是否返回了锚点
        final currentViewport = ref
            .read(chatTimelineControllerProvider(widget.args.chatId))
            .viewportState;
        if (currentViewport?.anchorFound == false) {
          _showAttachmentError(
            context,
            ref.read(appStringsProvider).chatAnchorFallback,
          );
        }
        _ensureInitialBottomVisibility();
      }
    });
  }

  void _ensureInitialBottomVisibility() {
    const delays = <int>[0, 60, 180, 320, 520, 760];
    for (final delay in delays) {
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _scrollTimelineToBottom(forceJump: delay == 0);
          _settleInitialBottomAlignment();
        });
      });
    }
  }

  void _settleInitialBottomAlignment() {
    if (!_initialBottomAlignmentPending ||
        !_timelineScrollController.hasClients) {
      return;
    }
    final position = _timelineScrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    if (distanceToBottom <= 4) {
      _initialBottomAlignmentPending = false;
      _isTimelineAtBottom = true;
    }
  }

  Future<void> _openQuotedMessage(String quotedMessageId) async {
    final targetId = quotedMessageId.trim();
    if (targetId.isEmpty) {
      return;
    }
    var messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    var matched = messages.any((item) => item.messageId == targetId);
    if (!matched) {
      final pageState = ref.read(chatControllerProvider(widget.args.chatId));
      await ref
          .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
          .reloadLatest(
            command: OpenChatCommand(
              chatId: widget.args.chatId,
              conversationType: pageState.entryArgs.conversationType,
              entryMode: ChatEntryMode.anchor,
              title: pageState.chatTitle ?? pageState.entryArgs.title,
              anchorMessageId: targetId,
            ),
          );
      await _rehydrateReeditHints();
      if (!mounted) {
        return;
      }
      messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
      matched = messages.any((item) => item.messageId == targetId);
    }
    if (!matched) {
      final viewportState = ref
          .read(chatTimelineControllerProvider(widget.args.chatId))
          .viewportState;
      if (viewportState?.anchorFound == false) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatAnchorFallback,
        );
        _scrollTimelineToBottom();
        return;
      }
      // 锚点已找到但消息不在当前窗口，渐进式加载
      final loadedAndFound = await _loadUntilMessageFound(
        messageId: targetId,
        maxRounds: 8,
      );
      if (!loadedAndFound) {
        if (!mounted) return;
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatQuoteMessageMissing,
        );
        return;
      }
    }
    setState(() {
      _activeHighlightedMessageId = targetId;
    });
    await _scrollToMessageKey(targetId);
    _scheduleHighlightClear();
  }

  /// 尝试在当前已渲染的消息中查找并滚动到目标消息
  /// 返回 true 表示找到并滚动，false 表示未找到
  Future<bool> _tryScrollToMessageKey(String messageId) async {
    final key = _resolveMessageItemKey(messageId);
    if (key?.currentContext != null) {
      await _doScrollToContext(key!.currentContext!);
      return true;
    }
    final messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    final index = messages.indexWhere(
      (item) =>
          item.messageId == messageId || item.clientMessageId == messageId,
    );
    if (index < 0) {
      return false;
    }
    await _scrollToMessageByIndex(index);
    return true;
  }

  /// 以指定消息为锚点重新加载消息窗口
  Future<void> _reloadWithAnchor(String messageId) async {
    final pageState = ref.read(chatControllerProvider(widget.args.chatId));
    await ref.read(chatTimelineControllerProvider(widget.args.chatId).notifier).reloadLatest(
          command: OpenChatCommand(
            chatId: widget.args.chatId,
            conversationType: pageState.entryArgs.conversationType,
            entryMode: ChatEntryMode.anchor,
            title: pageState.chatTitle ?? pageState.entryArgs.title,
            anchorMessageId: messageId,
          ),
        );
    await _rehydrateReeditHints();
  }

  Future<void> _scrollToMessageKey(String messageId) async {
    final key = _resolveMessageItemKey(messageId);
    if (key?.currentContext != null) {
      await _doScrollToContext(key!.currentContext!);
      return;
    }
    final messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    final index = messages.indexWhere(
      (item) =>
          item.messageId == messageId || item.clientMessageId == messageId,
    );
    if (index < 0) {
      return;
    }
    await _scrollToMessageByIndex(index);
  }

  Future<void> _doScrollToContext(BuildContext context) async {
    await Scrollable.ensureVisible(
      context,
      alignment: 0.4,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  /// 通过精确计算像素偏移量滚动到目标消息位置
  /// 使用两阶段策略：快速接近 → 精确测量 → 最终对齐
  Future<void> _scrollToMessageByIndex(int messageIndex) async {
    if (!_timelineScrollController.hasClients) return;
    final position = _timelineScrollController.position;
    // 第一阶段：使用保守估算快速接近目标位置
    const conservativeEstimate = 80.0;
    // +1 是因为 ListView 的第一个 item 是 _LoadOlderBar
    final roughOffset = 16 + 48 + (messageIndex + 1) * conservativeEstimate;
    final roughTarget = roughOffset.clamp(0.0, position.maxScrollExtent);
    await position.animateTo(
      roughTarget,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    // 第二阶段：等待 ListView 渲染可视区域内的消息
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await WidgetsBinding.instance.endOfFrame;
    // 第三阶段：使用已渲染消息的 RenderBox 精确计算偏移量
    final preciseOffset = _calculateExactPixelOffset(messageIndex);
    if (preciseOffset != null) {
      final finalTarget = preciseOffset.clamp(0.0, position.maxScrollExtent);
      final delta = (finalTarget - position.pixels).abs();
      // 只有当精确计算的偏移量与当前位置有显著差异时才二次滚动
      if (delta > 10) {
        await position.animateTo(
          finalTarget,
          duration: Duration(milliseconds: delta < 200 ? 150 : 250),
          curve: Curves.easeOut,
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await WidgetsBinding.instance.endOfFrame;
      }
    }
    // 第四阶段：通过 GlobalKey 精确对齐目标消息
    await _fineTuneAfterRender(messageIndex);
  }

  /// 精确计算从列表顶部到目标消息的像素偏移量
  /// 通过累加已渲染消息的真实高度 + 未渲染消息的估算高度
  double? _calculateExactPixelOffset(int targetIndex) {
    final messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    if (targetIndex < 0 || targetIndex >= messages.length) return null;
    // ListView padding top = 16
    double totalOffset = 16;
    // +1 是因为 ListView 的第一个 item 是 _LoadOlderBar
    // _LoadOlderBar 的高度估算
    const loadOlderBarHeight = 48.0;
    totalOffset += loadOlderBarHeight;
    // 遍历从 0 到 targetIndex-1 的所有消息，累加它们的高度
    for (var i = 0; i < targetIndex; i++) {
      final item = messages[i];
      final renderKey = _messageRenderKey(item, i);
      final globalKey = _messageItemKeys[renderKey];
      if (globalKey?.currentContext != null) {
        // 消息已渲染，使用 RenderBox 精确测量高度
        final renderObject = globalKey!.currentContext!.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize) {
          totalOffset += renderObject.size.height;
        } else {
          totalOffset += 80; // 降级估算（含 padding 和可能的 time divider）
        }
      } else {
        // 消息未渲染（虚拟化），使用保守估算（含 padding 和可能的 time divider）
        totalOffset += 80;
      }
    }
    return totalOffset;
  }

  /// 滚动后尝试精确定位到目标消息
  Future<void> _fineTuneAfterRender(int messageIndex) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await WidgetsBinding.instance.endOfFrame;
    final key = _resolveMessageItemKeyByIndex(messageIndex);
    if (key?.currentContext != null) {
      await _doScrollToContext(key!.currentContext!);
    }
  }

  GlobalKey? _resolveMessageItemKeyByIndex(int messageIndex) {
    final messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    if (messageIndex < 0 || messageIndex >= messages.length) return null;
    final item = messages[messageIndex];
    final renderKey = _messageRenderKey(item, messageIndex);
    return _messageItemKeys[renderKey];
  }

  /// 渐进式加载历史消息直到找到目标消息，然后滚动到目标位置
  /// 用于解决大量消息场景下搜索跳转无法定位的问题
  Future<bool> _loadUntilMessageFound({
    required String messageId,
    int maxRounds = 15,
    Duration interval = const Duration(milliseconds: 300),
  }) async {
    for (var round = 0; round < maxRounds; round++) {
      if (!mounted) return false;
      // 等待当前帧渲染完成，确保 _messageItemKeys 已更新
      await WidgetsBinding.instance.endOfFrame;
      // 先尝试通过已渲染的 key 找到
      final key = _resolveMessageItemKey(messageId);
      if (key?.currentContext != null) {
        await _doScrollToContext(key!.currentContext!);
        return true;
      }
      // 在消息数据列表中查找目标索引
      final messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
      final index = messages.indexWhere(
        (item) =>
            item.messageId == messageId || item.clientMessageId == messageId,
      );
      if (index >= 0) {
        // 消息已加载到列表中，使用精确滚动
        await _scrollToMessageByIndex(index);
        return true;
      }
      // 消息还未加载，检查是否还有更早的历史消息
      final viewport = ref.read(chatTimelineControllerProvider(widget.args.chatId)).viewportState;
      if (viewport?.hasMoreBefore != true) {
        return false;
      }
      try {
        await ref.read(chatTimelineControllerProvider(widget.args.chatId).notifier).loadOlder(
              chatId: widget.args.chatId,
            );
      } catch (_) {
        return false;
      }
      if (round < maxRounds - 1) {
        await Future<void>.delayed(interval);
      }
    }
    return false;
  }

  GlobalKey? _resolveMessageItemKey(String messageId) {
    final messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    for (var index = 0; index < messages.length; index++) {
      final item = messages[index];
      if (item.messageId == messageId || item.clientMessageId == messageId) {
        final renderKey = _messageRenderKey(item, index);
        final resolved = _messageItemKeys[renderKey];
        if (resolved != null) {
          return resolved;
        }
      }
    }
    return null;
  }

  String _messageRenderKey(Message message, int index) {
    final messageId = message.messageId.trim();
    final clientMessageId = message.clientMessageId?.trim() ?? '';
    final sequence = message.sequence?.trim() ?? '';
    // 优先使用稳定标识符（sequence > messageId > clientMessageId），
    // 避免加载历史消息后 key 失效导致滚动位置错乱。
    if (sequence.isNotEmpty) {
      return 'seq:$sequence';
    }
    if (messageId.isNotEmpty && clientMessageId.isNotEmpty) {
      return 'mid:$messageId|cid:$clientMessageId';
    }
    if (messageId.isNotEmpty) {
      return 'mid:$messageId';
    }
    if (clientMessageId.isNotEmpty) {
      return 'cid:$clientMessageId';
    }
    // 兜底：使用 content hash + sentAt 生成稳定 key，避免索引漂移
    final contentHash = message.content.hashCode;
    return 'hash:${contentHash}_${message.sentAt.microsecondsSinceEpoch}';
  }

  bool _handleGroupLifecycleRequestError(
    BuildContext context,
    Object? error, {
    required String fallbackNotice,
  }) {
    if (widget.args.conversationType != ConversationType.group) {
      return false;
    }
    final notice = _resolveGroupLifecycleErrorNotice(error, fallbackNotice);
    if (notice.isEmpty) {
      return false;
    }
    _redirectAfterRemovedFromGroup(context, notice);
    return true;
  }

  String _resolveGroupLifecycleErrorNotice(
    Object? error,
    String fallbackNotice,
  ) {
    final queue = <Object?>[error];
    final visited = <Object?>{};
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == null || visited.contains(current)) {
        continue;
      }
      visited.add(current);
      if (current is AppError) {
        final fromCause = _resolveGroupLifecycleErrorNotice(
          current.cause,
          fallbackNotice,
        );
        if (fromCause.isNotEmpty) {
          return fromCause;
        }
        if (_looksLikeGroupLifecycleFailure(current.message, current.code)) {
          return current.message.trim().isNotEmpty
              ? current.message.trim()
              : fallbackNotice;
        }
        continue;
      }
      if (current is ApiException) {
        if (_looksLikeGroupLifecycleFailure(current.message, null)) {
          return current.message.trim().isNotEmpty
              ? current.message.trim()
              : fallbackNotice;
        }
        queue.add(current.details);
        continue;
      }
      final text = current.toString().trim();
      if (_looksLikeGroupLifecycleFailure(text, null)) {
        return _extractLifecycleNoticeText(text, fallbackNotice);
      }
    }
    return '';
  }

  bool _looksLikeGroupLifecycleFailure(String text, String? code) {
    final normalizedCode = code?.trim().toUpperCase() ?? '';
    if (normalizedCode == 'NOT_GROUP_MEMBER' ||
        normalizedCode == 'GROUP_MEMBER_NOT_EXISTS' ||
        normalizedCode == 'GROUP_NOT_FOUND') {
      return true;
    }
    final normalizedText = text.trim();
    final upper = normalizedText.toUpperCase();
    return upper.contains('NOT_GROUP_MEMBER') ||
        upper.contains('GROUP_MEMBER_NOT_EXISTS') ||
        upper.contains('GROUP_NOT_FOUND') ||
        normalizedText.contains('移出群聊') ||
        normalizedText.contains('不在群聊') ||
        normalizedText.contains('群成员不存在');
  }

  String _extractLifecycleNoticeText(String text, String fallbackNotice) {
    final messageMatch = RegExp(r'message:\s*([^)]+)').firstMatch(text);
    final resolved = messageMatch?.group(1)?.trim() ?? text.trim();
    if (resolved.isEmpty) {
      return fallbackNotice;
    }
    final upper = resolved.toUpperCase();
    if (upper == 'NOT_GROUP_MEMBER' ||
        upper == 'GROUP_MEMBER_NOT_EXISTS' ||
        upper == 'GROUP_NOT_FOUND') {
      return fallbackNotice;
    }
    return resolved;
  }

  void _redirectAfterRemovedFromGroup(BuildContext context, String notice) {
    if (!mounted) {
      return;
    }
    _showAttachmentError(context, notice);
    final groupId = _resolveGroupId(
      widget.args.conversationType == ConversationType.group,
    );
    if (groupId != null && groupId.trim().isNotEmpty) {
      final args = GroupContextArgs(groupId: groupId, groupName: '');
      ref.invalidate(groupSettingsControllerProvider(args));
      ref.invalidate(groupMembersFutureProvider(groupId));
    }
    final router = GoRouter.of(context);
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      router.goNamed(RouteNames.conversations);
    });
  }

  void _startReeditTicker() {
    _timerManager.cancel('reedit');
    _timerManager.setPeriodic('reedit', Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timerManager.cancel('reedit');
        return;
      }
      // 双重检查：确保在 setState 时仍然有效
      try {
        if (mounted) {
          setState(() {
            _reeditNowTs = DateTime.now().millisecondsSinceEpoch;
          });
        }
      } catch (_) {
        // 忽略 widget 已被销毁时的 setState 异常
        _timerManager.cancel('reedit');
      }
    }));
  }

  void _handleReeditAfterRecall(Message message) {
    if (!_canReeditAfterRecall(message)) {
      _showAttachmentError(
        context,
        ref.read(appStringsProvider).chatReeditExpired,
      );
      return;
    }
    final content = message.extra.reeditContent?.trim() ?? '';
    if (content.isEmpty) {
      _showAttachmentError(
        context,
        ref.read(appStringsProvider).chatReeditUnsupported,
      );
      return;
    }
    final composer = ref.read(chatComposerControllerProvider);
    composer.textController.value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(offset: content.length),
    );
    _updateComposerLineCount(content);
    setState(() {
      _quoteInfo = null;
      _isMorePanelVisible = false;
      _isEmojiPanelVisible = false;
      _isMentionPanelVisible = false;
      _isVoiceMode = false;
      _isSelectionMode = false;
      _isFullExpanded = false;
    });
  }

  bool _canReeditAfterRecall(Message message) {
    if (!message.isOutgoing || message.type != MessageType.system) {
      return false;
    }
    final deadline = message.extra.reeditDeadlineTs ?? 0;
    final content = message.extra.reeditContent?.trim() ?? '';
    if (deadline <= 0 || content.isEmpty) {
      return false;
    }
    if (message.extra.quoteMessageId?.trim().isNotEmpty == true) {
      return false;
    }
    if (message.extra.forwardedFrom?.trim().isNotEmpty == true) {
      return false;
    }
    if (message.extra.customType?.toUpperCase() == 'FORWARD_COMBINE') {
      return false;
    }
    return DateTime.now().millisecondsSinceEpoch <= deadline;
  }

  Future<void> _confirmSelectionForward(BuildContext context) async {
    final strings = ref.read(appStringsProvider);
    final selectedMessages = _selectedMessages;
    if (selectedMessages.isEmpty) {
      _showAttachmentError(context, strings.chatChooseForwardMessage);
      return;
    }
    if (selectedMessages.length > _maxForwardSelectionCount) {
      _showAttachmentError(
        context,
        strings.chatMaxSelectReached(_maxForwardSelectionCount),
      );
      return;
    }
    final forwardValidationError = _validateForwardMessages(
      messages: selectedMessages,
      strings: strings,
    );
    if (forwardValidationError != null) {
      _showAttachmentError(context, forwardValidationError);
      return;
    }
    final confirmed = await _showForwardConfirmDialog(
      context,
      title: strings.chatForwardMenu,
      targetLabel: strings.chatForwardSelectTarget,
      previewText: strings.chatChooseForwardMessage,
      confirmText: strings.chatForwardDialogSend,
    );
    if (confirmed != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _openForwardTargetPage(context, selectedMessages);
  }

  String? _validateForwardMessages({
    required List<Message> messages,
    required AppLocalizations strings,
  }) {
    return null;
  }

  Future<bool> _openForwardTargetPage(
    BuildContext context,
    List<Message> messages,
  ) async {
    final strings = ref.read(appStringsProvider);
    final forwardValidationError = _validateForwardMessages(
      messages: messages,
      strings: strings,
    );
    if (forwardValidationError != null) {
      _showAttachmentError(context, forwardValidationError);
      return false;
    }
    final messageIds = messages
        .map((item) => item.messageId.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    if (messageIds.isEmpty) {
      _showAttachmentError(context, strings.chatChooseForwardMessage);
      return false;
    }
    if (messageIds.length > _maxForwardSelectionCount) {
      _showAttachmentError(
        context,
        strings.chatMaxSelectReached(_maxForwardSelectionCount),
      );
      return false;
    }
    if (!context.mounted) {
      return false;
    }
    if (_isSelectionMode) {
      _exitSelectionMode();
    }
    await context.pushNamed(
      RouteNames.chatForwardTarget,
      extra: ForwardTargetRouteArgs(
        messageIds: messageIds,
        initialForwardType: 1,
      ),
    );
    return true;
  }

  List<Message> get _selectedMessages {
    final messages = ref.read(chatTimelineControllerProvider(widget.args.chatId)).messages;
    return messages
        .where(
          (message) =>
              _selectedMessageIds.contains(_messageSelectionKey(message)),
        )
        .toList();
  }

  String _messageSelectionKey(Message message) {
    final messageId = message.messageId.trim();
    if (messageId.isNotEmpty) {
      return messageId;
    }
    return message.clientMessageId?.trim() ?? '';
  }

  void _enterSelectionMode(Message message) {
    final selectionKey = _messageSelectionKey(message);
    if (selectionKey.isEmpty ||
        message.type == MessageType.system ||
        message.type == MessageType.voice ||
        message.type == MessageType.location) {
      return;
    }
    setState(() {
      _isSelectionMode = true;
      _isMorePanelVisible = false;
      _isEmojiPanelVisible = false;
      _selectedMessageIds.clear();
    });
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) {
        return;
      }
      _scrollTimelineToBottom();
    });
  }

  void _toggleSelection(Message message) {
    final selectionKey = _messageSelectionKey(message);
    final strings = ref.read(appStringsProvider);
    if (selectionKey.isEmpty || message.type == MessageType.system) {
      return;
    }
    final isSelecting = !_selectedMessageIds.contains(selectionKey);
    if (isSelecting &&
        _selectedMessageIds.length >= _maxForwardSelectionCount) {
      _showAttachmentError(
        context,
        strings.chatMaxSelectReached(_maxForwardSelectionCount),
      );
      return;
    }
    setState(() {
      _isSelectionMode = true;
      if (_selectedMessageIds.contains(selectionKey)) {
        _selectedMessageIds.remove(selectionKey);
      } else {
        _selectedMessageIds.add(selectionKey);
      }
      if (_selectedMessageIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    if (!_isSelectionMode && _selectedMessageIds.isEmpty) {
      return;
    }
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _scrollTimelineToBottom({bool forceJump = false}) {
    if (!_timelineScrollController.hasClients) {
      return;
    }
    final position = _timelineScrollController.position;
    if ((position.maxScrollExtent - position.pixels).abs() <= 1) {
      _settleInitialBottomAlignment();
      return;
    }
    if (forceJump) {
      _timelineScrollController.jumpTo(position.maxScrollExtent);
      _settleInitialBottomAlignment();
      return;
    }
    _timelineScrollController
        .animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        )
        .whenComplete(_settleInitialBottomAlignment);
  }

  void _scheduleBottomStick() {
    for (final delay in const <int>[0, 60, 180, 320]) {
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _scrollTimelineToBottom(forceJump: delay == 0);
        });
      });
    }
  }

  void _handleTimelineScroll() {
    if (!_timelineScrollController.hasClients) {
      return;
    }
    final position = _timelineScrollController.position;
    final top = position.pixels;
    final distanceToBottom = position.maxScrollExtent - top;
    final nextAtBottom = distanceToBottom <= 72;
    if (nextAtBottom != _isTimelineAtBottom) {
      _isTimelineAtBottom = nextAtBottom;
    }
    final delta = top - _lastTimelineScrollTop;
    _lastTimelineScrollTop = top;
    if (top > 48 || delta > 0) {
      return;
    }
    final timelineState = ref.read(chatTimelineControllerProvider(widget.args.chatId));
    if (timelineState.status == ChatTimelineStatus.loading ||
        timelineState.messages.isEmpty ||
        timelineState.viewportState?.hasMoreBefore == false) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHistoryLoadTriggerAt < 500) {
      return;
    }
    final pageState = ref.read(chatControllerProvider(widget.args.chatId));
    _lastHistoryLoadTriggerAt = now;
    unawaited(
      ref
          .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
          .loadOlder(chatId: pageState.entryArgs.chatId),
    );
  }

  // ignore: unused_element
  Future<void> _showEmojiPicker(
    BuildContext context,
    ChatComposerController composer,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EmojiStickerPickerSheet(
          chatId: widget.args.chatId,
          conversationType: widget.args.conversationType,
          targetId: widget.args.targetId,
          stickerRepository: ref.read(stickerRepositoryProvider),
          fileRepository: ref.read(fileRepositoryProvider),
          mediaPickerService: ref.read(mediaPickerServiceProvider),
          currentUserId: ref.read(authSessionProvider).userId,
          onManage: () => context.pushNamed(RouteNames.chatStickerManage),
          onInsertEmoji: (emojiCode) {
            _insertEmojiIntoComposer(composer, emojiCode);
          },
          onDeleteEmoji: () {
            _deleteEmojiFromComposer(composer);
          },
          onSendSticker: (payload) async {
            if (!_ensureConversationWritable(context)) {
              return false;
            }
            final sent = await ref
                .read(chatControllerProvider(widget.args.chatId).notifier)
                .sendSticker(payload);
            if (!sent && context.mounted) {
              final strings = ref.read(appStringsProvider);
              final error = ref.read(chatControllerProvider(widget.args.chatId)).error;
              if (_handleGroupLifecycleRequestError(
                context,
                error,
                fallbackNotice: strings.chatGroupRemovedCannotSend,
              )) {
                return false;
              }
              final errorMessage = error?.message.trim() ?? '';
              _showAttachmentError(
                context,
                errorMessage.isNotEmpty ? errorMessage : strings.messageFailed,
              );
            }
            return sent;
          },
          onShowNotice: (text) => _showAttachmentError(context, text),
          onShowSuccessNotice: (text) => _showAttachmentSuccess(context, text),
        );
      },
    );
  }

  Future<void> _startVoiceRecording(Offset globalPosition) async {
    if (_isRecording) {
      return;
    }
    if (!_ensureConversationWritable(context)) {
      return;
    }
    _isVoicePressActive = true;
    final session = ++_voicePressSession;
    final service = ref.read(audioRecordingServiceProvider);
    final hasPermission = await service.ensurePermission();
    if (!_isVoicePressCurrent(session)) {
      return;
    }
    if (!hasPermission) {
      _isVoicePressActive = false;
      if (mounted) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatRecordPermissionDenied,
        );
      }
      return;
    }
    await service.prepareProfile();
    final path = await _buildVoiceRecordingPath(service.fileExtension);
    try {
      await service.start(path: path);
      if (!_isVoicePressCurrent(session)) {
        await service.cancel();
        return;
      }
      _recordAmplitudeSubscription?.cancel();
      _recordAmplitudeSubscription = service
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
            if (!mounted) {
              return;
            }
            setState(() {
              _recordingAmplitude = amplitude.current;
            });
          });
      _timerManager.cancel('recording');
      _timerManager.setPeriodic('recording', Timer.periodic(const Duration(milliseconds: 100), (_) {
        final startAt = _recordStartAt;
        if (!mounted || startAt == null) {
          return;
        }
        final elapsed = DateTime.now().difference(startAt).inMilliseconds;
        if (elapsed >= _maxVoiceDurationMs) {
          _finishVoiceRecording();
          return;
        }
        setState(() {
          _recordingElapsedMs = elapsed;
        });
      }));
      setState(() {
        _recordStartY = globalPosition.dy;
        _recordStartAt = DateTime.now();
        _recordingElapsedMs = 0;
        _recordingAmplitude = -160;
        _isCancelReady = false;
        _isRecording = true;
      });
    } catch (error) {
      if (mounted) {
        _showAttachmentError(context, error.toString());
      }
    }
  }

  void _updateVoiceRecordingGesture(Offset globalPosition) {
    if (!_isRecording) {
      return;
    }
    final nextCancelReady =
        (_recordStartY - globalPosition.dy) >= _voiceCancelThreshold;
    if (nextCancelReady == _isCancelReady || !mounted) {
      return;
    }
    setState(() {
      _isCancelReady = nextCancelReady;
    });
  }

  Future<void> _finishVoiceRecording() async {
    _isVoicePressActive = false;
    if (!_isRecording) {
      return;
    }
    final service = ref.read(audioRecordingServiceProvider);
    final shouldCancel = _isCancelReady;
    _timerManager.cancel('recording');
    _recordAmplitudeSubscription?.cancel();
    _recordAmplitudeSubscription = null;
    final durationMs = _recordingElapsedMs;
    _resetVoiceRecordingUi();
    if (shouldCancel) {
      return;
    }
    if (!mounted) {
      return;
    }
    if (durationMs < _minVoiceDurationMs) {
      _showAttachmentError(
        context,
        ref.read(appStringsProvider).chatRecordTooShort,
      );
      return;
    }
    try {
      final path = await service.stop();
      if (path == null || path.trim().isEmpty) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatRecordFileCreateFailed,
        );
        return;
      }
      if (durationMs >
          _maxVoiceDurationMs + _voiceDurationOverflowToleranceMs) {
        _showAttachmentError(context, _buildVoiceDurationInvalidHint());
        return;
      }
      final localPath = path.trim();
      final uploadBytes = await _resolveVoiceUploadBytes(localPath);
      if (kIsWeb && (uploadBytes == null || uploadBytes.isEmpty)) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatRecordFileCreateFailed,
        );
        return;
      }
      final sourceSize = await _resolveVoiceSourceSize(
        localPath,
        uploadBytes: uploadBytes,
      );
      if (!mounted) {
        return;
      }
      if (sourceSize != null && sourceSize > _maxVoiceSize) {
        _showAttachmentError(context, _buildVoiceTooLargeHint(sourceSize));
        return;
      }
      await _uploadVoiceMessage(
        localPath,
        durationMs,
        uploadBytes: uploadBytes,
        sourceSize: sourceSize,
      );
    } catch (error) {
      _resetVoiceRecordingUi();
      if (mounted) {
        _showAttachmentError(context, error.toString());
      }
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _isVoicePressActive = false;
    if (!_isRecording) {
      return;
    }
    _timerManager.cancel('recording');
    _recordAmplitudeSubscription?.cancel();
    _recordAmplitudeSubscription = null;
    try {
      await ref.read(audioRecordingServiceProvider).cancel();
    } finally {
      _resetVoiceRecordingUi();
    }
  }

  void _resetVoiceRecordingUi() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isRecording = false;
      _isCancelReady = false;
      _recordingElapsedMs = 0;
      _recordingAmplitude = -160;
      _recordStartY = 0;
      _recordStartAt = null;
    });
  }

  Future<void> _uploadVoiceMessage(
    String localPath,
    int durationMs, {
    Uint8List? uploadBytes,
    int? sourceSize,
  }) async {
    await _performVoiceUpload(
      localPath: localPath,
      durationMs: durationMs,
      uploadBytes: uploadBytes,
      sourceSize: sourceSize,
    );
  }

  Future<bool> _retryVoiceMessage(Message message) async {
    if (message.status != MessageStatus.failed) {
      return false;
    }
    final localPath = message.extra.localPath?.trim() ?? '';
    if (localPath.isEmpty) {
      return false;
    }
    return _performVoiceUpload(
      localPath: localPath,
      durationMs:
          message.extra.durationMs ??
          ((message.extra.duration ?? 1).clamp(1, 60) * 1000),
      retryMessage: message,
      sourceSize: message.extra.fileSize,
    );
  }

  Future<bool> _performVoiceUpload({
    required String localPath,
    required int durationMs,
    Message? retryMessage,
    Uint8List? uploadBytes,
    int? sourceSize,
  }) async {
    if (durationMs < _minVoiceDurationMs) {
      if (mounted) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatRecordTooShort,
        );
      }
      return false;
    }
    if (durationMs > _maxVoiceDurationMs + _voiceDurationOverflowToleranceMs) {
      if (mounted) {
        _showAttachmentError(context, _buildVoiceDurationInvalidHint());
      }
      return false;
    }
    final resolvedUploadBytes =
        uploadBytes ?? await _resolveVoiceUploadBytes(localPath);
    final resolvedSourceSize =
        sourceSize ??
        await _resolveVoiceSourceSize(
          localPath,
          uploadBytes: resolvedUploadBytes,
        );
    if (resolvedSourceSize != null && resolvedSourceSize > _maxVoiceSize) {
      if (mounted) {
        _showAttachmentError(
          context,
          _buildVoiceTooLargeHint(resolvedSourceSize),
        );
      }
      return false;
    }
    final durationSeconds = (durationMs / 1000).round().clamp(1, 60);
    final recordingService = ref.read(audioRecordingServiceProvider);
    final format = retryMessage?.extra.fileType?.trim().isNotEmpty == true
        ? retryMessage!.extra.fileType!.trim()
        : recordingService.formatLabel;
    final mimeType = _voiceMimeTypeForFormat(format);
    final displayName = 'voice.$format';
    final localMessage =
        retryMessage ??
        ref
            .read(optimisticMessageFactoryProvider)
            .createVoice(
              chatId: widget.args.chatId,
              localPath: localPath,
              duration: durationSeconds,
              durationMs: durationMs,
              fileSize: resolvedSourceSize ?? 0,
              format: format,
            );
    final retryKey = localMessage.clientMessageId ?? localMessage.messageId;
    if (retryMessage == null) {
      ref
          .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
          .appendSingleMessage(localMessage);
    } else {
      ref
          .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
          .markSendingByClientMessageId(clientMessageId: retryKey);
    }
    ref
        .read(conversationListControllerProvider.notifier)
        .upsertLocalMessage(
          chatId: localMessage.chatId,
          title: ref.read(chatControllerProvider(widget.args.chatId)).chatTitle ?? '',
          conversationType: widget.args.conversationType,
          targetId: widget.args.targetId,
          messageId: retryKey,
          messageSequence: localMessage.sequence,
          preview: createConversationPreviewFormatter(
            ref.read(appLocaleProvider),
          ).call(
            type: localMessage.type,
            content: localMessage.content,
            customType: localMessage.extra.customType,
            fileName: localMessage.extra.fileName,
            systemEventKey: localMessage.extra.systemEventKey,
            systemEventParams: localMessage.extra.systemEventParams,
            conversationType: widget.args.conversationType,
            isSelf: localMessage.isOutgoing,
            senderName: localMessage.senderName,
          ),
          messageType: localMessage.type,
          senderName: localMessage.senderName,
          isSelf: localMessage.isOutgoing,
          customType: localMessage.extra.customType,
          fileName: localMessage.extra.fileName,
          systemEventKey: localMessage.extra.systemEventKey,
          systemEventParams: localMessage.extra.systemEventParams,
          messageStatus: MessageStatus.sending,
          updatedAt: DateTime.now(),
          resetUnread: true,
        );
    try {
      final upload = await ref
          .read(fileRepositoryProvider)
          .uploadAndCreateFile(
            taskId: retryKey,
            purpose: UploadPurpose.chatVoice,
            scope: _resolveUploadScope(),
            localUri: localPath,
            displayName: displayName,
            mimeType: mimeType,
            bytes: resolvedUploadBytes,
            maxSize: _maxVoiceSize,
          );
      final target = _resolveLegacySendTarget();
      final sent = await ref
          .read(messageRepositoryProvider)
          .sendVoiceMessage(
            chatId: widget.args.chatId,
            fileId: upload.file.fileId,
            url: upload.file.url,
            duration: durationSeconds,
            size: upload.file.size > _maxVoiceSize
                ? _maxVoiceSize
                : upload.file.size,
            durationMs: durationMs,
            format: format,
            md5: upload.file.md5 ?? '',
            clientMessageId: retryKey,
            receiverId: target.receiverId,
            groupId: target.groupId,
          );
      final normalizedSent = _normalizeSentVoiceMessage(
        fallback: localMessage,
        message: sent.message,
        durationSeconds: durationSeconds,
        durationMs: durationMs,
        fileSize: upload.file.size,
        format: format,
        mimeType: mimeType,
        fileId: upload.file.fileId,
        fileUrl: upload.file.url,
        md5: upload.file.md5 ?? '',
      );
      ref
          .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
          .replaceSingleMessage(
            clientMessageId: retryKey,
            message: normalizedSent,
          );
      ref
          .read(conversationListControllerProvider.notifier)
          .upsertLocalMessage(
            chatId: normalizedSent.chatId,
            title: ref.read(chatControllerProvider(widget.args.chatId)).chatTitle ?? '',
            conversationType: widget.args.conversationType,
            targetId: widget.args.targetId,
            messageId: normalizedSent.messageId,
            messageSequence: normalizedSent.sequence,
            preview: createConversationPreviewFormatter(
              ref.read(appLocaleProvider),
            ).call(
              type: normalizedSent.type,
              content: normalizedSent.content,
              customType: normalizedSent.extra.customType,
              fileName: normalizedSent.extra.fileName,
              systemEventKey: normalizedSent.extra.systemEventKey,
              systemEventParams: normalizedSent.extra.systemEventParams,
              conversationType: widget.args.conversationType,
              isSelf: normalizedSent.isOutgoing,
              senderName: normalizedSent.senderName,
            ),
            messageType: normalizedSent.type,
            senderName: normalizedSent.senderName,
            isSelf: normalizedSent.isOutgoing,
            customType: normalizedSent.extra.customType,
            fileName: normalizedSent.extra.fileName,
            systemEventKey: normalizedSent.extra.systemEventKey,
            systemEventParams: normalizedSent.extra.systemEventParams,
            messageStatus: normalizedSent.status,
            updatedAt: normalizedSent.sentAt,
            resetUnread: true,
          );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      if (_handleGroupLifecycleRequestError(
        context,
        error,
        fallbackNotice: ref.read(appStringsProvider).chatGroupRemovedCannotSend,
      )) {
        return false;
      }
      ref
          .read(chatTimelineControllerProvider(widget.args.chatId).notifier)
          .markFailedByClientMessageId(clientMessageId: retryKey);
      ref
          .read(conversationListControllerProvider.notifier)
          .patchLastMessageStatus(
            chatId: localMessage.chatId,
            messageId: retryKey,
            status: MessageStatus.failed,
          );
      if (mounted) {
        _showAttachmentError(context, error.toString());
      }
      return false;
    }
  }

  bool _isVoicePressCurrent(int session) {
    return mounted && _isVoicePressActive && _voicePressSession == session;
  }

  Future<String> _buildVoiceRecordingPath(String extension) async {
    final fileName =
        'voice_${DateTime.now().microsecondsSinceEpoch}.$extension';
    if (kIsWeb) {
      return fileName;
    }
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/$fileName';
  }

  String _voiceMimeTypeForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'wav':
        return 'audio/wav';
      case 'pcm':
      case 'pcm16bits':
        return 'audio/pcm';
      case 'webm':
      case 'opus':
        return 'audio/webm';
      case 'm4a':
      case 'aac':
      default:
        return 'audio/mp4';
    }
  }

  Message _normalizeSentVoiceMessage({
    required Message fallback,
    required Message message,
    required int durationSeconds,
    required int durationMs,
    required int fileSize,
    required String format,
    required String mimeType,
    required String fileId,
    required String fileUrl,
    required String md5,
  }) {
    final base = message.copyWith(
      type: MessageType.voice,
      status: message.status == MessageStatus.sending
          ? MessageStatus.sent
          : message.status,
      content: '',
      isOutgoing: true,
      clientMessageId: message.clientMessageId ?? fallback.clientMessageId,
    );
    return base.copyWith(
      extra: base.extra.copyWith(
        localPath: fallback.extra.localPath,
        fileId: fileId,
        fileUrl: fileUrl,
        mimeType: mimeType,
        fileType: format,
        fileName: 'voice.$format',
        fileSize: fileSize,
        duration: durationSeconds,
        durationMs: durationMs,
        voicePlayed: true,
        md5: md5,
      ),
    );
  }

  Future<int?> _resolveVoiceSourceSize(
    String localPath, {
    Uint8List? uploadBytes,
  }) async {
    if (uploadBytes != null) {
      return uploadBytes.lengthInBytes;
    }
    return loadLocalFileSize(localPath);
  }

  Future<Uint8List?> _resolveVoiceUploadBytes(String localPath) async {
    if (!kIsWeb) {
      return null;
    }
    final normalized = localPath.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('blob:') || normalized.startsWith('data:')) {
      return loadLocalUriBytes(normalized);
    }
    return null;
  }

  String _buildVoiceDurationInvalidHint() {
    return '录音时长异常，请重新录制';
  }

  String _buildVoiceTooLargeHint([int? sizeBytes]) {
    final limitText = _formatBytes(_maxVoiceSize);
    if (sizeBytes != null && sizeBytes > 0) {
      return '语音大小超出限制（${_formatBytes(sizeBytes)} / $limitText）';
    }
    return '语音大小超出限制，最多支持 $limitText';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  ({String? receiverId, String? groupId}) _resolveLegacySendTarget() {
    if (widget.args.conversationType == ConversationType.group) {
      final groupId = (widget.args.targetId ?? widget.args.chatId).trim();
      return (
        receiverId: null,
        groupId: groupId.isEmpty || groupId == '0' ? null : groupId,
      );
    }
    final receiverId = (widget.args.targetId ?? '').trim();
    return (
      receiverId: receiverId.isEmpty || receiverId == '0' ? null : receiverId,
      groupId: null,
    );
  }

  UploadScope _resolveUploadScope() {
    return switch (widget.args.conversationType) {
      ConversationType.group => UploadScope.groupChat(
        groupId: widget.args.targetId ?? widget.args.chatId,
        chatId: widget.args.chatId,
      ),
      _ => UploadScope.directChat(
        chatId: widget.args.chatId,
        targetUserId: widget.args.targetId ?? '',
      ),
    };
  }

  Future<void> _showContactPicker() async {
    final picked = await context.pushNamed<ContactCardSharePayload>(
      RouteNames.chatSelectContactCard,
      extra: const SelectContactCardRouteArgs(),
    );
    if (picked == null || !mounted) {
      return;
    }
    await _sendContactCard(context, picked);
  }

  Future<void> _showLocationPicker() async {
    final picked = await context.push<LocationSharePayload>(
      RoutePaths.chatSelectLocation,
      extra: const SelectLocationRouteArgs(),
    );
    if (picked == null || !mounted) {
      return;
    }
    await _sendLocation(context, picked);
  }

  Future<void> _sendContactCard(
    BuildContext context,
    ContactCardSharePayload payload,
  ) async {
    final strings = ref.read(appStringsProvider);
    if (!_ensureConversationWritable(context)) {
      return;
    }
    try {
      final sent = await ref
          .read(chatControllerProvider(widget.args.chatId).notifier)
          .sendContactCard(payload);
      if (!sent) {
        if (!context.mounted) {
          return;
        }
        final error = ref.read(chatControllerProvider(widget.args.chatId)).error;
        if (_handleGroupLifecycleRequestError(
          context,
          error,
          fallbackNotice: strings.chatGroupRemovedCannotSend,
        )) {
          return;
        }
        final errorMessage = error?.message.trim() ?? '';
        _showAttachmentError(
          context,
          errorMessage.isNotEmpty ? errorMessage : strings.messageFailed,
        );
        return;
      }
      if (!context.mounted) {
        return;
      }
    } catch (error) {
      if (_handleGroupLifecycleRequestError(
        context,
        error,
        fallbackNotice: strings.chatGroupRemovedCannotSend,
      )) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      _showAttachmentError(context, error.toString());
    }
  }

  Future<void> _sendLocation(
    BuildContext context,
    LocationSharePayload payload,
  ) async {
    final strings = ref.read(appStringsProvider);
    if (!_ensureConversationWritable(context)) {
      return;
    }
    try {
      final sent = await ref
          .read(chatControllerProvider(widget.args.chatId).notifier)
          .sendLocation(payload);
      if (!sent) {
        if (!context.mounted) {
          return;
        }
        final error = ref.read(chatControllerProvider(widget.args.chatId)).error;
        if (_handleGroupLifecycleRequestError(
          context,
          error,
          fallbackNotice: strings.chatGroupRemovedCannotSend,
        )) {
          return;
        }
        final errorMessage = error?.message.trim() ?? '';
        _showAttachmentError(
          context,
          errorMessage.isNotEmpty ? errorMessage : strings.messageFailed,
        );
        return;
      }
      // 发送成功不显示提示（微信行为）
    } catch (error) {
      if (_handleGroupLifecycleRequestError(
        context,
        error,
        fallbackNotice: strings.chatGroupRemovedCannotSend,
      )) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      _showAttachmentError(context, error.toString());
    }
  }

  void _openLocationMessage(
    BuildContext context,
    Message message,
  ) {
    final strings = ref.read(appStringsProvider);
    final latitude = message.extra.locationLatitude;
    final longitude = message.extra.locationLongitude;
    if (latitude == null || longitude == null) {
      _showAttachmentError(context, strings.chatLocationMissing);
      return;
    }
    final locationName = message.extra.locationName?.trim() ?? '';
    final address = message.extra.locationAddress?.trim() ?? '';
    
    // 直接跳转到位置详情页
    context.pushNamed(
      RouteNames.chatLocationDetail,
      extra: LocationSharePayload(
        name: locationName.isNotEmpty
            ? locationName
            : strings.chatLocationDefaultTitle,
        address: address,
        latitude: latitude,
        longitude: longitude,
        provider: message.extra.locationProvider ?? 'unknown',
      ),
    );
  }

  String _buildLocationClipboardPayload({
    required String locationName,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final parts = <String>[];
    if (locationName.trim().isNotEmpty) {
      parts.add(locationName.trim());
    }
    if (address.trim().isNotEmpty && address.trim() != locationName.trim()) {
      parts.add(address.trim());
    }
    parts.add(
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
    );
    return parts.join('\n');
  }

  void _insertEmojiIntoComposer(
    ChatComposerController composer,
    String emojiCode,
  ) {
    final controller = composer.textController;
    controller.insertToken(emojiCode);
    _updateComposerLineCount(controller.text);
  }

  void _deleteEmojiFromComposer(ChatComposerController composer) {
    final controller = composer.textController;
    controller.deletePreviousUnit();
    _updateComposerLineCount(controller.text);
  }
}

class _ReadReceiptBottomSheet extends StatefulWidget {
  const _ReadReceiptBottomSheet({
    required this.messageId,
    required this.chatTitle,
    required this.messagePreview,
    required this.isVoiceMessage,
    this.initialSummary,
    required this.repository,
    required this.onSummaryLoaded,
    required this.onShowNotice,
  });

  final String messageId;
  final String chatTitle;
  final String messagePreview;
  final bool isVoiceMessage;
  final ReadReceiptSummary? initialSummary;
  final MessageRepository repository;
  final ValueChanged<ReadReceiptSummary?> onSummaryLoaded;
  final ValueChanged<String> onShowNotice;

  @override
  State<_ReadReceiptBottomSheet> createState() =>
      _ReadReceiptBottomSheetState();
}

class _ReadReceiptBottomSheetState extends State<_ReadReceiptBottomSheet> {
  static const int _pageSize = 20;

  ReadReceiptSummary? _summary;
  List<ReadReceiptDetailItem> _items = const <ReadReceiptDetailItem>[];
  String _selectedTab = 'read';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _pageNo = 1;
  String? _error;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _pageNo = 1;
      _selectedTab = 'read';
      _error = null;
      _summary = widget.initialSummary;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final summary =
          widget.initialSummary ??
          await widget.repository.getReadReceiptSummary(
            messageId: widget.messageId,
          );
      if (summary == null) {
        if (!mounted) {
          return;
        }
        widget.onSummaryLoaded(null);
        widget.onShowNotice(
          AppLocalizations.of(context).chatReadReceiptDataLoading,
        );
        Navigator.of(context).pop();
        return;
      }
      widget.onSummaryLoaded(summary);
      final items = await widget.repository.getReadReceiptDetail(
        messageId: widget.messageId,
        status: 'read',
        pageNo: 1,
        pageSize: _pageSize,
      );
      if (!mounted) {
        return;
      }
      final total = summary.readCount;
      setState(() {
        _summary = summary;
        _selectedTab = 'read';
        _items = items;
        _hasMore = items.length < total;
        _pageNo = items.isNotEmpty ? 2 : 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _switchTab(String value) async {
    if (_selectedTab == value) {
      return;
    }
    setState(() {
      _selectedTab = value;
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _pageNo = 1;
      _error = null;
    });
    try {
      final items = await widget.repository.getReadReceiptDetail(
        messageId: widget.messageId,
        status: value,
        pageNo: 1,
        pageSize: _pageSize,
      );
      if (!mounted) {
        return;
      }
      final total = value == 'read'
          ? (_summary?.readCount ?? 0)
          : (_summary?.unreadCount ?? 0);
      setState(() {
        _items = items;
        _hasMore = items.length < total;
        _pageNo = items.isNotEmpty ? 2 : 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        !_hasMore ||
        _error != null) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 48) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
    });
    try {
      final items = await widget.repository.getReadReceiptDetail(
        messageId: widget.messageId,
        status: _selectedTab,
        pageNo: _pageNo,
        pageSize: _pageSize,
      );
      if (!mounted) {
        return;
      }
      final total = _selectedTab == 'read'
          ? (_summary?.readCount ?? 0)
          : (_summary?.unreadCount ?? 0);
      final merged = <ReadReceiptDetailItem>[..._items, ...items];
      setState(() {
        _items = merged;
        _pageNo = items.isNotEmpty ? _pageNo + 1 : _pageNo;
        _hasMore = merged.length < total && items.isNotEmpty;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final readCount = _summary?.readCount ?? 0;
    final unreadCount = _summary?.unreadCount ?? 0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          height: 428,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.chatReadReceiptTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeColors.textPrimary(context),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          strings.chatReadReceiptClose,
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: ThemeColors.divider(context)),
              if (widget.isVoiceMessage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.chatReadReceiptVoiceHint,
                      style: TextStyle(
                        fontSize: 11,
                        height: 16 / 11,
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ),
                ),
              Container(
                margin: EdgeInsets.fromLTRB(
                  16,
                  widget.isVoiceMessage ? 6 : 10,
                  16,
                  0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: _ReadReceiptTabSummary(
                        label: strings.chatReadReceiptReadLabel,
                        count: readCount,
                        active: _selectedTab == 'read',
                        onTap: () => _switchTab('read'),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: ThemeColors.divider(context),
                    ),
                    SizedBox(
                      width: 120,
                      child: _ReadReceiptTabSummary(
                        label: strings.chatReadReceiptUnreadTab,
                        count: unreadCount,
                        active: _selectedTab == 'unread',
                        onTap: () => _switchTab('unread'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_loading) {
                      return Center(
                        child: Text(
                          strings.chatReadReceiptLoading,
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.textSecondary(context),
                          ),
                        ),
                      );
                    }
                    if (_error != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ThemeColors.textSecondary(context)),
                          ),
                        ),
                      );
                    }
                    if (_items.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedTab == 'read'
                              ? strings.chatReadReceiptEmptyRead
                              : strings.chatReadReceiptEmptyUnread,
                          style: TextStyle(color: ThemeColors.textSecondary(context)),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                _loadingMore
                                    ? strings.chatReadReceiptLoading
                                    : strings.chatReadReceiptNoMore,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeColors.textSecondary(context),
                                ),
                              ),
                            ),
                          );
                        }
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: item.avatar.trim().isEmpty
                                      ? DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: getUserAvatarColor(item.userId),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              getAvatarText(item.userName),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Image.network(
                                          item.avatar,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.userName.trim().isEmpty
                                          ? item.userId
                                          : item.userName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: ThemeColors.textPrimary(context),
                                      ),
                                    ),
                                    if (_selectedTab == 'read' &&
                                        _buildReadTime(item).isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _buildReadTime(item),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ThemeColors.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 0),
                      itemCount:
                          _items.length +
                          ((_loadingMore || !_hasMore) && _items.isNotEmpty
                              ? 1
                              : 0),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildReadTime(ReadReceiptDetailItem item) {
    if (_selectedTab != 'read') {
      return '';
    }
    final time = item.readTime;
    if (time == null) {
      return '';
    }
    final strings = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(time);
    if (!diff.isNegative && diff < const Duration(minutes: 1)) {
      return strings.chatReadReceiptJustNow;
    }
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);
    final days = today.difference(messageDay).inDays;
    if (days == 0) {
      return strings.chatReadReceiptTodayAt('$hh:$mm');
    }
    if (days == 1) {
      return strings.chatReadReceiptYesterdayAt('$hh:$mm');
    }
    final yyyy = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '$yyyy-$month-$day $hh:$mm';
  }
}

class _ReadReceiptTabSummary extends StatelessWidget {
  const _ReadReceiptTabSummary({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF246BFD) : ThemeColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiStickerPickerSheet extends StatefulWidget {
  const _EmojiStickerPickerSheet({
    required this.chatId,
    required this.conversationType,
    required this.targetId,
    required this.stickerRepository,
    required this.fileRepository,
    required this.mediaPickerService,
    required this.currentUserId,
    required this.onManage,
    required this.onInsertEmoji,
    required this.onDeleteEmoji,
    required this.onSendSticker,
    required this.onShowNotice,
    required this.onShowSuccessNotice,
  });

  final String chatId;
  final ConversationType conversationType;
  final String? targetId;
  final StickerRepository stickerRepository;
  final FileRepository fileRepository;
  final MediaPickerService mediaPickerService;
  final String currentUserId;
  final VoidCallback onManage;
  final ValueChanged<String> onInsertEmoji;
  final VoidCallback onDeleteEmoji;
  final Future<bool> Function(StickerPayload payload) onSendSticker;
  final ValueChanged<String> onShowNotice;
  final ValueChanged<String> onShowSuccessNotice;

  @override
  State<_EmojiStickerPickerSheet> createState() =>
      _EmojiStickerPickerSheetState();
}

class _EmojiStickerPickerSheetState extends State<_EmojiStickerPickerSheet> {
  static const _recentEmojiStorageKey = 'im_chat_recent_emoji_v1';
  static final List<String> _emojiItems = ChatEmojiCatalog.codes;

  String _tab = 'emoji';
  bool _loading = true;
  bool _uploadingSticker = false;
  String? _error;
  List<String> _recentEmojis = const <String>[];
  List<StickerItem> _recent = const <StickerItem>[];
  List<StickerItem> _favorites = const <StickerItem>[];

  @override
  void initState() {
    super.initState();
    _loadRecentEmojis();
    _loadStickers();
  }

  Future<void> _loadRecentEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_recentEmojiStorageKey) ?? const <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _recentEmojis = stored
          .where((item) => _emojiItems.contains(item))
          .toList(growable: false);
    });
  }

  Future<void> _touchRecentEmoji(String emojiCode) async {
    final next = <String>[
      emojiCode,
      ..._recentEmojis.where((item) => item != emojiCode),
    ];
    if (next.length > 24) {
      next.removeRange(24, next.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentEmojiStorageKey, next);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentEmojis = next;
    });
  }

  Future<void> _loadStickers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await widget.stickerRepository.getStickerCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _recent = catalog.recent;
        _favorites = catalog.favorites;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendSticker(StickerItem item) async {
    try {
      try {
        await widget.stickerRepository.recordRecentUse(
          stickerId: item.stickerId,
        );
      } catch (_) {
        // 老项目这里是附加链路，失败不阻断发送。
      }
      final sent = await widget.onSendSticker(
        StickerPayload(
          stickerId: item.stickerId,
          fileId: item.fileId ?? '',
          url: item.url,
          thumbFileId: item.thumbFileId,
          thumbUrl: item.thumbUrl,
          md5: item.md5,
          width: item.width ?? 0,
          height: item.height ?? 0,
          mimeType: item.mimeType,
        ),
      );
      if (!mounted || !sent) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      widget.onShowNotice(error.toString());
    }
  }

  Future<void> _uploadSticker() async {
    if (_uploadingSticker || widget.currentUserId.trim().isEmpty) {
      return;
    }
    final strings = AppLocalizations.of(context);
    final currentCount = _buildStickerList().length;
    if (currentCount >= _ChatPageState._maxStickerCount) {
      widget.onShowNotice(
        strings.chatMaxStickerReached(_ChatPageState._maxStickerCount),
      );
      return;
    }
    setState(() {
      _uploadingSticker = true;
    });
    try {
      final picked = await widget.mediaPickerService.pickImage();
      if (picked == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _uploadingSticker = false;
        });
        return;
      }
      final upload = await widget.fileRepository.uploadAndCreateFile(
        taskId: DateTime.now().microsecondsSinceEpoch.toString(),
        purpose: UploadPurpose.stickerOriginal,
        scope: UploadScope.sticker(userId: widget.currentUserId),
        localUri: picked.path,
        displayName: picked.name.trim().isEmpty ? 'sticker' : picked.name,
        mimeType: picked.mimeType,
        bytes: picked.bytes,
      );
      final uploaded = await widget.stickerRepository.uploadSticker(
        fileId: upload.file.fileId,
        url: upload.file.url,
        name: upload.file.name,
        md5: upload.file.md5 ?? '',
        mimeType: upload.file.mimeType,
      );
      await _loadStickers();
      if (!mounted) {
        return;
      }
      widget.onShowSuccessNotice(strings.chatStickerAdded);
      await _sendSticker(uploaded);
    } catch (error) {
      if (mounted) {
        widget.onShowNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingSticker = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final allStickers = _buildStickerList();
    return SafeArea(
      top: false,
      child: Container(
        height: 252,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: ThemeColors.divider(context), width: 1)),
        ),
        child: Column(
          children: [
            Expanded(
              child: _tab == 'emoji'
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      children: [
                        if (_recentEmojis.isNotEmpty) ...[
                          Text(
                            strings.chatEmojiRecent,
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _EmojiGrid(
                            items: _recentEmojis,
                            onTap: (emojiCode) async {
                              await _touchRecentEmoji(emojiCode);
                              widget.onInsertEmoji(emojiCode);
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          strings.chatEmojiAll,
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _EmojiGrid(
                          items: _emojiItems,
                          onTap: (emojiCode) async {
                            await _touchRecentEmoji(emojiCode);
                            widget.onInsertEmoji(emojiCode);
                          },
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _uploadingSticker
                                    ? null
                                    : _uploadSticker,
                                icon: AppIcon(
                                  AppIconKind.add,
                                  size: 18,
                                  color: ThemeColors.textPrimary(context),
                                ),
                                label: Text(
                                  _uploadingSticker
                                      ? strings.chatUploading
                                      : strings.chatStickerAdd,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onManage();
                                },
                                child: Text(strings.chatEmojiManage),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              if (_loading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (_error != null) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: ThemeColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (allStickers.isEmpty) {
                                return Center(
                                  child: Text(
                                    strings.chatMediaEmpty,
                                    style: TextStyle(
                                      color: ThemeColors.textSecondary(context),
                                    ),
                                  ),
                                );
                              }
                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  2,
                                  12,
                                  10,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: allStickers.length,
                                itemBuilder: (context, index) {
                                  final item = allStickers[index];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _sendSticker(item),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: DecoratedBox(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF6F8FC),
                                        ),
                                        child: Image.network(
                                          item.url,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Center(
                                                  child: Icon(
                                                    Icons
                                                        .emoji_emotions_outlined,
                                                    color: ThemeColors.textSecondary(context),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ThemeColors.divider(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _PickerIconTab(
                      icon: AppIconKind.smile,
                      active: _tab == 'emoji',
                      onTap: () => setState(() => _tab = 'emoji'),
                    ),
                  ),
                  Expanded(
                    child: _PickerIconTab(
                      icon: AppIconKind.starOutline,
                      active: _tab == 'sticker',
                      onTap: () => setState(() => _tab = 'sticker'),
                    ),
                  ),
                  if (_tab == 'emoji')
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: widget.onDeleteEmoji,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 28,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE1E6EF),
                              width: 0.8,
                            ),
                          ),
                          child: const Center(
                            child: AppIcon(
                              AppIconKind.backspace,
                              size: 15,
                              color: Color(0xFF6B7380),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<StickerItem> _buildStickerList() {
    final seen = <String>{};
    final merged = <StickerItem>[];
    for (final item in [..._recent, ..._favorites]) {
      if (item.stickerId.isEmpty || seen.contains(item.stickerId)) {
        continue;
      }
      seen.add(item.stickerId);
      merged.add(item);
    }
    return merged;
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.items, required this.onTap});

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.42,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final assets = ChatEmojiCatalog.candidateAssetsFor(item);
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(item),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: assets.isEmpty
                  ? Text(
                      item,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.textPrimary(context),
                      ),
                    )
                  : ChatEmojiAssetImage(
                      assets: assets,
                      size: 28,
                      empty: const SizedBox(width: 28, height: 28),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _PickerIconTab extends StatelessWidget {
  const _PickerIconTab({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final AppIconKind icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: active
              ? const Border(
                  top: BorderSide(color: Color(0xFF2F6BFF), width: 2),
                )
              : null,
        ),
        child: Center(
          child: AppIcon(
            icon,
            size: 22,
            color: active ? const Color(0xFF2F6BFF) : ThemeColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _MentionRange {
  const _MentionRange({required this.startIndex, required this.endIndex});

  final int startIndex;
  final int endIndex;
}

class _TypingEntry {
  const _TypingEntry({
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  final String userId;
  final String userName;
  final DateTime timestamp;
}
