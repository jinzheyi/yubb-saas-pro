import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_department_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/department_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/controllers/contact_selection_controller.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

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
  String? _selectedDeptId;
  final Set<String> _expandedDeptIds = <String>{};
  Timer? _searchDebounce;
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final deptTreeAsync = ref.watch(myDepartmentTreeProvider);
    final sourceDepartments =
        deptTreeAsync.valueOrNull ?? const <DepartmentSummary>[];
    final departments = _searchedDepartments ?? sourceDepartments;
    final visibleDepartments = _filterDepartments(departments);
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: const ContactsBackButton(),
        centerTitle: true,
        title: Text(strings.contactsDepartments),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeDept?.name ??
                      widget.args.initialDeptName ??
                      strings.contactsDepartments,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索部门成员',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _handleSearchChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
      bottomNavigationBar: widget.args.selectionMode && !_isSingleSelection
          ? Container(
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
      ContactsSectionCard(
        children: [
          for (var index = 0; index < members.length; index++) ...[
            _DepartmentMemberTile(
              member: members[index],
              role: members[index].postName.isEmpty
                  ? members[index].departmentName
                  : members[index].postName,
              color: _memberColor(members[index].name),
              selectionMode: widget.args.selectionMode,
              singleSelection: _isSingleSelection,
              selected: selectionState.isSelected(members[index].userId),
              onTap: () => widget.args.selectionMode
                  ? _toggleSelected(selectionController, members[index])
                  : _openProfile(context, members[index]),
            ),
            if (index != members.length - 1)
              const Divider(
                height: 1,
                indent: 70,
                endIndent: 16,
                color: Color(0xFFF0F2F6),
              ),
          ],
        ],
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
                          color: const Color(0xFF8F96A3),
                        ),
                ),
                Expanded(
                  child: Text(
                    '${node.department.name} ${strings.contactsCountPeople(node.department.memberCount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF3D75F6)
                          : const Color(0xFF202531),
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

  void _handleSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final keyword = value.trim();
      if (keyword.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searching = false;
          _searchedDepartments = null;
          _searchedMembersByDept.clear();
        });
        return;
      }
      unawaited(_runDepartmentSearch(keyword));
    });
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
    final result = await _searchAndFilterDepartments(
      departments: departments,
      keyword: keyword,
      searchedMembersByDept: searchedMembersByDept,
    );
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

  Future<List<DepartmentSummary>> _searchAndFilterDepartments({
    required List<DepartmentSummary> departments,
    required String keyword,
    required Map<String, List<ContactDirectoryItem>> searchedMembersByDept,
  }) async {
    final result = <DepartmentSummary>[];
    final tree = _buildTree(departments);
    for (final node in tree) {
      result.addAll(
        await _searchNode(
          node: node,
          keyword: keyword,
          searchedMembersByDept: searchedMembersByDept,
        ),
      );
    }
    return result;
  }

  Future<List<DepartmentSummary>> _searchNode({
    required _DeptNode node,
    required String keyword,
    required Map<String, List<ContactDirectoryItem>> searchedMembersByDept,
  }) async {
    final matchedMembers = await ref
        .read(contactsRepositoryProvider)
        .getContactsByDepartment(node.department.deptId, keyword: keyword);
    if (matchedMembers.isNotEmpty) {
      searchedMembersByDept[node.department.deptId] = matchedMembers;
    }
    final matchedChildren = <DepartmentSummary>[];
    for (final child in node.children) {
      matchedChildren.addAll(
        await _searchNode(
          node: child,
          keyword: keyword,
          searchedMembersByDept: searchedMembersByDept,
        ),
      );
    }
    if (matchedMembers.isEmpty && matchedChildren.isEmpty) {
      return const <DepartmentSummary>[];
    }
    return <DepartmentSummary>[
      DepartmentSummary(
        deptId: node.department.deptId,
        name: node.department.name,
        memberCount: matchedMembers.length,
        parentDeptId: node.department.parentDeptId,
        sort: node.department.sort,
      ),
      ...matchedChildren,
    ];
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
      extra: <String, String>{
        'userId': member.userId,
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

  Color _memberColor(String name) {
    const colors = <Color>[
      Color(0xFF27C38A),
      Color(0xFFFF9AA8),
      Color(0xFFF6D2B3),
      Color(0xFFE97CAB),
      Color(0xFF8FB8F7),
    ];
    return colors[name.hashCode.abs() % colors.length];
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
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ContactsSectionCard(
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                message,
                style: TextStyle(fontSize: 15, color: Color(0xFF8F96A3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
