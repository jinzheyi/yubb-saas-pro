import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_paths.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/initiate_group_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/controllers/group_settings_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class GroupSettingsPage extends ConsumerStatefulWidget {
  const GroupSettingsPage({super.key, required this.args});

  final GroupContextArgs args;

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  ProviderSubscription<GroupJoinRequestSignal?>? _joinRequestSignalSubscription;

  @override
  void initState() {
    super.initState();
    _joinRequestSignalSubscription = ref.listenManual<GroupJoinRequestSignal?>(
      groupJoinRequestSignalProvider,
      (previous, next) {
        if (next == null || next.groupId != widget.args.groupId) {
          return;
        }
        ref
            .read(groupSettingsControllerProvider(widget.args).notifier)
            .load();
      },
    );
  }

  @override
  void dispose() {
    _joinRequestSignalSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(groupSettingsControllerProvider(widget.args));
    final controller = ref.read(
      groupSettingsControllerProvider(widget.args).notifier,
    );
    final title = state.groupName.trim().isNotEmpty
        ? state.groupName.trim()
        : (widget.args.groupName?.trim().isNotEmpty == true
              ? widget.args.groupName!.trim()
              : strings.groupSettingsTitle);
    final isOwner = state.currentUserRoleCode == 2;
    final canManageJoinRequests =
        state.currentUserRoleCode == 1 || state.currentUserRoleCode == 2;
    final canManageGroupMute = canManageJoinRequests;
    final canAddMembers = canManageJoinRequests || state.allowMemberInvite;
    final canRemoveMembers = canManageJoinRequests;

    if (state.status == GroupSettingsStatus.loading ||
        state.status == GroupSettingsStatus.initial) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == GroupSettingsStatus.failed) {
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
          title: Text(strings.groupSettingsTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error?.message ?? strings.unknownError,
                style: const TextStyle(color: Color(0xFF8F96A3)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.load,
                child: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    }

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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(strings.groupSettingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C08C),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.groups_2_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202531),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                strings.groupSettingsMembersCount(
                                  state.memberCount,
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8F96A3),
                                ),
                              ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                _TagChip(label: strings.groupSettingsOwner),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.groupMembersTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202531),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final changed = await context.pushNamed<bool>(
                          RouteNames.groupMembers,
                          extra: GroupContextArgs(
                            groupId: widget.args.groupId,
                            groupName: title,
                            mode: GroupMembersPageMode.view,
                          ),
                        );
                        if (changed == true) {
                          controller.load();
                        }
                      },
                      child: Text(strings.groupSettingsViewAllMembers),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 98,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final member in state.members)
                        Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: _MemberPreview(
                            onTap: () {
                              final displayName = member.name.trim().isNotEmpty
                                  ? member.name.trim()
                                  : strings.profileUnknownUser;
                              context.pushNamed(
                                RouteNames.contactsProfile,
                                extra: {
                                  'userId': member.id,
                                  'name': displayName,
                                  'departmentName':
                                      member.deptName?.trim() ?? '',
                                },
                              );
                            },
                            name: member.name.trim().isNotEmpty
                                ? member.name.trim()
                                : strings.profileUnknownUser,
                            color: Color(member.colorValue),
                            avatarUrl: member.avatarUrl,
                          ),
                        ),
                      if (canAddMembers)
                        Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: _IconMemberAction(
                            icon: Icons.add_rounded,
                            label: strings.groupSettingsAdd,
                            onTap: () async {
                              final changed = await context.pushNamed<bool>(
                                RouteNames.initiateGroup,
                                extra: InitiateGroupArgs.add(
                                  groupId: widget.args.groupId,
                                  groupName: title,
                                ),
                              );
                              if (changed == true) {
                                controller.load();
                              }
                            },
                          ),
                        ),
                      if (canRemoveMembers)
                        _IconMemberAction(
                          icon: Icons.delete_outline_rounded,
                          label: strings.groupSettingsRemove,
                          onTap: () async {
                            final changed = await context.pushNamed<bool>(
                              RouteNames.groupMembers,
                              extra: GroupContextArgs(
                                groupId: widget.args.groupId,
                                groupName: title,
                                mode: GroupMembersPageMode.remove,
                              ),
                            );
                            if (changed == true) {
                              controller.load();
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              _NavSettingTile(
                title: strings.groupSettingsGroupName,
                value: title,
                onTap: () => _showEditDialog(
                  context: context,
                  title: strings.groupSettingsEditGroupName,
                  initialValue: title,
                  onConfirm: controller.updateGroupName,
                ),
              ),
              _NavSettingTile(
                title: strings.groupSettingsGroupQrCode,
                onTap: () => _openDetailPage(
                  context,
                  routeName: RouteNames.groupQrCode,
                  groupId: widget.args.groupId,
                  groupName: title,
                ),
              ),
              _NavSettingTile(
                title: strings.groupSettingsGroupNotice,
                value: _noticePreview(strings, state.notice),
                onTap: () => _openDetailPage(
                  context,
                  routeName: RouteNames.groupAnnouncement,
                  groupId: widget.args.groupId,
                  groupName: title,
                ),
              ),
              _NavSettingTile(
                title: strings.groupSettingsGroupFiles,
                onTap: () => _openDetailPage(
                  context,
                  routeName: RouteNames.groupFiles,
                  groupId: widget.args.groupId,
                  groupName: title,
                ),
              ),
              _NavSettingTile(
                title: strings.groupSettingsChatHistory,
                onTap: () => _openDetailPage(
                  context,
                  routeName: RouteNames.groupChatHistory,
                  groupId: widget.args.groupId,
                  groupName: title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              _SwitchSettingTile(
                title: strings.groupSettingsMute,
                value: state.noDisturb,
                onChanged: (value) {
                  controller.updateNoDisturb(value);
                },
              ),
              _SwitchSettingTile(
                title: strings.groupSettingsPin,
                value: state.pinned,
                onChanged: (value) {
                  controller.updatePinned(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              if (canManageGroupMute)
                _SwitchSettingTile(
                  title: strings.groupSettingsMuteAll,
                  value: state.muteAll,
                  onChanged: controller.updateMuteAll,
                ),
              if (canManageJoinRequests)
                _SwitchSettingTile(
                  title: strings.groupSettingsAllowInvite,
                  value: state.allowMemberInvite,
                  onChanged: controller.updateAllowMemberInvite,
                ),
              if (canManageJoinRequests)
                _SwitchSettingTile(
                  title: strings.groupSettingsInviteConfirm,
                  value: state.needApproval,
                  onChanged: controller.updateNeedApproval,
                ),
              if (canManageJoinRequests)
                _NavSettingTile(
                  title: strings.groupSettingsJoinRequests,
                  value: state.pendingRequestCount > 0
                      ? strings.groupSettingsPendingCount(
                          state.pendingRequestCount,
                        )
                      : strings.groupSettingsPendingEmpty,
                  onTap: () async {
                    final changed = await context.pushNamed<bool>(
                      RouteNames.groupJoinRequests,
                      extra: GroupContextArgs(
                        groupId: widget.args.groupId,
                        groupName: title,
                      ),
                    );
                    if (changed == true) {
                      controller.load();
                    }
                  },
                ),
              _NavSettingTile(
                title: strings.groupSettingsNickname,
                value: state.myNickname,
                onTap: () => _showEditDialog(
                  context: context,
                  title: strings.groupSettingsEditNickname,
                  initialValue: state.myNickname,
                  onConfirm: controller.updateMyNickname,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              _DangerActionTile(
                title: strings.groupSettingsClearHistory,
                onTap: () => _clearChatHistory(
                  context: context,
                  ref: ref,
                  controller: controller,
                  state: state,
                ),
              ),
              if (isOwner)
                _DangerActionTile(
                  title: strings.groupSettingsTransferOwner,
                  onTap: () async {
                    final changed = await context.pushNamed<bool>(
                      RouteNames.groupMembers,
                      extra: GroupContextArgs(
                        groupId: widget.args.groupId,
                        groupName: title,
                        mode: GroupMembersPageMode.transfer,
                      ),
                    );
                    if (changed == true) {
                      controller.load();
                    }
                  },
                ),
              _DangerActionTile(
                title: isOwner
                    ? strings.groupSettingsDissolve
                    : strings.groupSettingsQuitGroup,
                onTap: () => _exitGroup(
                  context: context,
                  ref: ref,
                  controller: controller,
                  state: state,
                  isOwner: isOwner,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required ValueChanged<String> onConfirm,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final strings = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.groupSettingsInputHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(strings.confirmAction),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null) {
      return;
    }
    onConfirm(result);
  }

  Future<bool> _showDangerConfirm(BuildContext context, String message) async {
    final strings = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.groupSettingsConfirmAction),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
              ),
              child: Text(strings.confirmAction),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _clearChatHistory({
    required BuildContext context,
    required WidgetRef ref,
    required GroupSettingsController controller,
    required GroupSettingsState state,
  }) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await _showDangerConfirm(
      context,
      strings.groupSettingsConfirmClearHistory,
    );
    if (!confirmed) {
      return;
    }
    try {
      await controller.clearChatHistory();
      if (state.chatId.isNotEmpty) {
        final currentChatId = ref.read(chatControllerProvider).entryArgs.chatId;
        if (currentChatId == state.chatId) {
          ref.read(chatTimelineControllerProvider.notifier).clearAll();
        }
        ref
            .read(conversationListControllerProvider.notifier)
            .clearConversationPreview(
              chatId: state.chatId,
              updatedAt: DateTime.now(),
            );
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupSettingsClearHistorySuccess)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _exitGroup({
    required BuildContext context,
    required WidgetRef ref,
    required GroupSettingsController controller,
    required GroupSettingsState state,
    required bool isOwner,
  }) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await _showDangerConfirm(
      context,
      isOwner
          ? strings.groupSettingsConfirmDissolve
          : strings.groupSettingsConfirmQuitGroup,
    );
    if (!confirmed) {
      return;
    }
    try {
      if (isOwner) {
        await controller.dissolveGroup();
      } else {
        await controller.quitGroup();
      }
      if (state.chatId.isNotEmpty) {
        ref.read(chatTimelineControllerProvider.notifier).clearAll();
        ref
            .read(conversationListControllerProvider.notifier)
            .clearConversationPreview(
              chatId: state.chatId,
              updatedAt: DateTime.now(),
            );
        await ref
            .read(conversationListControllerProvider.notifier)
            .syncIncrementally();
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOwner
                ? strings.groupSettingsDissolveSuccess
                : strings.groupSettingsQuitGroupSuccess,
          ),
        ),
      );
      context.go(RoutePaths.conversations);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openDetailPage(
    BuildContext context, {
    required String routeName,
    required String groupId,
    required String groupName,
  }) {
    context.pushNamed(
      routeName,
      extra: GroupSettingDetailArgs(groupId: groupId, groupName: groupName),
    );
  }
}

String _noticePreview(AppLocalizations strings, String notice) {
  final trimmed = notice.trim();
  if (trimmed.isEmpty) {
    return strings.groupAnnouncementEmpty;
  }
  return trimmed.replaceAll('\n', ' ');
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }
}

class _NavSettingTile extends StatelessWidget {
  const _NavSettingTile({required this.title, this.value, this.onTap});

  final String title;
  final String? value;
  final VoidCallback? onTap;

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8F96A3)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8C0CC)),
        ],
      ),
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  const _SwitchSettingTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
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
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _DangerActionTile extends StatelessWidget {
  const _DangerActionTile({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFF4B4B),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MemberPreview extends StatelessWidget {
  const _MemberPreview({
    required this.name,
    required this.color,
    this.onTap,
    this.avatarUrl,
  });

  final String name;
  final Color color;
  final VoidCallback? onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 54,
        child: Column(
          children: [
            _MemberPreviewAvatar(
              name: name,
              color: color,
              avatarUrl: avatarUrl,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4E5666)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPreviewAvatar extends StatelessWidget {
  const _MemberPreviewAvatar({
    required this.name,
    required this.color,
    this.avatarUrl,
  });

  final String name;
  final Color color;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = avatarUrl?.trim() ?? '';
    if (resolvedAvatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          resolvedAvatar,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.characters.first;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconMemberAction extends StatelessWidget {
  const _IconMemberAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 54,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF8F96A3)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4E5666)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFF8F2C),
        ),
      ),
    );
  }
}
