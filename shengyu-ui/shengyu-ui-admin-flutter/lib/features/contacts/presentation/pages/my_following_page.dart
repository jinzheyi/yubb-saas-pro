import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/controllers/contact_selection_controller.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';

class MyFollowingPage extends ConsumerStatefulWidget {
  const MyFollowingPage({super.key, this.args = const ContactPickerArgs()});

  final ContactPickerArgs args;

  @override
  ConsumerState<MyFollowingPage> createState() => _MyFollowingPageState();
}

class _MyFollowingPageState extends ConsumerState<MyFollowingPage> {
  final TextEditingController _searchController = TextEditingController();

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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('我的关注')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索关注联系人',
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
                  return const Center(
                    child: Text(
                      '暂无关注联系人',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8F96A3)),
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
                        color: const Color(0xFFE97CAB),
                        avatarUrl: item.avatarUrl,
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        item.postName.trim().isEmpty
                            ? item.departmentName
                            : item.postName,
                      ),
                      trailing: widget.args.selectionMode
                          ? Checkbox(
                              value: selected,
                              onChanged: (_) =>
                                  _handleTap(selectionController, item),
                            )
                          : const Icon(Icons.chevron_right_rounded),
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
      bottomNavigationBar: widget.args.selectionMode
          ? Container(
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
            )
          : null,
    );
  }

  Future<void> _handleTap(
    ContactSelectionController selectionController,
    ContactDirectoryItem item,
  ) async {
    if (widget.args.selectionMode) {
      selectionController.toggle(
        ContactSelectionEntry(
          id: item.userId,
          name: item.name,
          role: item.postName.trim().isEmpty
              ? item.departmentName
              : item.postName,
          avatarUrl: item.avatarUrl,
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    context.pushNamed(
      RouteNames.contactsProfile,
      extra: <String, String>{
        'userId': item.userId,
        'name': item.name,
        'departmentName': item.departmentName,
      },
    );
  }
}
