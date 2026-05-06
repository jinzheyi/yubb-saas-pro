import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/states/conversation_list_state.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/providers/favorite_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ForwardTargetPage extends ConsumerStatefulWidget {
  const ForwardTargetPage({super.key, required this.args});

  final ForwardTargetRouteArgs args;

  @override
  ConsumerState<ForwardTargetPage> createState() => _ForwardTargetPageState();
}

class _ForwardTargetPageState extends ConsumerState<ForwardTargetPage> {
  static const int _maxForwardMessageCount = 50;

  late final TextEditingController _keywordController;
  String _keyword = '';
  var _forwardType = 1;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController();
    _forwardType = widget.args.initialForwardType == 2 ? 2 : 1;
    Future.microtask(() async {
      if (widget.args.messageIds.length > _maxForwardMessageCount) {
        if (!mounted) {
          return;
        }
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.chatMaxSelectReached(_maxForwardMessageCount),
            ),
          ),
        );
        Navigator.of(context).maybePop();
        return;
      }
      final state = ref.read(conversationListControllerProvider);
      if (state.conversations.isNotEmpty) {
        return;
      }
      await ref.read(conversationListControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final conversationState = ref.watch(conversationListControllerProvider);
    final conversations = conversationState.conversations;
    final filtered = _filteredConversations(conversations);
    final isFavoriteMode = widget.args.isFavoriteMode;
    final messageCount = isFavoriteMode ? 1 : widget.args.messageIds.length;
    final showForwardType = !isFavoriteMode && messageCount > 1;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leadingWidth: 80,
            leading: TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF202531),
                padding: const EdgeInsets.only(left: 8),
              ),
              icon: const AppIcon(
                AppIconKind.chevronLeft,
                size: 20,
                color: Color(0xFF202531),
              ),
              label: Text(
                strings.backAction,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            titleSpacing: 0,
            centerTitle: true,
            title: Text(
              strings.chatForwardTargetTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF202531),
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const AppIcon(
                        AppIconKind.search,
                        size: 16,
                        color: Color(0xFF98A1B2),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _keywordController,
                          onChanged: (value) {
                            setState(() {
                              _keyword = value.trim();
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: strings.searchHint,
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF98A1B2),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF202531),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (messageCount > 0)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(
                    '${isFavoriteMode ? strings.chatForwardTargetSummarySend : strings.chatForwardTargetSummaryForward} '
                    '${strings.chatForwardTargetMessageCount(messageCount)} '
                    '${strings.chatForwardTargetSummaryTo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
              if (showForwardType)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ForwardTypeButton(
                          active: _forwardType == 1,
                          label: strings.chatForwardTargetSingleForward,
                          onTap: _submitting
                              ? null
                              : () => setState(() {
                                  _forwardType = 1;
                                }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ForwardTypeButton(
                          active: _forwardType == 2,
                          label: strings.chatForwardTargetCombineForward,
                          onTap: _submitting
                              ? null
                              : () => setState(() {
                                  _forwardType = 2;
                                }),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child:
                    conversationState.status ==
                            ConversationListStatus.loading &&
                        conversations.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          strings.chatForwardEmptyTarget,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ForwardConversationTile(
                              conversation: item,
                              onTap: _submitting
                                  ? null
                                  : () => _handleSelectConversation(
                                      context,
                                      item,
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (_submitting) ...[
          const ModalBarrier(dismissible: false, color: Color(0x26000000)),
          Center(
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xCC111111),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.chatForwardTargetSending,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Conversation> _filteredConversations(List<Conversation> items) {
    final keyword = _keyword.trim();
    if (keyword.isEmpty) {
      return items;
    }
    return items
        .where((item) {
          final title = _displayConversationTitle(item);
          return title.contains(keyword);
        })
        .toList(growable: false);
  }

  Future<void> _handleSelectConversation(
    BuildContext context,
    Conversation conversation,
  ) async {
    final strings = AppLocalizations.of(context);
    final isFavoriteMode = widget.args.isFavoriteMode;
    final favoriteId = widget.args.favoriteId?.trim() ?? '';
    final rawIds = widget.args.messageIds;
    final messageIds = rawIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    if (!isFavoriteMode && messageIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.chatChooseForwardMessage)));
      return;
    }
    if (!isFavoriteMode && messageIds.length > _maxForwardMessageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.chatMaxSelectReached(_maxForwardMessageCount)),
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      if (isFavoriteMode) {
        await ref
            .read(favoriteRepositoryProvider)
            .resendFavorite(
              favoriteId: favoriteId,
              targetChatId: conversation.chatId,
            );
        await ref
            .read(conversationListControllerProvider.notifier)
            .syncIncrementally();
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.chatForwardTargetSent)),
        );
        final entryArgs = ChatEntryArgs.latest(
          chatId: conversation.chatId,
          conversationType: conversation.conversationType,
          targetId: conversation.targetId,
          title: _displayConversationTitle(conversation),
        );
        context.pushReplacementNamed(RouteNames.chat, extra: entryArgs);
        return;
      }
      final expectedCount = _forwardType == 2 ? 1 : messageIds.length;
      final successCount = await ref
          .read(messageRepositoryProvider)
          .forwardMessages(
            targetChatId: conversation.chatId,
            messageIds: messageIds,
            forwardType: _forwardType,
          );
      await ref
          .read(conversationListControllerProvider.notifier)
          .syncIncrementally();
      if (!context.mounted) {
        return;
      }
      final resolvedSuccessCount = successCount ?? expectedCount;
      if (resolvedSuccessCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.chatForwardTargetForwardFailed)),
        );
        return;
      }
      final notice = resolvedSuccessCount < expectedCount
          ? strings.chatForwardTargetPartialSuccess(
              resolvedSuccessCount,
              expectedCount,
            )
          : strings.chatForwardTargetForwarded;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(notice)));
      final entryArgs = ChatEntryArgs.latest(
        chatId: conversation.chatId,
        conversationType: conversation.conversationType,
        targetId: conversation.targetId,
        title: _displayConversationTitle(conversation),
      );
      context.pushReplacementNamed(RouteNames.chat, extra: entryArgs);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatForwardTargetForwardFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

String _displayConversationTitle(Conversation conversation) {
  final title = conversation.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  final targetId = conversation.targetId?.trim() ?? '';
  if (targetId.isNotEmpty) {
    return targetId;
  }
  return conversation.chatId;
}

String _displayConversationPreview(Conversation conversation) {
  final preview = conversation.lastMessagePreview.trim().replaceAll(
    RegExp(r'\r?\n+'),
    ' ',
  );
  return preview.isEmpty ? '-' : preview;
}

class _ForwardTypeButton extends StatelessWidget {
  const _ForwardTypeButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: active ? const Color(0x243370FF) : const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? const Color(0xFF246BFD) : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }
}

class _ForwardConversationTile extends StatelessWidget {
  const _ForwardConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final Conversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = _displayConversationTitle(conversation);
    final preview = _displayConversationPreview(conversation);
    final isGroup = conversation.conversationType == ConversationType.group;
    final avatar = conversation.targetAvatar?.trim() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isGroup
                      ? const Color(0xFFFFB347)
                      : const Color(0xFF246BFD),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatar.isNotEmpty
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _ConversationAvatarFallback(
                            title: title,
                            isGroup: isGroup,
                          );
                        },
                      )
                    : _ConversationAvatarFallback(
                        title: title,
                        isGroup: isGroup,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
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
  }
}

class _ConversationAvatarFallback extends StatelessWidget {
  const _ConversationAvatarFallback({
    required this.title,
    required this.isGroup,
  });

  final String title;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      return const Center(
        child: AppIcon(AppIconKind.groupsOutline, size: 18, color: Colors.white),
      );
    }
    final trimmed = title.trim();
    final text = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
