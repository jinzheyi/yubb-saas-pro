import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/group_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/badge_widgets.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

/// 全局群加入申请页面：展示所有被管理的群组中待处理的入群申请
///
/// 数据源：
/// - 后端通过 WebSocket badgeUpdated 推送 menuBadges['contactsGroupJoinRequest'] 总数
/// - 本页面通过 myGroups 获取具体有哪些群组有待处理申请
class GroupJoinRequestsPage extends ConsumerWidget {
  const GroupJoinRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final groupsAsync = ref.watch(myGroupsProvider);
    final groups = groupsAsync.valueOrNull ?? const <GroupSummary>[];
    // 筛选出有待处理申请的群组（仅展示管理者可见的群组）
    final pendingGroups = groups
        .where((item) => item.myRole > 0 && item.pendingJoinRequestCount > 0)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(strings.groupJoinRequestsTitle),
      ),
      body: Column(
        children: [
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
                  _RequestsErrorCard(
                    errorText: groupsAsync.error.toString(),
                    onRetry: () => ref.invalidate(myGroupsProvider),
                  )
                else if (pendingGroups.isEmpty)
                  _RequestsEmptyCard(message: strings.groupJoinRequestsEmpty)
                else
                  ContactsSectionCard(
                    children: [
                      for (var index = 0; index < pendingGroups.length; index++)
                        _PendingGroupTile(
                          group: pendingGroups[index],
                          onTap: () => context.pushNamed(
                            RouteNames.groupJoinRequests,
                            extra: GroupContextArgs(
                              groupId: pendingGroups[index].groupId,
                              groupName: pendingGroups[index].name,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingGroupTile extends StatelessWidget {
  const _PendingGroupTile({
    required this.group,
    required this.onTap,
  });

  final GroupSummary group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = group.pendingJoinRequestCount;
    final displayText = count > 99 ? '99+' : '$count';
    return ContactsChevronTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 42,
          height: 42,
          child: _GroupAvatar(group: group),
        ),
      ),
      title: group.name,
      subtitle: '群成员 ${group.memberCount} 人',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          displayText,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFE54D4F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group});

  final GroupSummary group;

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

class _RequestsErrorCard extends StatelessWidget {
  const _RequestsErrorCard({required this.errorText, required this.onRetry});

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
                FilledButton.tonal(onPressed: onRetry, child: Text(strings.retry)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsEmptyCard extends StatelessWidget {
  const _RequestsEmptyCard({required this.message});

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
