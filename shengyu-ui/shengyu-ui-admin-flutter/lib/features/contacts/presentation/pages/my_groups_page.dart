import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_group_members_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/group_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/contact_group_members_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/badge_widgets.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';

class MyGroupsPage extends ConsumerStatefulWidget {
  const MyGroupsPage({super.key, this.args = const ContactPickerArgs()});

  final ContactPickerArgs args;

  @override
  ConsumerState<MyGroupsPage> createState() => _MyGroupsPageState();
}

class _MyGroupsPageState extends ConsumerState<MyGroupsPage> {
  final TextEditingController _searchController = TextEditingController();

  bool get _isSingleSelection =>
      widget.args.selectionMode && widget.args.selectionLimit == 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final groupsAsync = ref.watch(myGroupsProvider);
    final groups = groupsAsync.valueOrNull ?? const <GroupSummary>[];
    final keyword = _searchController.text.trim().toLowerCase();
    final visibleGroups = keyword.isEmpty
        ? groups
        : groups
              .where((item) => item.name.toLowerCase().contains(keyword))
              .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: const ContactsBackButton(),
        centerTitle: true,
        title: Text(strings.contactsMyGroups),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索我的群组',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF3F4F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 24),
              children: [
                if (groupsAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (groupsAsync.hasError)
                  _GroupsErrorCard(
                    errorText: groupsAsync.error.toString(),
                    onRetry: () => ref.invalidate(myGroupsProvider),
                  )
                else if (visibleGroups.isEmpty)
                  _GroupsEmptyCard(
                    message: keyword.isEmpty
                        ? strings.contactsMyGroupsEmpty
                        : '暂无匹配群组',
                  )
                else
                  ContactsSectionCard(
                    children: [
                      for (
                        var index = 0;
                        index < visibleGroups.length;
                        index++
                      ) ...[
                        _GroupTile(
                          group: visibleGroups[index],
                          countLabel: strings.contactsCountPeople(
                            visibleGroups[index].memberCount,
                          ),
                          roleLabel: _roleLabel(visibleGroups[index].myRole),
                          color: _groupColor(visibleGroups[index].name),
                          onTap: () => _handleGroupTap(visibleGroups[index]),
                          onOpenJoinRequests:
                              visibleGroups[index].myRole > 0 &&
                                  visibleGroups[index].pendingJoinRequestCount >
                                      0
                              ? () => context.pushNamed(
                                  RouteNames.groupJoinRequests,
                                  extra: GroupContextArgs(
                                    groupId: visibleGroups[index].groupId,
                                    groupName: visibleGroups[index].name,
                                  ),
                                )
                              : null,
                          pendingCount:
                              visibleGroups[index].pendingJoinRequestCount,
                        ),
                        if (index != visibleGroups.length - 1)
                          const Divider(
                            height: 1,
                            indent: 70,
                            endIndent: 16,
                            color: Color(0xFFF0F2F6),
                          ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGroupTap(GroupSummary group) async {
    if (widget.args.selectionMode) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ContactGroupMembersPage(
            args: ContactGroupMembersArgs(
              groupId: group.groupId,
              groupName: group.name,
              selectionLimit: widget.args.selectionLimit,
            ),
          ),
        ),
      );
      if (_isSingleSelection &&
          mounted &&
          ref.read(contactSelectionControllerProvider).count > 0) {
        Navigator.of(context).pop();
      }
      return;
    }
    try {
      final chatId = await ref
          .read(groupSettingsRepositoryProvider)
          .ensureGroupChatId(group.groupId);
      if (!mounted) {
        return;
      }
      context.pushNamed(
        RouteNames.chat,
        extra: ChatEntryArgs.latest(
          chatId: chatId,
          conversationType: ConversationType.group,
          targetId: group.groupId,
          title: group.name,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.operationFailed(error.toString()))));
    }
  }

  Color _groupColor(String name) {
    return getGroupAvatarColor(name.hashCode.toString());
  }

  String _roleLabel(int role) {
    if (role >= 2) {
      return '群主';
    }
    if (role == 1) {
      return '管理员';
    }
    return '成员';
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.countLabel,
    required this.roleLabel,
    required this.color,
    required this.onTap,
    this.onOpenJoinRequests,
    this.pendingCount = 0,
  });

  final GroupSummary group;
  final String countLabel;
  final String roleLabel;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onOpenJoinRequests;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return ContactsChevronTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 42,
          height: 42,
          child: _GroupAvatar(group: group, color: color),
        ),
      ),
      title: group.name,
      subtitle: countLabel,
      trailing: onOpenJoinRequests != null && pendingCount > 0
          ? GestureDetector(
              onTap: onOpenJoinRequests,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pendingCount > 99 ? '99+' : '$pendingCount',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE54D4F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : Text(
              roleLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8F96A3)),
            ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group, required this.color});

  final GroupSummary group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GroupAvatarWidget.fromMembers(
      members: group.groupMemberItems
          .map((item) => GroupAvatarMember(
                userId: item.userId ?? '',
                name: item.name ?? '',
                avatarUrl: item.avatar,
              ))
          .toList(),
      size: 42,
      borderRadius: 10,
    );
  }
}

class _GroupsErrorCard extends StatelessWidget {
  const _GroupsErrorCard({required this.errorText, required this.onRetry});

  final String errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ContactsSectionCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE54D4F),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: Text(strings.retry),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupsEmptyCard extends StatelessWidget {
  const _GroupsEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ContactsSectionCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15, color: Color(0xFF8F96A3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
