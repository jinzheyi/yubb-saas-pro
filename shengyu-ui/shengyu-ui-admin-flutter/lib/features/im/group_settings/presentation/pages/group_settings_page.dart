import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/initiate_group_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_paths.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/controllers/group_settings_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';

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
        ref.read(groupSettingsControllerProvider(widget.args).notifier).load();
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
    final visibleMembers = state.members.take(8).toList(growable: false);

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
        appBar: _buildAppBar(context, strings),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        context.go(RoutePaths.conversations);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: _buildAppBar(context, strings),
        body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      GroupAvatarWidget(
                        members: state.members
                            .take(4)
                            .map((m) => GroupAvatarMember(
                                  userId: m.id,
                                  name: m.name,
                                  avatarUrl: m.avatarUrl,
                                ))
                            .toList(),
                        size: 64,
                        borderRadius: 14,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202531),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          const SizedBox(width: 8),
                          _RoleChip(roleCode: state.currentUserRoleCode),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.groupMembersTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                  children: [
                    for (final member in visibleMembers)
                      _MemberGridItem(
                        name: member.name.trim().isNotEmpty
                            ? member.name.trim()
                            : strings.profileUnknownUser,
                        userId: member.id,
                        avatarUrl: member.avatarUrl,
                        onTap: () {
                          final displayName = member.name.trim().isNotEmpty
                              ? member.name.trim()
                              : strings.profileUnknownUser;
                          context.pushNamed(
                            RouteNames.contactsProfile,
                            pathParameters: <String, String>{
                              'userId': member.id,
                            },
                            extra: {
                              'name': displayName,
                              'departmentName': member.deptName?.trim() ?? '',
                            },
                          );
                        },
                      ),
                    if (canAddMembers)
                      _MemberActionGridItem(
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
                    if (canRemoveMembers)
                      _MemberActionGridItem(
                        icon: Icons.remove_rounded,
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
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
                  child: Container(
                    height: 44,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFE8ECF3), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          strings.groupSettingsViewAllMembers,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2F6BFF),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF98A1B2),
                        ),
                      ],
                    ),
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
                  maxLength: 30,
                  onConfirm: controller.updateGroupName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
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
                onChanged: (value) => _handleAsyncAction(
                  context,
                  successMessage: value
                      ? strings.chatSettingsNotifyDisabled
                      : strings.chatSettingsNotifyEnabled,
                  action: () => controller.updateNoDisturb(value),
                ),
              ),
              _SwitchSettingTile(
                title: strings.groupSettingsPin,
                value: state.pinned,
                onChanged: (value) => _handleAsyncAction(
                  context,
                  successMessage: value
                      ? strings.chatSettingsPinned
                      : strings.chatSettingsUnpinned,
                  action: () => controller.updatePinned(value),
                ),
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
                  onChanged: (value) => _handleAsyncAction(
                    context,
                    successMessage: strings.confirmAction,
                    action: () => controller.updateMuteAll(value),
                    showSuccess: false,
                  ),
                ),
              if (canManageJoinRequests)
                _SwitchSettingTile(
                  title: strings.groupSettingsAllowInvite,
                  value: state.allowMemberInvite,
                  onChanged: (value) => _handleAsyncAction(
                    context,
                    successMessage: strings.confirmAction,
                    action: () => controller.updateAllowMemberInvite(value),
                    showSuccess: false,
                  ),
                ),
              if (canManageJoinRequests)
                _SwitchSettingTile(
                  title: strings.groupSettingsInviteConfirm,
                  value: state.needApproval,
                  onChanged: (value) => _handleAsyncAction(
                    context,
                    successMessage: strings.confirmAction,
                    action: () => controller.updateNeedApproval(value),
                    showSuccess: false,
                  ),
                ),
              if (canManageJoinRequests)
                _NavSettingTile(
                  title: strings.groupSettingsJoinRequests,
                  value: state.pendingRequestCount > 0
                      ? strings.groupSettingsPendingCount(
                          state.pendingRequestCount,
                        )
                      : strings.groupSettingsPendingEmpty,
                  valueColor: state.pendingRequestCount > 0
                      ? const Color(0xFFF54A45)
                      : const Color(0xFF8F96A3),
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
                  maxLength: 15,
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
    ),
    );
  }

  void _handleBack(BuildContext context) {
    context.go(RoutePaths.conversations);
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations strings) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 22),
        onPressed: () => _handleBack(context),
      ),
      centerTitle: true,
      title: Text(strings.groupSettingsTitle),
    );
  }

  Future<void> _showEditDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required int maxLength,
    required Future<void> Function(String value) onConfirm,
  }) async {
    final inputController = TextEditingController(text: initialValue);
    final strings = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: inputController,
                    autofocus: true,
                    maxLength: maxLength,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: strings.groupSettingsInputHint,
                      counterText: '',
                    ),
                  ),
                  Text(
                    '${inputController.text.length}/$maxLength',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF98A1B2),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(strings.cancelAction),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(inputController.text),
                  child: Text(strings.confirmAction),
                ),
              ],
            );
          },
        );
      },
    );
    inputController.dispose();
    if (result == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _handleAsyncAction(
      context,
      action: () => onConfirm(result),
      successMessage: strings.confirmAction,
      showSuccess: false,
    );
  }

  Future<void> _handleAsyncAction(
    BuildContext context, {
    required Future<void> Function() action,
    required String successMessage,
    bool showSuccess = true,
  }) async {
    try {
      await action();
      if (!context.mounted || !showSuccess) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
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
  const _NavSettingTile({
    required this.title,
    this.value,
    this.valueColor,
    this.onTap,
  });

  final String title;
  final String? value;
  final Color? valueColor;
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? const Color(0xFF8F96A3),
                ),
              ),
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

class _MemberGridItem extends StatelessWidget {
  const _MemberGridItem({
    required this.name,
    required this.userId,
    this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String userId;
  final VoidCallback? onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        children: [
          _MemberPreviewAvatar(
            name: name,
            userId: userId,
            avatarUrl: avatarUrl,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4E5666)),
          ),
        ],
      ),
    );
  }
}

class _MemberPreviewAvatar extends StatelessWidget {
  const _MemberPreviewAvatar({
    required this.name,
    required this.userId,
    this.avatarUrl,
  });

  final String name;
  final String userId;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: name,
      avatarUrl: avatarUrl,
      backgroundColor: getUserAvatarColor(userId),
      size: 54,
      borderRadius: 10,
      fontSize: 18,
      textColor: Colors.white,
    );
  }
}

class _MemberActionGridItem extends StatelessWidget {
  const _MemberActionGridItem({
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
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF8F96A3)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4E5666)),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.roleCode});

  final int roleCode;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    late final String label;
    late final Color backgroundColor;
    late final Color textColor;

    if (roleCode == 2) {
      label = strings.groupSettingsOwner;
      backgroundColor = const Color(0xFFFFF0E1);
      textColor = const Color(0xFFFF8F2C);
    } else if (roleCode == 1) {
      label = strings.groupSettingsAdmin;
      backgroundColor = const Color(0xFFEAF1FF);
      textColor = const Color(0xFF2F6BFF);
    } else {
      label = strings.groupSettingsMember;
      backgroundColor = const Color(0xFFF2F4F7);
      textColor = const Color(0xFF667085);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
