import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_department_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/department_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/controllers/contact_selection_controller.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class MyDepartmentPage extends ConsumerStatefulWidget {
  const MyDepartmentPage({
    super.key,
    this.args = const ContactDepartmentArgs(),
  });

  final ContactDepartmentArgs args;

  @override
  ConsumerState<MyDepartmentPage> createState() => _MyDepartmentPageState();
}

class _MyDepartmentPageState extends ConsumerState<MyDepartmentPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedDeptId;
  final Set<String> _expandedDeptIds = <String>{};
  bool _searching = false;
  List<DepartmentSummary>? _searchedDepartments;
  final Map<String, List<ContactDirectoryItem>> _searchedMembersByDept =
      <String, List<ContactDirectoryItem>>{};

  bool get _isSingleSelection =>
      widget.args.selectionMode && widget.args.selectionLimit == 1;

  @override
  void initState() {
    super.initState();
    _selectedDeptId = widget.args.initialDeptId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final deptTreeAsync = ref.watch(myDepartmentTreeProvider);
    final sourceDepartments =
        deptTreeAsync.valueOrNull ?? const <DepartmentSummary>[];
    final departments = _searchedDepartments ?? sourceDepartments;
    final visibleDepartments = _searchedDepartments != null
        ? departments
        : _filterDepartments(departments);
    final activeDept = _resolveActiveDept(visibleDepartments);
    final memberKeyword = _searchController.text.trim();
    final searchMembers = activeDept == null
        ? null
        : _searchedMembersByDept[activeDept.deptId];
    final useSearchMembers =
        memberKeyword.isNotEmpty && _searchedDepartments != null;
    final membersAsync = useSearchMembers || activeDept == null
        ? null
        : ref.watch(
            departmentMembersProvider(
              DepartmentMembersQuery(
                deptId: activeDept.deptId,
                keyword: memberKeyword,
              ),
            ),
          );
    final members = useSearchMembers
        ? (searchMembers ?? const <ContactDirectoryItem>[])
        : (membersAsync?.valueOrNull ?? const <ContactDirectoryItem>[]);
    final selectionState = ref.watch(contactSelectionControllerProvider);
    final selectionController = ref.read(
      contactSelectionControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: const ContactsBackButton(),
        centerTitle: true,
        title: Text(strings.contactsDepartments),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ===== Header + Search Bar (1:1 对齐会话列表页) =====
            Container(
              color: ThemeColors.surface(context),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // 标题行
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activeDept?.name ??
                              widget.args.initialDeptName ??
                              strings.contactsDepartments,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: ThemeColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 搜索框（1:1 对齐会话列表页）
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: ThemeColors.searchBarBg(context),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _searchController.text.trim().isNotEmpty
                              ? _handleSearch
                              : null,
                          child: Icon(
                            ShengyuIconFont.chaxun,
                            size: 16,
                            color: _searchController.text.trim().isNotEmpty
                                ? ThemeColors.searchIcon(context)
                                : ThemeColors.searchHint(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              fontSize: 14,
                              color: ThemeColors.searchText(context),
                            ),
                            decoration: InputDecoration(
                              hintText: '搜索部门成员',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isCollapsed: true,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: ThemeColors.searchHint(context),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _handleSearch(),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty)
                          InkWell(
                            onTap: _handleSearch,
                            child: Icon(
                              ShengyuIconFont.fasong,
                              size: 16,
                              color: ThemeColors.searchIcon(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ===== 内容区域 =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (deptTreeAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_searching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (deptTreeAsync.hasError)
                    _DepartmentErrorCard(
                      message: deptTreeAsync.error.toString(),
                      onRetry: () => ref.invalidate(myDepartmentTreeProvider),
                    )
                  else if (visibleDepartments.isEmpty)
                    _DepartmentEmptyCard(message: strings.contactsDepartmentsEmpty)
                  else
                    ..._buildDepartmentSections(
                      strings: strings,
                      departments: visibleDepartments,
                      activeDept: activeDept,
                      membersAsync: membersAsync,
                      members: members,
                      selectionState: selectionState,
                      selectionController: selectionController,
                      context: context,
                    ),
                ],
              ),
            ),
          ],
        ),
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

  DepartmentSummary? _resolveActiveDept(List<DepartmentSummary> departments) {
    if (departments.isEmpty) {
      return null;
    }
    final selectedDeptId = _selectedDeptId;
    if (selectedDeptId != null && selectedDeptId.isNotEmpty) {
      for (final department in departments) {
        if (department.deptId == selectedDeptId) {
          return department;
        }
      }
    }
    return departments.first;
  }

  List<Widget> _buildDepartmentSections({
    required AppLocalizations strings,
    required List<DepartmentSummary> departments,
    required DepartmentSummary? activeDept,
    required AsyncValue<List<ContactDirectoryItem>>? membersAsync,
    required List<ContactDirectoryItem> members,
    required ContactSelectionController selectionController,
    required BuildContext context,
    required dynamic selectionState,
  }) {
    final nodes = _buildTree(departments);
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ContactsSectionCard(
          children: _buildTreeTiles(nodes, activeDept, strings),
        ),
      ),
      const SizedBox(height: 10),
    ];
    if (activeDept == null) {
      widgets.add(
        _DepartmentEmptyCard(message: strings.contactsDepartmentsEmpty),
      );
      return widgets;
    }
    if (membersAsync?.isLoading == true) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      return widgets;
    }
    if (membersAsync?.hasError == true) {
      widgets.add(
        _DepartmentErrorCard(
          message: membersAsync!.error.toString(),
          onRetry: () => ref.invalidate(
            departmentMembersProvider(
              DepartmentMembersQuery(
                deptId: activeDept.deptId,
                keyword: _searchController.text.trim(),
              ),
            ),
          ),
        ),
      );
      return widgets;
    }
    if (members.isEmpty) {
      widgets.add(
        _DepartmentEmptyCard(message: strings.contactsDepartmentsEmpty),
      );
      return widgets;
    }
    widgets.add(
      Container(
        color: ThemeColors.surface(context),
        child: Column(
          children: [
            for (var index = 0; index < members.length; index++) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == members.length - 1
                          ? Colors.transparent
                          : ThemeColors.divider(context),
                    ),
                  ),
                ),
                child: _DepartmentMemberTile(
                  member: members[index],
                  role: members[index].postName.isEmpty
                      ? members[index].departmentName
                      : members[index].postName,
                  color: _memberColor(members[index].userId),
                  selectionMode: widget.args.selectionMode,
                  singleSelection: _isSingleSelection,
                  selected: selectionState.isSelected(members[index].userId),
                  onTap: () => widget.args.selectionMode
                      ? _toggleSelected(selectionController, members[index])
                      : _openProfile(context, members[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return widgets;
  }

  List<DepartmentSummary> _filterDepartments(
    List<DepartmentSummary> departments,
  ) {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      return departments;
    }
    final keptIds = <String>{};
    final byId = <String, DepartmentSummary>{
      for (final item in departments) item.deptId: item,
    };
    for (final item in departments) {
      if (!item.name.toLowerCase().contains(keyword)) {
        continue;
      }
      DepartmentSummary? cursor = item;
      while (cursor != null && keptIds.add(cursor.deptId)) {
        final parentId = cursor.parentDeptId;
        cursor = parentId == null ? null : byId[parentId];
      }
    }
    return departments.where((item) => keptIds.contains(item.deptId)).toList();
  }

  List<_DeptNode> _buildTree(List<DepartmentSummary> departments) {
    final nodeMap = <String, _DeptNode>{};
    for (final department in departments) {
      nodeMap[department.deptId] = _DeptNode(department: department);
    }
    final roots = <_DeptNode>[];
    for (final node in nodeMap.values) {
      final parentId = node.department.parentDeptId;
      final parent = parentId == null ? null : nodeMap[parentId];
      if (parent == null) {
        roots.add(node);
      } else {
        parent.children.add(node);
      }
    }
    void sortNodes(List<_DeptNode> nodes) {
      nodes.sort(
        (a, b) => a.department.sort != b.department.sort
            ? a.department.sort.compareTo(b.department.sort)
            : a.department.name.compareTo(b.department.name),
      );
      for (final node in nodes) {
        sortNodes(node.children);
      }
    }

    sortNodes(roots);
    return roots;
  }

  List<Widget> _buildTreeTiles(
    List<_DeptNode> nodes,
    DepartmentSummary? activeDept,
    AppLocalizations strings, {
    int depth = 0,
  }) {
    final widgets = <Widget>[];
    final forceExpandForSearch = _searchController.text.trim().isNotEmpty;
    for (final node in nodes) {
      final expanded =
          forceExpandForSearch ||
          _expandedDeptIds.contains(node.department.deptId) ||
          depth == 0;
      final selected = activeDept?.deptId == node.department.deptId;
      widgets.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedDeptId = node.department.deptId;
              if (node.children.isNotEmpty) {
                if (expanded) {
                  _expandedDeptIds.remove(node.department.deptId);
                } else {
                  _expandedDeptIds.add(node.department.deptId);
                }
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(16 + depth * 18, 12, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: node.children.isEmpty
                      ? const SizedBox.shrink()
                      : Icon(
                          expanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          size: 18,
                          color: ThemeColors.chevronColor(context),
                        ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.apartment_rounded,
                  size: 16,
                  color: selected
                      ? const Color(0xFF3D75F6)
                      : const Color(0xFF6FB214),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${node.department.name} ${strings.contactsCountPeople(node.department.memberCount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF3D75F6)
                          : ThemeColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (expanded && node.children.isNotEmpty) {
        widgets.addAll(
          _buildTreeTiles(node.children, activeDept, strings, depth: depth + 1),
        );
      }
    }
    return widgets;
  }

  void _handleSearch() {
    _searchFocusNode.unfocus();
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchedDepartments = null;
        _searchedMembersByDept.clear();
      });
      return;
    }
    unawaited(_runDepartmentSearch(keyword));
  }

  Future<void> _runDepartmentSearch(String keyword) async {
    final departments = ref.read(myDepartmentTreeProvider).valueOrNull;
    if (departments == null || departments.isEmpty) {
      return;
    }
    if (mounted) {
      setState(() {
        _searching = true;
      });
    }
    final searchedMembersByDept = <String, List<ContactDirectoryItem>>{};
    final tree = _buildTree(departments);
    if (tree.isNotEmpty) {
      final rootDeptId = tree.first.department.deptId;
      final allMembers = await ref
          .read(contactsRepositoryProvider)
          .getContactsByDepartment(rootDeptId, keyword: keyword);
      for (final member in allMembers) {
        final deptId = member.departmentId;
        if (deptId.isNotEmpty) {
          searchedMembersByDept
              .putIfAbsent(deptId, () => <ContactDirectoryItem>[])
              .add(member);
        }
      }
    }
    final result = _buildSearchTree(departments, searchedMembersByDept);
    final firstMatchedDept = _findFirstDeptWithMembers(
      departments: result,
      searchedMembersByDept: searchedMembersByDept,
    );
    if (!mounted || _searchController.text.trim() != keyword) {
      return;
    }
    setState(() {
      _searching = false;
      _searchedDepartments = result;
      _searchedMembersByDept
        ..clear()
        ..addAll(searchedMembersByDept);
      _selectedDeptId = firstMatchedDept?.deptId;
    });
  }

  List<DepartmentSummary> _buildSearchTree(
    List<DepartmentSummary> departments,
    Map<String, List<ContactDirectoryItem>> searchedMembersByDept,
  ) {
    final byId = <String, DepartmentSummary>{
      for (final d in departments) d.deptId: d,
    };
    final keptIds = <String>{};
    for (final deptId in searchedMembersByDept.keys) {
      DepartmentSummary? cursor = byId[deptId];
      while (cursor != null && keptIds.add(cursor.deptId)) {
        final parentId = cursor.parentDeptId;
        cursor = parentId == null ? null : byId[parentId];
      }
    }
    final result = departments
        .where((d) => keptIds.contains(d.deptId))
        .map((d) => DepartmentSummary(
              deptId: d.deptId,
              name: d.name,
              memberCount: searchedMembersByDept[d.deptId]?.length ?? 0,
              parentDeptId: d.parentDeptId,
              sort: d.sort,
            ))
        .toList();
    return result;
  }

  DepartmentSummary? _findFirstDeptWithMembers({
    required List<DepartmentSummary> departments,
    required Map<String, List<ContactDirectoryItem>> searchedMembersByDept,
  }) {
    for (final department in departments) {
      final members = searchedMembersByDept[department.deptId];
      if (members != null && members.isNotEmpty) {
        return department;
      }
    }
    return null;
  }

  void _openProfile(BuildContext context, ContactDirectoryItem member) {
    context.pushNamed(
      RouteNames.contactsProfile,
      pathParameters: <String, String>{'userId': member.userId},
      extra: <String, String>{
        'name': member.name,
        'departmentName': member.departmentName,
      },
    );
  }

  void _toggleSelected(
    ContactSelectionController controller,
    ContactDirectoryItem member,
  ) {
    final selected = controller.toggle(
      ContactSelectionEntry(
        id: member.userId,
        name: member.name,
        role: member.postName.isEmpty ? member.departmentName : member.postName,
        avatarUrl: member.avatarUrl,
      ),
    );
    if (_isSingleSelection && selected && mounted) {
      Navigator.of(context).pop();
    }
  }

  Color _memberColor(String userId) {
    return getUserAvatarColor(userId);
  }
}

class _DeptNode {
  _DeptNode({required this.department});

  final DepartmentSummary department;
  final List<_DeptNode> children = <_DeptNode>[];
}

class _DepartmentMemberTile extends StatelessWidget {
  const _DepartmentMemberTile({
    required this.member,
    required this.role,
    required this.color,
    required this.onTap,
    required this.selectionMode,
    required this.singleSelection,
    required this.selected,
  });

  final ContactDirectoryItem member;
  final String role;
  final Color color;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool singleSelection;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tile = ContactsChevronTile(
      onTap: onTap,
      leading: ContactsInitialAvatar(
        name: member.name,
        color: color,
        avatarUrl: member.avatarUrl,
        seed: member.userId,
        size: 42,
      ),
      title: member.name,
      subtitle: role,
    );
    if (!selectionMode) {
      return tile;
    }
    return Stack(
      children: [
        Padding(padding: const EdgeInsets.only(right: 48), child: tile),
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: singleSelection
                ? Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF98A2B3),
                  )
                : Checkbox(value: selected, onChanged: (_) => onTap()),
          ),
        ),
      ],
    );
  }
}

class _DepartmentErrorCard extends StatelessWidget {
  const _DepartmentErrorCard({required this.message, required this.onRetry});

  final String message;
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
                  message,
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

class _DepartmentEmptyCard extends StatelessWidget {
  const _DepartmentEmptyCard({required this.message});

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
                style: TextStyle(
                  fontSize: 15,
                  color: ThemeColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
