import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_department_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/initiate_group_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contact_picker_widgets.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class InitiateGroupPage extends ConsumerStatefulWidget {
  const InitiateGroupPage({
    super.key,
    this.args = const InitiateGroupArgs.create(),
  });

  final InitiateGroupArgs args;

  @override
  ConsumerState<InitiateGroupPage> createState() => _InitiateGroupPageState();
}

class _InitiateGroupPageState extends ConsumerState<InitiateGroupPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_SelectableContact> _contacts = <_SelectableContact>[];

  bool _loading = true;
  bool _submitting = false;
  bool _selectionClosed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  @override
  void dispose() {
    _closeSelection();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(contactSelectionControllerProvider);
    final filtered = _filteredContacts();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(widget.args.isAddMode ? '添加成员' : '发起群聊'),
        leadingWidth: 68,
        leading: TextButton.icon(
          onPressed: _handleBack,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF202531),
            padding: const EdgeInsets.only(left: 8),
          ),
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          label: const Text(
            '返回',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索成员',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
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
                ContactPickerCategoryPanel(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  items: [
                    ContactPickerCategoryAction(
                      icon: AppIconKind.groupsFill,
                      label: '鎴戠殑缇ょ粍',
                      color: const Color(0xFFFB923C),
                      onTap: () => _openPickerCategory(
                        RouteNames.contactsMyGroups,
                        ContactPickerArgs(
                          selectionMode: true,
                          selectionLimit: widget.args.selectionLimit,
                        ),
                      ),
                    ),
                    ContactPickerCategoryAction(
                      icon: AppIconKind.starOutline,
                      label: '鎴戠殑鍏虫敞',
                      color: const Color(0xFFEAB308),
                      onTap: () => _openPickerCategory(
                        RouteNames.contactsMyFollowing,
                        ContactPickerArgs(
                          selectionMode: true,
                          selectionLimit: widget.args.selectionLimit,
                        ),
                      ),
                    ),
                    ContactPickerCategoryAction(
                      icon: AppIconKind.tree,
                      label: '缁勭粐鏋舵瀯',
                      color: const Color(0xFF84CC16),
                      onTap: () => _openPickerCategory(
                        RouteNames.contactsOrg,
                        ContactPickerArgs(
                          selectionMode: true,
                          selectionLimit: widget.args.selectionLimit,
                        ),
                      ),
                    ),
                    ContactPickerCategoryAction(
                      icon: AppIconKind.apartment,
                      label: '鎴戠殑閮ㄩ棬',
                      color: const Color(0xFF06B6D4),
                      onTap: () => _openPickerCategory(
                        RouteNames.contactsMyDepartment,
                        ContactDepartmentArgs(
                          selectionMode: true,
                          selectionLimit: widget.args.selectionLimit,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(
                    child: Text(
                      '暂无可选联系人',
                      style: TextStyle(fontSize: 14, color: Color(0xFF697386)),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                      color: Color(0xFFF0F2F6),
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Material(
                        color: Colors.white,
                        child: ListTile(
                          onTap: () => _toggleSelection(item),
                          leading: ContactsInitialAvatar(
                            name: item.name,
                            avatarUrl: item.avatarUrl,
                            color: _avatarColor(item.userId),
                          ),
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.roleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Checkbox(
                            value: selectionState.isSelected(item.userId),
                            onChanged: (_) => _toggleSelection(item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已选择 ${selectionState.count} 人',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF202531),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _submitting ? null : _handleConfirm,
                  child: Text(
                    _submitting
                        ? (widget.args.isAddMode ? '添加中...' : '创建中...')
                        : '确定',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initialize() async {
    ref
        .read(contactSelectionControllerProvider.notifier)
        .start(limit: widget.args.selectionLimit);
    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final profile = await ref.read(currentUserProfileProvider.future);
      final existingIds = widget.args.isAddMode
          ? await _loadExistingMemberIds(profile)
          : const <String>{};
      final contacts = await ref.read(contactsRepositoryProvider).getContacts();
      final items = <_SelectableContact>[];

      if (!widget.args.isAddMode) {
        items.add(
          _SelectableContact(
            userId: profile.userId,
            name: profile.nickname.trim().isEmpty
                ? '我'
                : profile.nickname.trim(),
            departmentName: profile.departmentName,
            pinyin: 'W',
            postName: profile.postName,
            avatarUrl: profile.avatarUrl,
            isCurrentUser: true,
          ),
        );
        ref
            .read(contactSelectionControllerProvider.notifier)
            .ensureSelected(
              ContactSelectionEntry(
                id: profile.userId,
                name: profile.nickname.trim().isEmpty
                    ? '我'
                    : profile.nickname.trim(),
                role: _roleLabel(
                  departmentName: profile.departmentName,
                  postName: profile.postName,
                ),
                avatarUrl: profile.avatarUrl,
                isCurrentUser: true,
              ),
            );
      }

      items.addAll(
        contacts
            .where((item) {
              if (!widget.args.isAddMode && item.userId == profile.userId) {
                return false;
              }
              if (widget.args.isAddMode && existingIds.contains(item.userId)) {
                return false;
              }
              return true;
            })
            .map(
              (item) => _SelectableContact(
                userId: item.userId,
                name: item.name.trim().isEmpty ? '未命名用户' : item.name.trim(),
                departmentName: item.departmentName,
                pinyin: item.pinyin,
                postName: item.postName,
                avatarUrl: item.avatarUrl,
              ),
            ),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _contacts
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      if (error is! StateError) {
        _showMessage(error.toString());
      }
    }
  }

  Future<Set<String>> _loadExistingMemberIds(UserProfile profile) async {
    final groupId = widget.args.groupId;
    if (groupId == null || groupId.trim().isEmpty) {
      return <String>{};
    }
    final repository = ref.read(groupSettingsRepositoryProvider);
    final snapshot = await repository.getGroupSettings(groupId);
    final members = await repository.getGroupMembers(groupId);
    final myMembers = members.where((item) => item.userId == profile.userId);
    final myMember = myMembers.isEmpty ? null : myMembers.first;
    final canAddMembers =
        snapshot.ownerUserId == profile.userId ||
        myMember?.role == 1 ||
        myMember?.role == 2 ||
        snapshot.allowMemberInvite;
    if (!canAddMembers) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showMessage('当前群不允许添加成员');
        _handleBack();
      });
      throw StateError('当前群不允许添加成员');
    }
    return members.map((item) => item.userId).toSet();
  }

  List<_SelectableContact> _filteredContacts() {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      return _contacts;
    }
    return _contacts.where((item) {
      return item.name.toLowerCase().contains(keyword) ||
          item.departmentName.toLowerCase().contains(keyword) ||
          item.postName.toLowerCase().contains(keyword);
    }).toList();
  }

  void _toggleSelection(_SelectableContact item) {
    final selected = ref
        .read(contactSelectionControllerProvider.notifier)
        .toggle(
          ContactSelectionEntry(
            id: item.userId,
            name: item.name,
            role: item.roleLabel,
            avatarUrl: item.avatarUrl,
            isCurrentUser: item.isCurrentUser,
          ),
        );
    if (!selected && item.isCurrentUser) {
      _showMessage('当前登录账号必须保留在群聊中');
    }
  }

  Future<void> _openPickerCategory(String routeName, Object args) async {
    await context.pushNamed(routeName, extra: args);
    if (mounted) {
      setState(() {});
    }
  }

  void _handleBack() {
    _closeSelection();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _closeSelection() {
    if (_selectionClosed) {
      return;
    }
    _selectionClosed = true;
    ref.read(contactSelectionControllerProvider.notifier).end();
  }

  Future<void> _handleConfirm() async {
    if (_submitting) {
      return;
    }
    final selectionState = ref.read(contactSelectionControllerProvider);
    final selectedMembers = selectionState.entries.values.toList();
    if (!widget.args.isAddMode && selectedMembers.length < 2) {
      _showMessage('至少选择两名成员');
      return;
    }
    if (widget.args.isAddMode && selectedMembers.isEmpty) {
      _showMessage('至少选择一名成员');
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      if (widget.args.isAddMode) {
        await ref
            .read(groupSettingsRepositoryProvider)
            .addGroupMembers(
              groupId: widget.args.groupId!,
              memberIds: selectedMembers.map((item) => item.id).toList(),
            );
        ref.invalidate(groupMembersFutureProvider(widget.args.groupId!));
        _closeSelection();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('添加成员成功')));
        Navigator.of(context).maybePop();
      } else {
        final groupName = _trimGroupName(_generateGroupName(selectedMembers));
        final result = await ref
            .read(groupSettingsRepositoryProvider)
            .createGroup(
              name: groupName,
              groupType: 1,
              memberIds: selectedMembers.map((item) => item.id).toList(),
            );
        final chatId = result.chatId.trim().isNotEmpty
            ? result.chatId.trim()
            : await ref
                  .read(groupSettingsRepositoryProvider)
                  .ensureGroupChatId(result.groupId);
        unawaited(
          ref
              .read(conversationListControllerProvider.notifier)
              .syncIncrementally(),
        );
        _closeSelection();
        if (!mounted) {
          return;
        }
        context.goNamed(
          RouteNames.chat,
          extra: ChatEntryArgs.latest(
            chatId: chatId,
            conversationType: ConversationType.group,
            targetId: result.groupId,
            title: groupName,
          ),
        );
      }
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _generateGroupName(List<ContactSelectionEntry> members) {
    if (members.isEmpty) {
      return '群聊';
    }
    if (members.length <= 3) {
      return members.map((item) => item.name).join('、');
    }
    final firstThree = members.take(3).map((item) => item.name).join('、');
    return '$firstThree等${members.length}人';
  }

  String _trimGroupName(String name) {
    return name.length <= 50 ? name : name.substring(0, 50);
  }

  String _roleLabel({
    required String departmentName,
    required String postName,
  }) {
    final normalizedPost = postName.trim();
    if (normalizedPost.isNotEmpty) {
      return normalizedPost;
    }
    final normalizedDepartment = departmentName.trim();
    if (normalizedDepartment.isNotEmpty) {
      return normalizedDepartment;
    }
    return '未分配部门';
  }

  Color _avatarColor(String seed) {
    const palette = <Color>[
      Color(0xFF5B8FF9),
      Color(0xFF61DDAA),
      Color(0xFFF6BD16),
      Color(0xFF7262FD),
      Color(0xFF78D3F8),
      Color(0xFF9661BC),
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SelectableContact extends ContactDirectoryItem {
  const _SelectableContact({
    required super.userId,
    required super.name,
    required super.departmentName,
    required super.pinyin,
    required super.avatarUrl,
    required super.postName,
    this.isCurrentUser = false,
  }) : super(chatId: '', email: '', officeLocation: '');

  final bool isCurrentUser;

  String get roleLabel {
    final normalizedPost = postName.trim();
    if (normalizedPost.isNotEmpty) {
      return normalizedPost;
    }
    final normalizedDepartment = departmentName.trim();
    if (normalizedDepartment.isNotEmpty) {
      return normalizedDepartment;
    }
    return '未分配部门';
  }
}
