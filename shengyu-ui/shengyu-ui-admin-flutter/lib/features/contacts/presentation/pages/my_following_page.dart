import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/controllers/contact_selection_controller.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class MyFollowingPage extends ConsumerStatefulWidget {
  const MyFollowingPage({super.key, this.args = const ContactPickerArgs()});

  final ContactPickerArgs args;

  @override
  ConsumerState<MyFollowingPage> createState() => _MyFollowingPageState();
}

class _MyFollowingPageState extends ConsumerState<MyFollowingPage> {
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
    final contactsAsync = ref.watch(starContactsProvider);
    final selectionState = ref.watch(contactSelectionControllerProvider);
    final selectionController = ref.read(
      contactSelectionControllerProvider.notifier,
    );
    final keyword = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(title: const Text('我的关注')),
      body: Column(
        children: [
          Container(
            color: ThemeColors.surface(context),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索关注联系人',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: ThemeColors.searchIcon(context),
                ),
                filled: true,
                fillColor: ThemeColors.searchBarBg(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                final filtered = contacts.where((item) {
                  if (keyword.isEmpty) {
                    return true;
                  }
                  return item.name.toLowerCase().contains(keyword) ||
                      item.departmentName.toLowerCase().contains(keyword) ||
                      item.postName.toLowerCase().contains(keyword);
                }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      '暂无关注联系人',
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final selected = selectionState.isSelected(item.userId);
                    return ListTile(
                      onTap: () => _handleTap(selectionController, item),
                      leading: ContactsInitialAvatar(
                        name: item.name,
                        color: getUserAvatarColor(item.userId),
                        seed: item.userId,
                        avatarUrl: item.avatarUrl,
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        item.postName.trim().isEmpty
                            ? item.departmentName
                            : item.postName,
                      ),
                      trailing: widget.args.selectionMode
                          ? _isSingleSelection
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
                                    onChanged: (_) =>
                                        _handleTap(selectionController, item),
                                  )
                          : Icon(
                              Icons.chevron_right_rounded,
                              color: ThemeColors.chevronColor(context),
                            ),
                    );
                  },
                );
              },
              error: (error, _) => Center(child: Text(error.toString())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.args.selectionMode && !_isSingleSelection
          ? Container(
              color: ThemeColors.surface(context),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '已选择 ${selectionState.count} 人',
                      style: TextStyle(
                        fontSize: 15,
                        color: ThemeColors.textPrimary(context),
                      ),
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
            )
          : null,
    );
  }

  Future<void> _handleTap(
    ContactSelectionController selectionController,
    ContactDirectoryItem item,
  ) async {
    if (widget.args.selectionMode) {
      final selected = selectionController.toggle(
        ContactSelectionEntry(
          id: item.userId,
          name: item.name,
          role: item.postName.trim().isEmpty
              ? item.departmentName
              : item.postName,
          avatarUrl: item.avatarUrl,
        ),
      );
      if (_isSingleSelection && selected && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    if (!mounted) {
      return;
    }
    context.pushNamed(
      RouteNames.contactsProfile,
      pathParameters: <String, String>{'userId': item.userId},
      extra: <String, String>{
        'name': item.name,
        'departmentName': item.departmentName,
      },
    );
  }
}
