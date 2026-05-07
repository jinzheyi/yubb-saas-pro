import 'dart:async';
import 'dart:convert';

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
import 'package:shengyu_ui_admin_im/core/platform/media_picker_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_outbound_sender.dart';
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
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_more_panel_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_message_action.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_more_panel_action.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_page_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_timeline_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_media_content_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_composer.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_page_panels.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_timeline.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
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
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_loading_view.dart';

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
  static const double _voiceCancelThreshold = 60;
  static const Duration _voicePlayedSyncDebounce = Duration(milliseconds: 300);
  static const Duration _voicePlayedCompensateInterval = Duration(seconds: 12);
  static const int _voicePlayedSyncBatchSize = 30;
  static const int _voicePlayedCompensateMaxIds = 80;
  static const int _voicePlayedCompensateBatchSize = 40;
  static const Duration _typingTimeout = Duration(seconds: 3);
  static const Duration _typingDebounce = Duration(milliseconds: 500);
  static const Duration _readReceiptSummaryTtl = Duration(minutes: 10);
  static const int _readReceiptSummaryCacheMax = 200;
  bool _isMorePanelVisible = false;
  bool _isEmojiPanelVisible = false;
  bool _isSelectionMode = false;
  bool _isVoiceMode = false;
  bool _isMentionPanelVisible = false;
  bool _isFullExpanded = false;
  bool _isRecording = false;
  bool _isCancelReady = false;
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
  int _recordingElapsedMs = 0;
  int _reeditNowTs = DateTime.now().millisecondsSinceEpoch;
  double _recordingAmplitude = -160;
  double _recordStartY = 0;
  DateTime? _recordStartAt;
  StreamSubscription<Amplitude>? _recordAmplitudeSubscription;
  StreamSubscription<Duration>? _voicePositionSubscription;
  StreamSubscription<Duration?>? _voiceDurationSubscription;
  StreamSubscription<PlayerState>? _voicePlayerStateSubscription;
  Timer? _recordingTimer;
  Timer? _reeditTicker;
  late final TextEditingController _mentionSearchController;
  late final FocusNode _composerFocusNode;
  final Map<String, bool> _voicePlayedPendingSync = <String, bool>{};
  String? _activePlayingVoiceMessageId;
  String? _activePausedVoiceMessageId;
  int _activeVoicePlaybackProgressMs = 0;
  int _activeVoicePlaybackDurationMs = 0;
  Timer? _highlightClearTimer;
  Timer? _voicePlayedSyncTimer;
  Timer? _voicePlayedCompensateTimer;
  Timer? _typingCleanupTimer;
  Timer? _typingSendTimer;
  ProviderSubscription<ChatTimelineState>? _timelineSubscription;
  bool _voicePlayedSyncInFlight = false;
  bool _voicePlayedCompensateInFlight = false;
  bool _isTimelineAtBottom = true;
  double _lastViewInsetsBottom = 0;
  late final ScrollController _timelineScrollController;
  final Map<String, _ReadReceiptSummaryCacheEntry> _readReceiptSummaryCache =
      <String, _ReadReceiptSummaryCacheEntry>{};
  final Map<String, bool> _readReceiptSummaryInFlight = <String, bool>{};
  final Map<String, int> _readReceiptSummaryRetryCount = <String, int>{};
  String _lastReadReceiptPrefetchKey = '';
  final Map<String, GlobalKey> _messageItemKeys = <String, GlobalKey>{};
  final Set<String> _transientSystemNotifyKeys = <String>{};
  double _lastTimelineScrollTop = 0;
  int _lastHistoryLoadTriggerAt = 0;
  final Map<String, _TypingEntry> _typingEntries = <String, _TypingEntry>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timelineScrollController = ScrollController()
      ..addListener(_handleTimelineScroll);
    _mentionSearchController = TextEditingController();
    _composerFocusNode = FocusNode();
    _activeHighlightedMessageId =
        widget.args.highlightedMessageId ?? widget.args.anchorMessageId;
    _timelineSubscription = ref.listenManual<ChatTimelineState>(
      chatTimelineControllerProvider,
      (previous, next) {
        _handleTimelineStateChanged(previous, next);
      },
    );
    Future.microtask(() {
      unawaited(_initializeChatPage());
      unawaited(_warmupStickerCatalog());
      unawaited(_restoreVoicePlayedCompensationOnce());
      unawaited(_loadRecallConfig());
    });
    _scheduleHighlightClear();
    _startVoicePlayedCompensation();
    _startReeditTicker();
    _startTypingCleanupTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _highlightClearTimer?.cancel();
    _recordingTimer?.cancel();
    _reeditTicker?.cancel();
    _recordAmplitudeSubscription?.cancel();
    _voicePositionSubscription?.cancel();
    _voiceDurationSubscription?.cancel();
    _voicePlayerStateSubscription?.cancel();
    _voicePlayedSyncTimer?.cancel();
    _voicePlayedCompensateTimer?.cancel();
    _typingCleanupTimer?.cancel();
    _typingSendTimer?.cancel();
    _timelineSubscription?.close();
    unawaited(_flushVoicePlayedSyncQueue(force: true));
    _timelineScrollController.dispose();
    _mentionSearchController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChatPage() async {
    await ref.read(chatControllerProvider.notifier).initialize(widget.args);
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
      _lastViewInsetsBottom = viewInsetsBottom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isTimelineAtBottom) {
          return;
        }
        _scrollTimelineToBottom();
      });
    }
    ref.watch(chatRealtimeBindingProvider(widget.args.chatId));
    ref.listen<ChatRuntimeNotice?>(chatRuntimeNoticeProvider, (prev, next) {
      if (next == null || next.chatId != widget.args.chatId || !mounted) {
        return;
      }
      ref.read(chatRuntimeNoticeProvider.notifier).state = null;
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
    ref.listen<ChatRealtimeSignal?>(chatRealtimeSignalProvider, (prev, next) {
      if (next == null || next.chatId != widget.args.chatId || !mounted) {
        return;
      }
      ref.read(chatRealtimeSignalProvider.notifier).state = null;
      _handleRealtimeSignal(next);
    });
    final strings = ref.watch(appStringsProvider);
    final pageState = ref.watch(chatControllerProvider);
    final timelineState = ref.watch(chatTimelineControllerProvider);
    final composer = ref.watch(chatComposerControllerProvider);
    final mediaState = ref.watch(chatMediaControllerProvider);
    final morePanelController = ref.watch(chatMorePanelControllerProvider);
    final chatTitle = pageState.chatTitle ?? strings.chatTitle;
    final isBusy =
        pageState.pendingAction == ChatPendingAction.sendingMessage ||
        mediaState.isPicking;
    final isGroupChat = widget.args.conversationType == ConversationType.group;
    final conversationState = ref.watch(conversationListControllerProvider);
    final conversation = _resolveConversation(conversationState.conversations);
    final groupId = _resolveGroupId(isGroupChat);
    final groupSettingsState = groupId == null
        ? null
        : ref.watch(
            groupSettingsControllerProvider(
              GroupContextArgs(groupId: groupId, groupName: chatTitle),
            ),
          );
    final groupNoticeText = _resolveGroupNoticeText(groupSettingsState);
    if (isGroupChat && timelineState.messages.isNotEmpty) {
      _scheduleReadReceiptPrefetch(timelineState.messages);
    }
    final groupMembersAsync = groupId == null
        ? const AsyncValue<List<GroupMember>>.data(<GroupMember>[])
        : ref.watch(groupMembersFutureProvider(groupId));
    final currentUserId = ref.watch(authSessionProvider).userId;
    final currentUserAvatarUrl =
        ref.watch(currentUserProfileProvider).valueOrNull?.avatarUrl ?? '';
    final groupMembers = groupMembersAsync.valueOrNull ?? const <GroupMember>[];
    final groupRestrictionHint = _resolveGroupSendRestrictionHint(
      groupSettingsState: groupSettingsState,
      currentUserId: currentUserId,
    );
    final canMentionAll = _resolveCanMentionAll(
      members: groupMembers,
      currentUserId: currentUserId,
    );
    final timelineMessageKeys = <String, GlobalKey>{
      for (final message in timelineState.messages) ...{
        if (message.messageId.trim().isNotEmpty)
          message.messageId.trim(): _ensureMessageItemKey(message.messageId),
        if (message.clientMessageId?.trim().isNotEmpty == true)
          message.clientMessageId!.trim(): _ensureMessageItemKey(
            message.clientMessageId!,
          ),
      },
    };
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
        !pageState.isReadOnly &&
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
      onTapInput: () {},
      onChanged: (value) {
        _updateComposerLineCount(value);
        _handleComposerChanged(
          value,
          isGroupChat: isGroupChat,
          groupId: groupId,
          isReadOnly: pageState.isReadOnly,
        );
      },
      onTapVoice: () {
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
        setState(() {
          _isEmojiPanelVisible = !_isEmojiPanelVisible;
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
      },
      onSend: (value) async {
        if (!_ensureConversationWritable(context)) {
          return;
        }
        final mentionPayload = _buildMentionPayload(value);
        final sent = await ref
            .read(chatControllerProvider.notifier)
            .sendText(
              value,
              quoteInfo: _quoteInfo,
              atUserIds: mentionPayload.atUserIds,
              mentions: mentionPayload.mentions,
            );
        if (!sent) {
          if (!context.mounted) {
            return;
          }
          final error = ref.read(chatControllerProvider).error;
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
      },
      onOpenAttachmentMenu: () {
        setState(() {
          _isMorePanelVisible = !_isMorePanelVisible;
          if (_isMorePanelVisible) {
            _isEmojiPanelVisible = false;
          }
        });
        if ((_isMorePanelVisible || _isEmojiPanelVisible) &&
            _isMentionPanelVisible) {
          _closeMentionPanel();
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
                  .read(chatControllerProvider.notifier)
                  .sendSticker(payload);
              if (!sent && context.mounted) {
                final error = ref.read(chatControllerProvider).error;
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
                pageState: pageState,
                chatTitle: chatTitle,
                morePanelController: morePanelController,
              );
            },
          )
        : null;
    final composerPanels = composerPanel == null
        ? const <Widget>[]
        : <Widget>[composerPanel];
    final body = switch (pageState.pageStatus) {
      ChatPageStatus.initial ||
      ChatPageStatus.initializing => const AppLoadingView(),
      ChatPageStatus.failed => AppErrorView(
        error: pageState.error,
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
                      decoration: const BoxDecoration(color: Color(0xFFF2F5FA)),
                      child: switch (timelineState.status) {
                        ChatTimelineStatus.failed => AppErrorView(
                          error: timelineState.error,
                          onRetry: () {
                            unawaited(_initializeChatPage());
                          },
                        ),
                        _ => ChatTimeline(
                          messages: timelineState.messages,
                          messageItemKeys: timelineMessageKeys,
                          controller: _timelineScrollController,
                          highlightedMessageId: _activeHighlightedMessageId,
                          selectionMode: _isSelectionMode,
                          selectedMessageIds: _selectedMessageIds,
                          isLoadingOlder:
                              timelineState.status ==
                              ChatTimelineStatus.loading,
                          onLoadOlder: () async {
                            final notice = strings.chatNoMoreMessages;
                            final beforeCount = timelineState.messages.length;
                            await ref
                                .read(chatTimelineControllerProvider.notifier)
                                .loadOlder(chatId: pageState.entryArgs.chatId);
                            if (!mounted || !context.mounted) {
                              return;
                            }
                            final nextTimeline = ref.read(
                              chatTimelineControllerProvider,
                            );
                            if (beforeCount == nextTimeline.messages.length &&
                                nextTimeline.viewportState?.hasMoreBefore ==
                                    false) {
                              _showAttachmentError(context, notice);
                            }
                          },
                          onRetryMessage: (message) async {
                            if (message.type == MessageType.text) {
                              final retried = await ref
                                  .read(chatControllerProvider.notifier)
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
                                .read(chatMediaControllerProvider.notifier)
                                .retryFailedMessage(
                                  failedMessage: message,
                                  entryArgs: pageState.entryArgs,
                                  chatTitle: chatTitle,
                                );
                            if (!handled) {
                              final error = ref
                                  .read(chatMediaControllerProvider)
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
                          onReeditRecalledMessage: _handleReeditAfterRecall,
                          reeditNowTs: _reeditNowTs,
                          showSenderNamesForIncoming: isGroupChat,
                          watermarkText: currentUserId.trim().isEmpty
                              ? '同事A 1234'
                              : currentUserId.trim(),
                          currentUserAvatarUrl: currentUserAvatarUrl,
                          outgoingFooterLabelBuilder: isGroupChat
                              ? (message) =>
                                    _buildReadReceiptEntryText(message, strings)
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
                  else if (pageState.isReadOnly || groupRestrictionHint != null)
                    ChatReadonlyFooter(
                      hintText: pageState.isReadOnly
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

    return Scaffold(
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
      body: Stack(children: [body, if (_isRecording) _buildRecordingOverlay()]),
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
        .read(chatTimelineControllerProvider.notifier)
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
    ref.invalidate(groupSettingsControllerProvider(args));
    ref.invalidate(groupMembersFutureProvider(notifyGroupId));

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
        .read(chatTimelineControllerProvider.notifier)
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
    }

    unawaited(
      ref.read(conversationListControllerProvider.notifier).syncIncrementally(),
    );
    unawaited(groupSettingsNotifier.load());
    unawaited(groupMembersNotifier.load());
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
  }) {
    if (widget.args.conversationType != ConversationType.group ||
        groupSettingsState == null) {
      return null;
    }
    final strings = ref.read(appStringsProvider);
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
      _typingSendTimer?.cancel();
      return;
    }
    if (value.trim().isEmpty) {
      _typingSendTimer?.cancel();
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
    _typingSendTimer?.cancel();
    _typingSendTimer = Timer(_typingDebounce, () {
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
    });
  }

  void _startTypingCleanupTimer() {
    _typingCleanupTimer?.cancel();
    _typingCleanupTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    });
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
      extra: <String, String>{
        'userId': resolvedUserId,
        'name': displayName.trim(),
        'departmentName': '',
      },
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
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE8ECF3), width: 0.5),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF202531),
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 0,
      centerTitle: true,
      title: Text(
        strings.chatSelectedCount(_selectedMessageIds.length),
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF202531),
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
        chatTimelineControllerProvider.notifier,
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
    if (message.type == MessageType.voice) {
      unawaited(_toggleVoicePlayback(message));
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
        extra: <String, String>{
          'userId': userId,
          'name': message.extra.contactDisplayName ?? message.senderName,
          'departmentName': message.extra.contactDepartmentName ?? '',
        },
      );
      return;
    }
    if (message.type == MessageType.location) {
      unawaited(_openLocationMessage(context, message));
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
          extra: <String, String>{
            'userId': userId,
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
      } catch (_) {}
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

  Future<void> _toggleVoicePlayback(Message message) async {
    final strings = ref.read(appStringsProvider);
    final playingId = _activePlayingVoiceMessageId;
    final pausedId = _activePausedVoiceMessageId;
    final messageKey = message.clientMessageId ?? message.messageId;
    final playback = ref.read(audioPlaybackServiceProvider);
    if (playingId != null && messageKey == playingId) {
      await playback.pause();
      if (!mounted) {
        return;
      }
      setState(() {
        _activePausedVoiceMessageId = messageKey;
        _activePlayingVoiceMessageId = null;
      });
      return;
    }
    if (pausedId != null && messageKey == pausedId) {
      await playback.play();
      if (!mounted) {
        return;
      }
      setState(() {
        _activePlayingVoiceMessageId = messageKey;
        _activePausedVoiceMessageId = null;
      });
      return;
    }

    final fileId = message.extra.fileId?.trim() ?? '';
    if (fileId.isEmpty) {
      if (mounted) {
        _showAttachmentError(context, strings.chatVoiceFileUnavailable);
      }
      return;
    }
    try {
      final url = await ref
          .read(fileRepositoryProvider)
          .getPresignedGetUrl(fileId: fileId);
      await _bindVoicePlayback(messageKey);
      await playback.stop();
      await playback.setUrl(url.toString());
      await playback.seek(Duration.zero);
      await playback.play();
      _markVoicePlayedOnOpen(message);
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showAttachmentError(context, strings.chatVoicePlayUrlFailed);
    }
  }

  Future<void> _bindVoicePlayback(String messageKey) async {
    final playback = ref.read(audioPlaybackServiceProvider);
    await _voicePositionSubscription?.cancel();
    await _voiceDurationSubscription?.cancel();
    await _voicePlayerStateSubscription?.cancel();
    _voicePositionSubscription = playback.positionStream.listen((position) {
      if (!mounted) {
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
      if (!mounted || duration == null) {
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
      if (!mounted) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          if (_activePlayingVoiceMessageId == messageKey ||
              _activePausedVoiceMessageId == messageKey) {
            _activePlayingVoiceMessageId = null;
            _activePausedVoiceMessageId = null;
            _activeVoicePlaybackProgressMs = 0;
          }
        });
        return;
      }
      if (!state.playing &&
          state.processingState != ProcessingState.completed &&
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
        .read(chatTimelineControllerProvider.notifier)
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
    _voicePlayedSyncTimer ??= Timer(_voicePlayedSyncDebounce, () {
      _voicePlayedSyncTimer = null;
      unawaited(_flushVoicePlayedSyncQueue());
    });
  }

  Future<void> _flushVoicePlayedSyncQueue({bool force = false}) async {
    if (force && _voicePlayedSyncTimer != null) {
      _voicePlayedSyncTimer!.cancel();
      _voicePlayedSyncTimer = null;
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
    _voicePlayedSyncTimer ??= Timer(_voicePlayedSyncDebounce, () {
      _voicePlayedSyncTimer = null;
      unawaited(_flushVoicePlayedSyncQueue());
    });
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
    _voicePlayedCompensateTimer?.cancel();
    _voicePlayedCompensateTimer = Timer.periodic(
      _voicePlayedCompensateInterval,
      (_) => unawaited(_restoreVoicePlayedCompensationOnce()),
    );
  }

  Future<void> _restoreVoicePlayedCompensationOnce() async {
    final chatId = widget.args.chatId.trim();
    if (chatId.isEmpty || chatId == '0' || _voicePlayedCompensateInFlight) {
      return;
    }
    final pendingVoiceIds = await _collectUnplayedVoiceMessageIds(
      _voicePlayedCompensateMaxIds,
    );
    if (pendingVoiceIds.isEmpty) {
      return;
    }
    _voicePlayedCompensateInFlight = true;
    try {
      final repository = ref.read(messageRepositoryProvider);
      var offset = 0;
      while (offset < pendingVoiceIds.length) {
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
          _voicePlayedPendingSync.remove(playedId);
          await _persistVoicePlayed(playedId);
          ref
              .read(chatTimelineControllerProvider.notifier)
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
    final result = <String>[];
    final seen = <String>{};
    final messages = ref.read(chatTimelineControllerProvider).messages;
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
          repository: ref.read(messageRepositoryProvider),
          onSummaryLoaded: (summary) {
            _storeReadReceiptSummary(messageId, summary);
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

  _ReadReceiptSummaryCacheEntry? _getCachedReadReceiptSummary(
    String messageId,
  ) {
    return _readReceiptSummaryCache[messageId];
  }

  void _storeReadReceiptSummary(String messageId, ReadReceiptSummary? summary) {
    if (messageId.isEmpty) {
      return;
    }
    _readReceiptSummaryCache[messageId] = _ReadReceiptSummaryCacheEntry(
      summary: summary,
      fetchedAt: DateTime.now(),
    );
    _pruneReadReceiptSummaryCache();
    if (mounted) {
      setState(() {});
    }
  }

  void _pruneReadReceiptSummaryCache() {
    if (_readReceiptSummaryCache.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final kept =
        _readReceiptSummaryCache.entries
            .where(
              (entry) =>
                  now.difference(entry.value.fetchedAt) <=
                  _readReceiptSummaryTtl,
            )
            .toList(growable: false)
          ..sort(
            (left, right) =>
                right.value.fetchedAt.compareTo(left.value.fetchedAt),
          );
    _readReceiptSummaryCache
      ..clear()
      ..addEntries(kept.take(_readReceiptSummaryCacheMax));
  }

  bool _shouldFetchReadReceiptSummary(String messageId) {
    final cached = _getCachedReadReceiptSummary(messageId);
    if (cached == null) {
      return true;
    }
    return DateTime.now().difference(cached.fetchedAt) > _readReceiptSummaryTtl;
  }

  bool _isReadReceiptSummaryInFlight(String messageId) {
    return _readReceiptSummaryInFlight[messageId] == true;
  }

  int _getReadReceiptSummaryRetryCount(String messageId) {
    return _readReceiptSummaryRetryCount[messageId] ?? 0;
  }

  void _setReadReceiptSummaryRetryCount(String messageId, int count) {
    if (messageId.isEmpty) {
      return;
    }
    if (count > 0) {
      _readReceiptSummaryRetryCount[messageId] = count;
    } else {
      _readReceiptSummaryRetryCount.remove(messageId);
    }
  }

  void _scheduleReadReceiptSummaryRetry(String messageId, int attempt) {
    if (messageId.isEmpty || attempt > 3) {
      return;
    }
    final delay = switch (attempt) {
      1 => const Duration(milliseconds: 600),
      2 => const Duration(milliseconds: 1500),
      _ => const Duration(milliseconds: 3000),
    };
    Future<void>.delayed(delay, () {
      unawaited(_ensureReadReceiptSummaryFetched(messageId));
    });
  }

  Future<void> _ensureReadReceiptSummaryFetched(String messageId) async {
    if (messageId.isEmpty ||
        !_shouldFetchReadReceiptSummary(messageId) ||
        _isReadReceiptSummaryInFlight(messageId)) {
      return;
    }
    _readReceiptSummaryInFlight[messageId] = true;
    try {
      final summary = await ref
          .read(messageRepositoryProvider)
          .getReadReceiptSummary(messageId: messageId);
      if (summary != null) {
        _setReadReceiptSummaryRetryCount(messageId, 0);
        _storeReadReceiptSummary(messageId, summary);
      } else {
        final nextAttempt = _getReadReceiptSummaryRetryCount(messageId) + 1;
        _setReadReceiptSummaryRetryCount(messageId, nextAttempt);
        if (nextAttempt <= 3) {
          _scheduleReadReceiptSummaryRetry(messageId, nextAttempt);
        } else {
          _storeReadReceiptSummary(messageId, null);
        }
      }
    } catch (_) {
      // Keep silent to match old page prefetch behavior.
    } finally {
      _readReceiptSummaryInFlight.remove(messageId);
    }
  }

  void _scheduleReadReceiptPrefetch(List<Message> messages) {
    final candidates = messages
        .where(_isReadReceiptMessageConfirmed)
        .map(_resolveReadReceiptTargetMessageId)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final latest = candidates.length > 20
        ? candidates.sublist(candidates.length - 20)
        : candidates;
    final nextKey = latest.join(',');
    if (nextKey.isEmpty || nextKey == _lastReadReceiptPrefetchKey) {
      return;
    }
    _lastReadReceiptPrefetchKey = nextKey;
    Future<void>.microtask(() async {
      for (final messageId in latest) {
        await _ensureReadReceiptSummaryFetched(messageId);
      }
    });
  }

  String _buildReadReceiptEntryText(Message message, AppLocalizations strings) {
    if (!_isReadReceiptMessageConfirmed(message)) {
      return switch (message.status) {
        MessageStatus.sending => strings.messageSending,
        MessageStatus.sent => strings.messageSent,
        MessageStatus.delivered => strings.messageDelivered,
        MessageStatus.read => strings.messageRead,
        MessageStatus.recalled => strings.chatPreviewRecalled,
        MessageStatus.failed => strings.messageFailed,
      };
    }
    final messageId = _resolveReadReceiptTargetMessageId(message);
    if (messageId.isEmpty) {
      return strings.chatReadReceiptPending;
    }
    final cached = _getCachedReadReceiptSummary(messageId);
    final summary = cached?.summary;
    if (summary != null) {
      final unread = summary.unreadCount;
      if (unread > 0) {
        return strings.chatReadReceiptUnread(unread);
      }
      return strings.chatReadReceiptReadLabel;
    }
    unawaited(_ensureReadReceiptSummaryFetched(messageId));
    return strings.chatReadReceiptPending;
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
    required ChatMorePanelController morePanelController,
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
    final result = await morePanelController.handleAction(
      action: action,
      entryArgs: pageState.entryArgs,
      chatTitle: chatTitle,
    );
    final error = ref.read(chatMediaControllerProvider).error;
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
    final actionController = ref.read(chatMessageActionControllerProvider);
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
    final directUrl = RegExp(r'^https?:\/\/\S+$', caseSensitive: false);
    final wwwUrl = RegExp(r'^www\.\S+$', caseSensitive: false);
    return directUrl.hasMatch(value) || wwwUrl.hasMatch(value);
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
    } catch (_) {}
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
          .read(chatTimelineControllerProvider.notifier)
          .applyRecalledMessage(recalled);
      final pageState = ref.read(chatControllerProvider);
      ref
          .read(conversationListControllerProvider.notifier)
          .upsertLocalMessage(
            chatId: widget.args.chatId,
            title: pageState.chatTitle ?? pageState.entryArgs.title ?? '',
            conversationType: pageState.entryArgs.conversationType,
            messageId: recalled.messageId,
            messageSequence: recalled.sequence,
            preview: ref
                .read(messagePreviewFormatterProvider)
                .formatConversationPreview(
                  type: recalled.type,
                  content: recalled.content,
                  customType: recalled.extra.customType,
                  fileName: recalled.extra.fileName,
                  systemEventKey: recalled.extra.systemEventKey,
                  conversationType: pageState.entryArgs.conversationType,
                  isSelf: recalled.isOutgoing,
                  senderName: recalled.senderName,
                ),
            messageType: recalled.type,
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
          .read(chatMessageActionControllerProvider)
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
    final timeline = ref.read(chatTimelineControllerProvider);
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
    ref
        .read(chatTimelineControllerProvider.notifier)
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
    final pageState = ref.read(chatControllerProvider);
    if (pageState.isReadOnly) {
      _showAttachmentError(context, _resolveReadOnlyHint());
      return false;
    }
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
        .read(chatControllerProvider)
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
    return ref
        .read(messagePreviewFormatterProvider)
        .format(
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
    _highlightClearTimer?.cancel();
    _highlightClearTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_activeHighlightedMessageId == highlightedMessageId) {
          _activeHighlightedMessageId = null;
        }
      });
    });
  }

  void _handleInitialViewport() {
    final timelineState = ref.read(chatTimelineControllerProvider);
    final viewport = timelineState.viewportState;
    final entryMode = widget.args.entryMode;
    final isAnchorEntry =
        entryMode == ChatEntryMode.anchor || entryMode == ChatEntryMode.restore;
    if (!isAnchorEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scrollTimelineToBottom();
      });
      return;
    }
    if (viewport?.anchorFound == false) {
      _showAttachmentError(
        context,
        ref.read(appStringsProvider).chatAnchorFallback,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scrollTimelineToBottom();
      });
      return;
    }
    final targetId = widget.args.highlightedMessageId?.trim().isNotEmpty == true
        ? widget.args.highlightedMessageId!.trim()
        : widget.args.anchorMessageId?.trim() ?? '';
    if (targetId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scrollTimelineToBottom();
      });
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) {
        return;
      }
      await _scrollToMessageKey(targetId);
    });
  }

  Future<void> _openQuotedMessage(String quotedMessageId) async {
    final targetId = quotedMessageId.trim();
    if (targetId.isEmpty) {
      return;
    }
    var messages = ref.read(chatTimelineControllerProvider).messages;
    var matched = messages.any((item) => item.messageId == targetId);
    if (!matched) {
      final pageState = ref.read(chatControllerProvider);
      await ref
          .read(chatTimelineControllerProvider.notifier)
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
      messages = ref.read(chatTimelineControllerProvider).messages;
      matched = messages.any((item) => item.messageId == targetId);
    }
    if (!matched) {
      final viewportState = ref
          .read(chatTimelineControllerProvider)
          .viewportState;
      if (viewportState?.anchorFound == false) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatAnchorFallback,
        );
        _scrollTimelineToBottom();
        return;
      }
      _showAttachmentError(
        context,
        ref.read(appStringsProvider).chatQuoteMessageMissing,
      );
      return;
    }
    setState(() {
      _activeHighlightedMessageId = targetId;
    });
    await _scrollToMessageKey(targetId);
    _scheduleHighlightClear();
  }

  Future<void> _scrollToMessageKey(String messageId) async {
    final key = _resolveMessageItemKey(messageId);
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.4,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    final messages = ref.read(chatTimelineControllerProvider).messages;
    final index = messages.indexWhere(
      (item) =>
          item.messageId == messageId || item.clientMessageId == messageId,
    );
    if (index < 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final retryKey = _resolveMessageItemKey(messageId);
      final context = retryKey?.currentContext;
      if (!mounted || context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignment: 0.4,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  GlobalKey? _resolveMessageItemKey(String messageId) {
    final direct = _messageItemKeys[messageId];
    if (direct != null) {
      return direct;
    }
    final messages = ref.read(chatTimelineControllerProvider).messages;
    final matched = messages.where(
      (item) =>
          item.messageId == messageId || item.clientMessageId == messageId,
    );
    for (final item in matched) {
      final byMessageId = _messageItemKeys[item.messageId];
      if (byMessageId != null) {
        return byMessageId;
      }
      final clientId = item.clientMessageId?.trim() ?? '';
      if (clientId.isNotEmpty) {
        final byClientId = _messageItemKeys[clientId];
        if (byClientId != null) {
          return byClientId;
        }
      }
    }
    return null;
  }

  GlobalKey _ensureMessageItemKey(String messageId) {
    final normalized = messageId.trim();
    return _messageItemKeys.putIfAbsent(normalized, GlobalKey.new);
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
    _reeditTicker?.cancel();
    _reeditTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _reeditNowTs = DateTime.now().millisecondsSinceEpoch;
      });
    });
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
    final messages = ref.read(chatTimelineControllerProvider).messages;
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

  void _scrollTimelineToBottom() {
    if (!_timelineScrollController.hasClients) {
      return;
    }
    final position = _timelineScrollController.position;
    if ((position.maxScrollExtent - position.pixels).abs() <= 1) {
      return;
    }
    _timelineScrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
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
    final timelineState = ref.read(chatTimelineControllerProvider);
    if (timelineState.status == ChatTimelineStatus.loading ||
        timelineState.messages.isEmpty ||
        timelineState.viewportState?.hasMoreBefore == false) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHistoryLoadTriggerAt < 500) {
      return;
    }
    final pageState = ref.read(chatControllerProvider);
    _lastHistoryLoadTriggerAt = now;
    unawaited(
      ref
          .read(chatTimelineControllerProvider.notifier)
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
                .read(chatControllerProvider.notifier)
                .sendSticker(payload);
            if (!sent && context.mounted) {
              final strings = ref.read(appStringsProvider);
              final error = ref.read(chatControllerProvider).error;
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
    final service = ref.read(audioRecordingServiceProvider);
    final hasPermission = await service.ensurePermission();
    if (!hasPermission) {
      if (mounted) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatRecordPermissionDenied,
        );
      }
      return;
    }
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    try {
      await service.start(path: path);
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
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
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
      });
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
    if (!_isRecording) {
      return;
    }
    final service = ref.read(audioRecordingServiceProvider);
    final shouldCancel = _isCancelReady;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordAmplitudeSubscription?.cancel();
    _recordAmplitudeSubscription = null;
    try {
      final path = await service.stop();
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
      if (path == null || path.trim().isEmpty) {
        _showAttachmentError(
          context,
          ref.read(appStringsProvider).chatRecordFileCreateFailed,
        );
        return;
      }
      await _uploadVoiceMessage(path.trim(), durationMs);
    } catch (error) {
      _resetVoiceRecordingUi();
      if (mounted) {
        _showAttachmentError(context, error.toString());
      }
    }
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_isRecording) {
      return;
    }
    _recordingTimer?.cancel();
    _recordingTimer = null;
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

  Future<void> _uploadVoiceMessage(String localPath, int durationMs) async {
    await _performVoiceUpload(localPath: localPath, durationMs: durationMs);
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
    );
  }

  Future<bool> _performVoiceUpload({
    required String localPath,
    required int durationMs,
    Message? retryMessage,
  }) async {
    final durationSeconds = (durationMs / 1000).round().clamp(1, 60);
    final localMessage =
        retryMessage ??
        ref
            .read(optimisticMessageFactoryProvider)
            .createVoice(
              chatId: widget.args.chatId,
              localPath: localPath,
              duration: durationSeconds,
              durationMs: durationMs,
              fileSize: 0,
              format: 'm4a',
            );
    final retryKey = localMessage.clientMessageId ?? localMessage.messageId;
    if (retryMessage == null) {
      ref
          .read(chatTimelineControllerProvider.notifier)
          .appendSingleMessage(localMessage);
    } else {
      ref
          .read(chatTimelineControllerProvider.notifier)
          .markSendingByClientMessageId(clientMessageId: retryKey);
    }
    ref
        .read(conversationListControllerProvider.notifier)
        .upsertLocalMessage(
          chatId: localMessage.chatId,
          title: ref.read(chatControllerProvider).chatTitle ?? '',
          conversationType: widget.args.conversationType,
          messageId: retryKey,
          messageSequence: localMessage.sequence,
          preview: ref
              .read(messagePreviewFormatterProvider)
              .formatConversationPreview(
                type: localMessage.type,
                content: localMessage.content,
                customType: localMessage.extra.customType,
                fileName: localMessage.extra.fileName,
                systemEventKey: localMessage.extra.systemEventKey,
                conversationType: widget.args.conversationType,
                isSelf: localMessage.isOutgoing,
                senderName: localMessage.senderName,
              ),
          messageType: localMessage.type,
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
            displayName: 'voice.m4a',
            mimeType: 'audio/mp4',
          );
      await ref
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
            format: 'm4a',
            md5: upload.file.md5 ?? '',
            clientMessageId: retryKey,
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
          .read(chatTimelineControllerProvider.notifier)
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
    final picked = await context.push<ContactCardSharePayload>(
      RoutePaths.chatSelectContactCard,
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
          .read(chatControllerProvider.notifier)
          .sendContactCard(payload);
      if (!sent) {
        if (!context.mounted) {
          return;
        }
        final error = ref.read(chatControllerProvider).error;
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
      _showAttachmentSuccess(context, strings.chatContactCardSendSuccess);
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
          .read(chatControllerProvider.notifier)
          .sendLocation(payload);
      if (!sent) {
        if (!context.mounted) {
          return;
        }
        final error = ref.read(chatControllerProvider).error;
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
      _showAttachmentSuccess(context, strings.chatLocationSendSuccess);
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

  Future<void> _openLocationMessage(
    BuildContext context,
    Message message,
  ) async {
    final strings = ref.read(appStringsProvider);
    final latitude = message.extra.locationLatitude;
    final longitude = message.extra.locationLongitude;
    if (latitude == null || longitude == null) {
      _showAttachmentError(context, strings.chatLocationMissing);
      return;
    }
    final locationName = message.extra.locationName?.trim() ?? '';
    final address = message.extra.locationAddress?.trim() ?? '';
    final confirmed = await _showLegacyConfirmDialog(
      context,
      title: locationName.isNotEmpty
          ? locationName
          : strings.chatLocationDefaultTitle,
      content: address.isNotEmpty
          ? address
          : strings.chatLocationCoordinateFallback(
              latitude.toStringAsFixed(6),
              longitude.toStringAsFixed(6),
            ),
      confirmText: strings.chatLocationNavigateAction,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final opened = await ref
        .read(chatLocationOpenerServiceProvider)
        .open(
          latitude: latitude,
          longitude: longitude,
          name: locationName,
          address: address,
        );
    if (opened || !context.mounted) {
      return;
    }
    final shouldCopy = await _showLegacyConfirmDialog(
      context,
      title: strings.chatLocationOpenFailed,
      content: strings.chatLocationOpenUnsupported,
      confirmText: strings.chatLocationCopyAction,
    );
    if (shouldCopy != true || !context.mounted) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(
        text: _buildLocationClipboardPayload(
          locationName: locationName,
          address: address,
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    _showAttachmentError(context, strings.chatLocationCopied);
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
    required this.repository,
    required this.onSummaryLoaded,
    required this.onShowNotice,
  });

  final String messageId;
  final String chatTitle;
  final String messagePreview;
  final bool isVoiceMessage;
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
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final summary = await widget.repository.getReadReceiptSummary(
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202531),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: const Color(0xFFE8ECF3)),
              if (widget.isVoiceMessage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.chatReadReceiptVoiceHint,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 16 / 11,
                        color: Color(0xFF98A1B2),
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
                      color: const Color(0xFFE8ECF3),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF98A1B2),
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
                            style: const TextStyle(color: Color(0xFF98A1B2)),
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
                          style: const TextStyle(color: Color(0xFF98A1B2)),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF98A1B2),
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
                                            color: const Color(0xFFEEF3FF),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _initials(item.userName),
                                              style: const TextStyle(
                                                color: Color(0xFF246BFD),
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
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF202531),
                                      ),
                                    ),
                                    if (_selectedTab == 'read' &&
                                        _buildReadTime(item).isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _buildReadTime(item),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF98A1B2),
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

  String _initials(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return '?';
    }
    return text.substring(0, 1).toUpperCase();
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

class _ReadReceiptSummaryCacheEntry {
  const _ReadReceiptSummaryCacheEntry({
    required this.summary,
    required this.fetchedAt,
  });

  final ReadReceiptSummary? summary;
  final DateTime fetchedAt;
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202531),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF246BFD) : const Color(0xFF98A1B2),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8ECF3), width: 1)),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF98A1B2),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF98A1B2),
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
                                icon: const AppIcon(
                                  AppIconKind.add,
                                  size: 18,
                                  color: Color(0xFF202531),
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
                                      style: const TextStyle(
                                        color: Color(0xFF98A1B2),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (allStickers.isEmpty) {
                                return Center(
                                  child: Text(
                                    strings.chatMediaEmpty,
                                    style: const TextStyle(
                                      color: Color(0xFF98A1B2),
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
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons
                                                        .emoji_emotions_outlined,
                                                    color: Color(0xFF98A1B2),
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
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF202531),
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
            color: active ? const Color(0xFF2F6BFF) : const Color(0xFF98A1B2),
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
