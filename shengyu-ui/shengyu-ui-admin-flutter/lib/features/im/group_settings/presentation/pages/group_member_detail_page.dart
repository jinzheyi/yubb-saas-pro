import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class GroupMemberDetailPage extends ConsumerWidget {
  const GroupMemberDetailPage({
    super.key,
    required this.args,
    required this.memberUserId,
    required this.memberName,
    required this.memberRoleCode,
    required this.colorValue,
    this.avatarUrl,
    this.canTransferOwner = false,
    this.canRemoveMember = false,
    this.canToggleAdmin = false,
    this.canToggleMute = false,
    this.joinTime,
    this.muteEndTime,
    this.isMuted = false,
  });

  final GroupContextArgs args;
  final String memberUserId;
  final String memberName;
  final int memberRoleCode;
  final int colorValue;
  final String? avatarUrl;
  final bool canTransferOwner;
  final bool canRemoveMember;
  final bool canToggleAdmin;
  final bool canToggleMute;
  final String? joinTime;
  final DateTime? muteEndTime;
  final bool isMuted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final displayName = _displayMemberName(strings);
    final groupName = _displayGroupName(strings);
    final roleLabel = _resolveRoleLabel(strings, memberRoleCode);
    final isOwner = memberRoleCode == 2;
    final joinedAtText = _formatJoinTime(strings, joinTime);
    final muteEndTimeText = _formatMuteEndTime(strings, muteEndTime);
    final canOpenProfile = memberUserId.trim().isNotEmpty;
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
        title: Text(strings.groupSettingsMemberDetail),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _MemberAvatar(
                  name: displayName,
                  colorValue: colorValue,
                  avatarUrl: avatarUrl,
                  size: 58,
                  borderRadius: 14,
                  fontSize: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202531),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RoleChip(label: roleLabel, isOwner: isOwner),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            children: [
              _InfoTile(
                title: strings.groupSettingsTitle,
                value: groupName.isNotEmpty
                    ? groupName
                    : strings.workbenchMetricPlaceholder,
              ),
              _InfoTile(title: strings.groupSettingsSetRole, value: roleLabel),
              _InfoTile(
                title: strings.groupSettingsJoinTime,
                value: joinedAtText,
              ),
              if (isMuted || muteEndTime != null)
                _InfoTile(
                  title: strings.groupSettingsMuteUntil,
                  value: muteEndTimeText,
                ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            children: [
              _ActionTile(
                title: strings.groupSettingsSendMessage,
                enabled: canOpenProfile,
                onTap: !canOpenProfile
                    ? null
                    : () async {
                        try {
                          final conversation = await ref.read(
                            directConversationProvider(memberUserId).future,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          context.pushNamed(
                            RouteNames.chat,
                            extra: ChatEntryArgs.latest(
                              chatId: conversation.chatId,
                              conversationType: ConversationType.direct,
                              targetId: conversation.targetId,
                              title: conversation.title.trim().isEmpty
                                  ? displayName
                                  : conversation.title.trim(),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
              ),
              _ActionTile(
                title: strings.groupSettingsViewProfile,
                enabled: canOpenProfile,
                onTap: !canOpenProfile
                    ? null
                    : () {
                        context.pushNamed(
                          RouteNames.contactsProfile,
                          pathParameters: <String, String>{
                            'userId': memberUserId,
                          },
                          extra: {
                            'name': displayName,
                            'departmentName': '',
                          },
                        );
                      },
              ),
              _ActionTile(
                title: memberRoleCode == 1
                    ? strings.groupSettingsRemoveAdmin
                    : strings.groupSettingsSetAdmin,
                enabled: canToggleAdmin,
                onTap: !canToggleAdmin
                    ? null
                    : () => _toggleAdmin(context, ref, strings),
              ),
              _ActionTile(
                title: isMuted
                    ? strings.groupSettingsUnmuteMember
                    : strings.groupSettingsMuteMember,
                enabled: canToggleMute,
                onTap: !canToggleMute
                    ? null
                    : () => _toggleMute(context, ref, strings),
              ),
              _ActionTile(
                title: strings.groupSettingsTransferOwner,
                enabled: canTransferOwner,
                onTap: !canTransferOwner
                    ? null
                    : () => _transferOwner(context, ref, strings),
              ),
              _ActionTile(
                title: strings.groupSettingsRemoveMember,
                enabled: canRemoveMember,
                onTap: !canRemoveMember
                    ? null
                    : () => _removeMember(context, ref, strings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _transferOwner(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupSettingsConfirmAction),
          content: Text(strings.groupSettingsConfirmTransferOwner),
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
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(groupSettingsRepositoryProvider)
          .transferGroupOwner(groupId: args.groupId, newOwnerId: memberUserId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupSettingsTransferOwnerSuccess)),
      );
      context.pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
  ) async {
    final displayName = _displayMemberName(strings);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupSettingsConfirmAction),
          content: Text(strings.groupSettingsConfirmRemoveMember(displayName)),
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
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(groupSettingsRepositoryProvider)
          .removeGroupMember(groupId: args.groupId, memberUserId: memberUserId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupSettingsRemoveMemberSuccess)),
      );
      context.pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggleAdmin(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
  ) async {
    final toAdmin = memberRoleCode != 1;
    final displayName = _displayMemberName(strings);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupSettingsConfirmAction),
          content: Text(
            toAdmin
                ? strings.groupSettingsConfirmSetAdmin(displayName)
                : strings.groupSettingsConfirmRemoveAdmin(displayName),
          ),
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
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(groupSettingsRepositoryProvider)
          .setGroupMemberRole(
            groupId: args.groupId,
            memberUserId: memberUserId,
            role: toAdmin ? 1 : 0,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            toAdmin
                ? strings.groupSettingsSetAdminSuccess
                : strings.groupSettingsRemoveAdminSuccess,
          ),
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggleMute(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
  ) async {
    final nextMuted = !isMuted;
    final displayName = _displayMemberName(strings);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupSettingsConfirmAction),
          content: Text(
            nextMuted
                ? strings.groupSettingsConfirmMuteMember(displayName)
                : strings.groupSettingsConfirmUnmuteMember(displayName),
          ),
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
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(groupSettingsRepositoryProvider)
          .setGroupMemberMuted(
            groupId: args.groupId,
            memberUserId: memberUserId,
            muted: nextMuted,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextMuted
                ? strings.groupSettingsMuteMemberSuccess
                : strings.groupSettingsUnmuteMemberSuccess,
          ),
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _displayMemberName(AppLocalizations strings) {
    final trimmedName = memberName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return strings.profileUnknownUser;
  }

  String _displayGroupName(AppLocalizations strings) {
    final trimmedGroupName = args.groupName?.trim() ?? '';
    if (trimmedGroupName.isNotEmpty) {
      return trimmedGroupName;
    }
    return strings.workbenchMetricPlaceholder;
  }
}

String _formatJoinTime(AppLocalizations strings, String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) {
    return strings.groupSettingsJoinTimeUnknown;
  }
  final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    return text;
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal());
}

String _formatMuteEndTime(AppLocalizations strings, DateTime? value) {
  if (value == null) {
    return strings.groupSettingsMuteUntilUnknown;
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}

String _resolveRoleLabel(AppLocalizations strings, int roleCode) {
  switch (roleCode) {
    case 2:
      return strings.groupSettingsOwner;
    case 1:
      return strings.groupSettingsAdmin;
    default:
      return strings.groupSettingsMember;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.name,
    required this.colorValue,
    required this.size,
    required this.borderRadius,
    required this.fontSize,
    this.avatarUrl,
  });

  final String name;
  final int colorValue;
  final double size;
  final double borderRadius;
  final double fontSize;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = avatarUrl?.trim() ?? '';
    if (resolvedAvatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          resolvedAvatar,
          width: size,
          height: size,
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
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorValue),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF202531),
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 14, color: Color(0xFF8F96A3)),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, this.onTap, this.enabled = true});

  final String title;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: enabled ? const Color(0xFF202531) : const Color(0xFFB8C0CC),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: enabled ? const Color(0xFFB8C0CC) : const Color(0xFFE0E5EC),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.isOwner});

  final String label;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOwner ? const Color(0xFFFFF0E1) : const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOwner ? const Color(0xFFFF8F2C) : const Color(0xFF697386),
        ),
      ),
    );
  }
}
