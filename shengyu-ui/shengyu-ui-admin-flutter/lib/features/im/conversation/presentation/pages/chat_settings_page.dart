import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class ChatSettingsPage extends ConsumerStatefulWidget {
  const ChatSettingsPage({super.key, required this.args});

  final ChatEntryArgs args;

  @override
  ConsumerState<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends ConsumerState<ChatSettingsPage> {
  bool? _pinnedOverride;
  bool? _mutedOverride;
  bool _submittingPinned = false;
  bool _submittingMuted = false;
  bool _clearingHistory = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final state = ref.read(conversationListControllerProvider);
      final exists = state.conversations.any(
        (item) => item.chatId == widget.args.chatId,
      );
      if (exists) {
        return;
      }
      await ref.read(conversationListControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final conversationList = ref.watch(conversationListControllerProvider);
    final conversation = conversationList.conversations
        .where((item) => item.chatId == widget.args.chatId)
        .firstOrNull;
    final targetId = _resolveTargetId(conversation);
    final profileAsync = targetId == null || targetId.isEmpty
        ? null
        : ref.watch(contactProfileProvider(targetId));
    final profile = profileAsync?.valueOrNull;
    final displayName = _resolveDisplayName(
      strings,
      conversation: conversation,
      profileName: profile?.name,
    );
    final displayDept = profile?.departmentName.isNotEmpty == true
        ? profile!.departmentName
        : strings.chatSettingsNoRoleInfo;
    final isPinned = _pinnedOverride ?? conversation?.isPinned ?? false;
    final isMuted = _mutedOverride ?? conversation?.isMuted ?? false;
    final avatarUrl = (profile?.avatarUrl.trim().isNotEmpty == true)
        ? profile!.avatarUrl
        : conversation?.targetAvatar;

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
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          label: Text(
            strings.backAction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(strings.chatSettingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                ContactsInitialAvatar(
                  name: displayName,
                  color: const Color(0xFFE97CAB),
                  avatarUrl: avatarUrl,
                  size: 64,
                  borderRadius: 12,
                  fontSize: 24,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayDept,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8F96A3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ContactsSectionCard(
            children: [
              _SwitchTile(
                title: strings.chatSettingsTop,
                value: isPinned,
                busy: _submittingPinned,
                onChanged: _updatePinned,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SwitchTile(
                title: strings.chatSettingsNotify,
                value: isMuted,
                busy: _submittingMuted,
                onChanged: _updateMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ContactsSectionCard(
            children: [
              _ActionTile(
                title: strings.chatSettingsChatFilesSingle,
                onTap: () {
                  context.pushNamed(RouteNames.chatMedia, extra: widget.args);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ActionTile(
                title: strings.chatHistoryTitle,
                onTap: () {
                  context.pushNamed(RouteNames.chatHistory, extra: widget.args);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DangerTile(
                title: strings.chatSettingsClearHistory,
                busy: _clearingHistory,
                onTap: _clearHistory,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              strings.chatSettingsSubordinateTip,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF98A1B2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveDisplayName(
    AppLocalizations strings, {
    required Conversation? conversation,
    String? profileName,
  }) {
    final resolvedProfileName = profileName?.trim() ?? '';
    if (resolvedProfileName.isNotEmpty) {
      return resolvedProfileName;
    }
    final conversationTitle = conversation?.title.trim() ?? '';
    if (conversationTitle.isNotEmpty) {
      return conversationTitle;
    }
    final routeTitle = widget.args.title?.trim() ?? '';
    if (routeTitle.isNotEmpty) {
      return routeTitle;
    }
    final chatId = widget.args.chatId.trim();
    if (chatId.isNotEmpty) {
      return chatId;
    }
    return strings.profileUnknownUser;
  }

  String? _resolveTargetId(Conversation? conversation) {
    final conversationTargetId = conversation?.targetId?.trim() ?? '';
    if (conversationTargetId.isNotEmpty) {
      return conversationTargetId;
    }
    final routeTargetId = widget.args.targetId?.trim() ?? '';
    if (routeTargetId.isNotEmpty) {
      return routeTargetId;
    }
    return null;
  }

  Future<void> _updatePinned(bool value) async {
    final strings = AppLocalizations.of(context);
    if (_submittingPinned) {
      return;
    }
    setState(() {
      _submittingPinned = true;
      _pinnedOverride = value;
    });
    try {
      await ref
          .read(conversationRepositoryProvider)
          .pinConversation(chatId: widget.args.chatId, pinned: value);
      ref
          .read(conversationListControllerProvider.notifier)
          .patchConversationSettings(
            chatId: widget.args.chatId,
            isPinned: value,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? strings.chatSettingsPinned : strings.chatSettingsUnpinned,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pinnedOverride = !value;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submittingPinned = false;
        });
      }
    }
  }

  Future<void> _updateMuted(bool value) async {
    final strings = AppLocalizations.of(context);
    if (_submittingMuted) {
      return;
    }
    setState(() {
      _submittingMuted = true;
      _mutedOverride = value;
    });
    try {
      await ref
          .read(conversationRepositoryProvider)
          .toggleNoDisturb(chatId: widget.args.chatId, noDisturb: value);
      ref
          .read(conversationListControllerProvider.notifier)
          .patchConversationSettings(
            chatId: widget.args.chatId,
            isMuted: value,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? strings.chatSettingsNotifyDisabled
                : strings.chatSettingsNotifyEnabled,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mutedOverride = !value;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submittingMuted = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    if (_clearingHistory) {
      return;
    }
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.chatSettingsClearHistory),
          content: Text(strings.chatSettingsClearHistoryConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
              ),
              child: Text(strings.confirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _clearingHistory = true;
    });
    try {
      await ref
          .read(messageRepositoryProvider)
          .clearConversationHistory(chatId: widget.args.chatId);
      final currentChatId = ref.read(chatControllerProvider).entryArgs.chatId;
      if (currentChatId == widget.args.chatId) {
        ref.read(chatTimelineControllerProvider.notifier).clearAll();
      }
      ref
          .read(conversationListControllerProvider.notifier)
          .clearConversationPreview(
            chatId: widget.args.chatId,
            updatedAt: DateTime.now(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.chatSettingsCleared)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatSettingsClearHistoryFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _clearingHistory = false;
        });
      }
    }
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.busy = false,
  });

  final String title;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF202531),
        ),
      ),
      trailing: Switch(value: value, onChanged: busy ? null : onChanged),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.title,
    required this.onTap,
    this.busy = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: busy ? null : onTap,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: busy ? const Color(0xFFB8C0CC) : const Color(0xFFE54D4F),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF202531),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFB8C0CC),
      ),
    );
  }
}
