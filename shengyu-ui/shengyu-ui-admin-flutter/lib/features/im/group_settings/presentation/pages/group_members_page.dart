import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/controllers/group_members_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_members_state.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class GroupMembersPage extends ConsumerStatefulWidget {
  const GroupMembersPage({super.key, required this.args});

  final GroupContextArgs args;

  @override
  ConsumerState<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends ConsumerState<GroupMembersPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(groupMembersControllerProvider(widget.args));
    final controller = ref.read(
      groupMembersControllerProvider(widget.args).notifier,
    );
    final displayGroupName = state.groupName.trim().isNotEmpty
        ? state.groupName.trim()
        : (widget.args.groupName?.trim().isNotEmpty == true
              ? widget.args.groupName!.trim()
              : strings.groupMembersTitle);
    final groupedMembers = _groupMembers(state.visibleMembers);
    final letters = groupedMembers.map((group) => group.letter).toList();
    for (final letter in letters) {
      _sectionKeys.putIfAbsent(letter, GlobalKey.new);
    }
    final headerTitle = widget.args.isRemoveMode
        ? strings.groupMembersRemoveTitle
        : widget.args.isTransferMode
        ? strings.groupMembersTransferTitle
        : strings.groupMembersTitleWithCount(state.visibleMembers.length);
    final backLabel = widget.args.isViewMode
        ? strings.backAction
        : strings.cancelAction;
    final selectedCount = state.selectedMemberIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leadingWidth: 84,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF202531),
            padding: const EdgeInsets.only(left: 8),
          ),
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          label: Text(
            backLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(headerTitle),
        actions: [
          if (widget.args.isRemoveMode && selectedCount > 0)
            TextButton(
              onPressed: () =>
                  _confirmRemove(context, strings, state, controller),
              child: Text(
                strings.groupMembersConfirmSelected(selectedCount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                Text(
                  displayGroupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 19,
                        color: Color(0xFF98A1B2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: controller.updateKeyword,
                          decoration: InputDecoration(
                            hintText: strings.groupSettingsSearchMembers,
                            isCollapsed: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            hintStyle: const TextStyle(
                              color: Color(0xFF98A1B2),
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
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                _buildBody(
                  context: context,
                  strings: strings,
                  state: state,
                  controller: controller,
                  groupedMembers: groupedMembers,
                ),
                if (letters.isNotEmpty &&
                    state.status == GroupMembersStatus.ready &&
                    widget.args.isViewMode)
                  Positioned(
                    right: 6,
                    top: 12,
                    bottom: 12,
                    child: _LetterIndex(
                      letters: letters,
                      onTap: _scrollToLetter,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AppLocalizations strings,
    required GroupMembersState state,
    required GroupMembersController controller,
    required List<_GroupedMembers> groupedMembers,
  }) {
    switch (state.status) {
      case GroupMembersStatus.initial:
      case GroupMembersStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case GroupMembersStatus.failed:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error?.message ?? strings.unknownError,
                style: const TextStyle(color: Color(0xFF8F96A3)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => controller.load(),
                child: Text(strings.retry),
              ),
            ],
          ),
        );
      case GroupMembersStatus.ready:
        if (groupedMembers.isEmpty) {
          return Center(
            child: Text(
              strings.groupSettingsPendingEmpty,
              style: const TextStyle(color: Color(0xFF8F96A3)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: groupedMembers.length,
          itemBuilder: (context, index) {
            final group = groupedMembers[index];
            return Column(
              key: _sectionKeys[group.letter],
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    group.letter,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8F96A3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      for (
                        var memberIndex = 0;
                        memberIndex < group.members.length;
                        memberIndex++
                      ) ...[
                        _MemberTile(
                          member: group.members[memberIndex],
                          args: widget.args,
                          selected: state.isSelected(
                            group.members[memberIndex].id,
                          ),
                          currentUserId: state.currentUserId,
                          currentUserRoleCode: state.currentUserRoleCode,
                          onTap: () => _handleMemberTap(
                            context,
                            strings,
                            state,
                            controller,
                            group.members[memberIndex],
                          ),
                          onManageTap: widget.args.isViewMode
                              ? () => _openManageSheet(
                                  context,
                                  strings,
                                  controller,
                                  state,
                                  group.members[memberIndex],
                                )
                              : null,
                        ),
                        if (memberIndex != group.members.length - 1)
                          const Divider(
                            height: 1,
                            indent: 66,
                            endIndent: 16,
                            color: Color(0xFFF0F2F6),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
    }
  }

  Future<void> _handleMemberTap(
    BuildContext context,
    AppLocalizations strings,
    GroupMembersState state,
    GroupMembersController controller,
    GroupMemberPreviewItem member,
  ) async {
    if (widget.args.isTransferMode) {
      await _confirmTransfer(context, strings, controller, state, member);
      return;
    }
    if (widget.args.isRemoveMode) {
      if (_cannotRemove(state, member)) {
        _showSnackBar(
          context,
          member.roleCode == 2
              ? strings.groupMembersCannotRemoveOwner
              : strings.groupMembersCannotRemoveSelf,
        );
        return;
      }
      controller.toggleSelection(member.id);
      return;
    }
    final displayName = member.name.trim().isNotEmpty
        ? member.name.trim()
        : strings.profileUnknownUser;
    context.pushNamed(
      RouteNames.contactsProfile,
      extra: {
        'userId': member.id,
        'name': displayName,
        'departmentName': member.deptName?.trim() ?? '',
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    AppLocalizations strings,
    GroupMembersState state,
    GroupMembersController controller,
  ) async {
    final selectedMembers = state.members
        .where((member) => state.selectedMemberIds.contains(member.id))
        .toList();
    if (selectedMembers.isEmpty) {
      _showSnackBar(context, strings.groupMembersSelectMembersToRemove);
      return;
    }
    final names = selectedMembers
        .map(
          (member) => member.name.trim().isEmpty
              ? strings.profileUnknownUser
              : member.name.trim(),
        )
        .join('、');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupMembersRemoveTitle),
          content: Text(strings.groupMembersRemoveConfirm(names)),
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
      await controller.removeMembers(
        selectedMembers.map((member) => member.id).toList(),
      );
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, strings.groupSettingsRemoveMemberSuccess);
      context.pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, error.toString());
    }
  }

  Future<void> _confirmTransfer(
    BuildContext context,
    AppLocalizations strings,
    GroupMembersController controller,
    GroupMembersState state,
    GroupMemberPreviewItem member,
  ) async {
    if (state.currentUserRoleCode != 2 ||
        member.roleCode == 2 ||
        member.id == state.currentUserId) {
      _showSnackBar(
        context,
        member.roleCode == 2
            ? strings.groupMembersAlreadyOwner
            : strings.groupMembersSelectOtherMember,
      );
      return;
    }
    final displayName = member.name.trim().isEmpty
        ? strings.groupMembersThisMember
        : member.name.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupMembersTransferTitle),
          content: Text(strings.groupMembersTransferConfirm(displayName)),
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
      await controller.transferOwner(member.id);
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, strings.groupMembersTransferredTo(displayName));
      context.pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, strings.groupMembersTransferFailed);
    }
  }

  Future<void> _openManageSheet(
    BuildContext context,
    AppLocalizations strings,
    GroupMembersController controller,
    GroupMembersState state,
    GroupMemberPreviewItem member,
  ) async {
    if (!_canManageMember(state, member)) {
      return;
    }
    final actions = <_ManageAction>[
      if (state.currentUserRoleCode == 2)
        _ManageAction(
          key: member.roleCode == 1 ? 'remove_admin' : 'set_admin',
          label: member.roleCode == 1
              ? strings.groupSettingsRemoveAdmin
              : strings.groupSettingsSetAdmin,
        ),
      _ManageAction(
        key: member.isMuted ? 'unmute' : 'mute',
        label: member.isMuted
            ? strings.groupSettingsUnmuteMember
            : strings.groupMembersMute24h,
      ),
    ];
    final actionKey = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  ListTile(
                    title: Center(
                      child: Text(
                        actions[index].label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(actions[index].key),
                  ),
                  if (index != actions.length - 1)
                    const Divider(height: 1, color: Color(0xFFF0F2F6)),
                ],
                const Divider(height: 8, color: Color(0xFFF5F7FB)),
                ListTile(
                  title: Center(child: Text(strings.cancelAction)),
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (actionKey == null || !context.mounted) {
      return;
    }
    try {
      if (actionKey == 'set_admin') {
        await controller.setMemberRole(memberId: member.id, role: 1);
      } else if (actionKey == 'remove_admin') {
        await controller.setMemberRole(memberId: member.id, role: 0);
      } else if (actionKey == 'mute') {
        await controller.setMemberMuted(memberId: member.id, muted: true);
      } else if (actionKey == 'unmute') {
        await controller.setMemberMuted(memberId: member.id, muted: false);
      }
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, strings.groupMembersActionSuccess);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, error.toString());
    }
  }

  bool _canManageMember(
    GroupMembersState state,
    GroupMemberPreviewItem member,
  ) {
    if (!widget.args.isViewMode) {
      return false;
    }
    if (state.currentUserRoleCode != 1 && state.currentUserRoleCode != 2) {
      return false;
    }
    if (member.id == state.currentUserId || member.roleCode == 2) {
      return false;
    }
    return member.id.trim().isNotEmpty;
  }

  bool _cannotRemove(GroupMembersState state, GroupMemberPreviewItem member) {
    return member.roleCode == 2 || member.id == state.currentUserId;
  }

  void _scrollToLetter(String letter) {
    final context = _sectionKeys[letter]?.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_GroupedMembers> _groupMembers(List<GroupMemberPreviewItem> members) {
    final groups = <String, List<GroupMemberPreviewItem>>{};
    for (final member in members) {
      final letter = _firstLetter(member.name);
      groups.putIfAbsent(letter, () => <GroupMemberPreviewItem>[]).add(member);
    }
    final sortedLetters = groups.keys.toList()..sort();
    return sortedLetters
        .map(
          (letter) => _GroupedMembers(
            letter: letter,
            members: groups[letter]!..sort((a, b) => a.name.compareTo(b.name)),
          ),
        )
        .toList();
  }

  String _firstLetter(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '#';
    }
    final first = trimmed.characters.first.toUpperCase();
    final code = first.codeUnitAt(0);
    if (code >= 19968 && code <= 40869) {
      final index = (code - 19968) % 26;
      return String.fromCharCode(65 + index);
    }
    final isAlphabet = RegExp(r'[A-Z]').hasMatch(first);
    if (isAlphabet) {
      return first;
    }
    return '#';
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.args,
    required this.selected,
    required this.currentUserId,
    required this.currentUserRoleCode,
    required this.onTap,
    this.onManageTap,
  });

  final GroupMemberPreviewItem member;
  final GroupContextArgs args;
  final bool selected;
  final String currentUserId;
  final int currentUserRoleCode;
  final VoidCallback onTap;
  final VoidCallback? onManageTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final displayName = member.name.trim().isNotEmpty
        ? member.name.trim()
        : strings.profileUnknownUser;
    final subtitle = member.isMuted
        ? _formatMuteEndTime(strings, member.muteEndTime)
        : (member.deptName?.trim().isNotEmpty == true
              ? member.deptName!.trim()
              : '');
    final canManage =
        args.isViewMode &&
        currentUserRoleCode > 0 &&
        member.roleCode != 2 &&
        member.id != currentUserId;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        onLongPress: canManage ? onManageTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (args.isRemoveMode) ...[
                _SelectionBox(
                  selected: selected,
                  disabled: member.roleCode == 2 || member.id == currentUserId,
                ),
                const SizedBox(width: 12),
              ],
              _MemberAvatar(
                name: displayName,
                colorValue: member.colorValue,
                avatarUrl: member.avatarUrl,
                size: 38,
                borderRadius: 8,
                fontSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202531),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (member.roleCode == 2)
                _Badge(label: strings.groupSettingsOwner),
              if (member.roleCode == 1)
                _Badge(label: strings.groupSettingsAdmin),
              if (member.isMuted)
                _Badge(label: strings.groupSettingsMutedMember),
              if (canManage) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onManageTap,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF98A1B2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.selected, required this.disabled});

  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1677FF) : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected
              ? const Color(0xFF1677FF)
              : (disabled ? const Color(0xFFD9DEE8) : const Color(0xFFC6CEDA)),
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF7F8794),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LetterIndex extends StatelessWidget {
  const _LetterIndex({required this.letters, required this.onTap});

  final List<String> letters;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters
          .map(
            (letter) => InkWell(
              onTap: () => onTap(letter),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8F96A3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GroupedMembers {
  const _GroupedMembers({required this.letter, required this.members});

  final String letter;
  final List<GroupMemberPreviewItem> members;
}

class _ManageAction {
  const _ManageAction({required this.key, required this.label});

  final String key;
  final String label;
}

String _formatMuteEndTime(AppLocalizations strings, DateTime? muteEndTime) {
  if (muteEndTime == null) {
    return strings.groupSettingsMutedMember;
  }
  final localTime = muteEndTime.toLocal();
  return strings.groupMembersMutedUntil(
    DateFormat('MM').format(localTime),
    DateFormat('dd').format(localTime),
    DateFormat('HH').format(localTime),
    DateFormat('mm').format(localTime),
  );
}
