import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_group_members_args.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';

class ContactGroupMembersPage extends ConsumerWidget {
  const ContactGroupMembersPage({super.key, required this.args});

  final ContactGroupMembersArgs args;

  bool get _isSingleSelection => args.selectionLimit == 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersFutureProvider(args.groupId));
    final selectionState = ref.watch(contactSelectionControllerProvider);
    final selectionController = ref.read(
      contactSelectionControllerProvider.notifier,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: Text(args.groupName)),
      body: membersAsync.when(
        data: (members) => ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final displayName = member.nickname.trim().isNotEmpty
                ? member.nickname.trim()
                : (member.userName.trim().isNotEmpty
                      ? member.userName.trim()
                      : '未命名用户');
            final role = member.role == 2
                ? '群主'
                : member.role == 1
                ? '管理员'
                : '';
            final selected = selectionState.isSelected(member.userId);
            return ListTile(
              onTap: () {
                final selected = selectionController.toggle(
                  ContactSelectionEntry(
                    id: member.userId,
                    name: displayName,
                    role: role,
                    avatarUrl: member.avatarUrl?.trim() ?? '',
                  ),
                );
                if (_isSingleSelection && selected) {
                  Navigator.of(context).pop();
                }
              },
              leading: ContactsInitialAvatar(
                name: displayName,
                avatarUrl: member.avatarUrl,
                color: const Color(0xFF5B8FF9),
              ),
              title: Text(displayName),
              subtitle: Text(role),
              trailing: _isSingleSelection
                  ? Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF98A2B3),
                    )
                  : Checkbox(
                      value: selected,
                      onChanged: (_) {
                        selectionController.toggle(
                          ContactSelectionEntry(
                            id: member.userId,
                            name: displayName,
                            role: role,
                            avatarUrl: member.avatarUrl?.trim() ?? '',
                      ),
            );
          },
                    ),
            );
          },
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: _isSingleSelection
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '已选择 ${selectionState.count} 人',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  FilledButton(
                    onPressed: selectionState.count == 0
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
    );
  }
}
