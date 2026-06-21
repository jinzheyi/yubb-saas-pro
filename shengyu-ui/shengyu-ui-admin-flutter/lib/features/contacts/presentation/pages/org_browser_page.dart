import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/department_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class OrgBrowserPage extends ConsumerStatefulWidget {
  const OrgBrowserPage({super.key, this.args = const ContactPickerArgs()});

  final ContactPickerArgs args;

  @override
  ConsumerState<OrgBrowserPage> createState() => _OrgBrowserPageState();
}

class _OrgBrowserPageState extends ConsumerState<OrgBrowserPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searching = false;
  List<DepartmentSummary>? _searchedDepartments;
  final Map<String, List<ContactDirectoryItem>> _searchedMembersByDept =
      <String, List<ContactDirectoryItem>>{};
  final Map<String, List<ContactDirectoryItem>> _loadedMembersByDept =
      <String, List<ContactDirectoryItem>>{};
  final Set<String> _loadingDeptIds = <String>{};
  final Set<String> _expandedIds = <String>{'root'};

  bool get _isSingleSelection =>
      widget.args.selectionMode && widget.args.selectionLimit == 1;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final orgAsync = ref.watch(organizationTreeProvider);
    final selectionState = ref.watch(contactSelectionControllerProvider);
    final selectionController = ref.read(
      contactSelectionControllerProvider.notifier,
    );
    final sourceDepartments =
        orgAsync.valueOrNull ?? const <DepartmentSummary>[];
    final departments = _searchedDepartments ?? sourceDepartments;
    // 搜索模式下直接用搜索结果，不再按部门名过滤
    final visibleDepartments = _searchedDepartments != null
        ? departments
        : _filterDepartments(departments);
    final roots = _buildTree(visibleDepartments);
    final rootCount = roots.fold<int>(
      0,
      (sum, node) => sum + node.department.memberCount,
    );
    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: const ContactsBackButton(),
        centerTitle: true,
        title: Text(strings.contactsOrganization),
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
                          strings.contactsOrganization,
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
                              hintText: '搜索组织架构',
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
                  if (orgAsync.isLoading || _searching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (orgAsync.hasError)
                    _OrgErrorCard(
                      message: orgAsync.error.toString(),
                      onRetry: () => ref.invalidate(organizationTreeProvider),
                    )
                  else if (roots.isEmpty)
                    _OrgEmptyCard(message: strings.contactsOrganizationEmpty)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ContactsSectionCard(
                        children: [
                          _RootHeader(
                            title: '${strings.contactsOrganization} ($rootCount)',
                            expanded: _expandedIds.contains('root'),
                            onTap: () {
                              setState(() {
                                if (_expandedIds.contains('root')) {
                                  _expandedIds.remove('root');
                                } else {
                                  _expandedIds.add('root');
                                }
                              });
                            },
                          ),
                          if (_expandedIds.contains('root'))
                            ..._buildNodes(
                              nodes: roots,
                              selectionState: selectionState,
                              selectionController: selectionController,
                            ),
                        ],
                      ),
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

  void _handleSearch() {
    _searchFocusNode.unfocus();
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = false;
        _searchedDepartments = null;
        _searchedMembersByDept.clear();
      });
      unawaited(_primeExpandedMembers());
      return;
    }
    unawaited(_runSearch(keyword));
  }

  Future<void> _runSearch(String keyword) async {
    final departments = ref.read(organizationTreeProvider).valueOrNull;
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
    // 只用根部门搜一次，后端会自动搜索该部门及其所有子部门
    if (tree.isNotEmpty) {
      final rootDeptId = tree.first.department.deptId;
      final allMembers = await ref
          .read(contactsRepositoryProvider)
          .getContactsByDepartment(rootDeptId, keyword: keyword);
      // 按部门分组
      for (final member in allMembers) {
        final deptId = member.departmentId;
        if (deptId.isNotEmpty) {
          searchedMembersByDept
              .putIfAbsent(deptId, () => <ContactDirectoryItem>[])
              .add(member);
        }
      }
    }
    if (!mounted || _searchController.text.trim() != keyword) {
      return;
    }
    // 构建搜索结果的部门树（只保留有匹配成员的部门）
    final result = _buildSearchTree(departments, searchedMembersByDept);
    setState(() {
      _searching = false;
      _searchedDepartments = result;
      _searchedMembersByDept
        ..clear()
        ..addAll(searchedMembersByDept);
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

  Future<void> _primeExpandedMembers() async {
    final sourceDepartments =
        ref.read(organizationTreeProvider).valueOrNull ??
        const <DepartmentSummary>[];
    final roots = _buildTree(sourceDepartments);
    for (final root in roots) {
      await _ensureMembersForExpandedNodes(root, depth: 0);
    }
  }

  Future<void> _ensureMembersForExpandedNodes(
    _OrgNode node, {
    required int depth,
  }) async {
    final expanded =
        _expandedIds.contains(node.department.deptId) || depth == 0;
    if (!expanded) {
      return;
    }
    await _loadMembersForDept(node.department.deptId);
    for (final child in node.children) {
      await _ensureMembersForExpandedNodes(child, depth: depth + 1);
    }
  }

  Future<void> _loadMembersForDept(String deptId) async {
    if (_loadedMembersByDept.containsKey(deptId) ||
        _loadingDeptIds.contains(deptId) ||
        _searchedDepartments != null) {
      return;
    }
    _loadingDeptIds.add(deptId);
    try {
      final members = await ref
          .read(contactsRepositoryProvider)
          .getContactsByDepartment(deptId);
      if (!mounted) {
        return;
      }
      setState(() {
        _loadedMembersByDept[deptId] = members;
      });
    } finally {
      _loadingDeptIds.remove(deptId);
    }
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

  List<_OrgNode> _buildTree(List<DepartmentSummary> departments) {
    final nodeMap = <String, _OrgNode>{};
    for (final department in departments) {
      nodeMap[department.deptId] = _OrgNode(department: department);
    }
    final roots = <_OrgNode>[];
    for (final node in nodeMap.values) {
      final parent = node.department.parentDeptId == null
          ? null
          : nodeMap[node.department.parentDeptId];
      if (parent == null) {
        roots.add(node);
      } else {
        parent.children.add(node);
      }
    }
    void sortNodes(List<_OrgNode> nodes) {
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

  List<Widget> _buildNodes({
    required List<_OrgNode> nodes,
    required dynamic selectionState,
    required dynamic selectionController,
    int depth = 0,
  }) {
    final widgets = <Widget>[];
    final forceExpandForSearch = _searchController.text.trim().isNotEmpty;
    for (final node in nodes) {
      final expanded =
          forceExpandForSearch ||
          _expandedIds.contains(node.department.deptId) ||
          depth == 0;
      final members =
          _searchedMembersByDept[node.department.deptId] ??
          _loadedMembersByDept[node.department.deptId] ??
          const <ContactDirectoryItem>[];
      final deptSelected = nodeSelectableState(node, members, selectionState);
      widgets.add(
        _OrgDeptTile(
          title: '${node.department.name} (${node.department.memberCount})',
          depth: depth,
          expanded: expanded,
          selectionMode: widget.args.selectionMode,
          singleSelection: _isSingleSelection,
          selected: deptSelected,
          hasChildren: node.children.isNotEmpty,
          onToggleExpand: node.children.isEmpty
              ? null
              : () {
                  unawaited(_loadMembersForDept(node.department.deptId));
                  setState(() {
                    if (expanded) {
                      _expandedIds.remove(node.department.deptId);
                    } else {
                      _expandedIds.add(node.department.deptId);
                    }
                  });
                },
          onTap: () async {
            if (!widget.args.selectionMode) {
              unawaited(_loadMembersForDept(node.department.deptId));
              setState(() {
                if (node.children.isNotEmpty) {
                  if (expanded) {
                    _expandedIds.remove(node.department.deptId);
                  } else {
                    _expandedIds.add(node.department.deptId);
                  }
                }
              });
              return;
            }
            if (_isSingleSelection) {
              unawaited(_loadMembersForDept(node.department.deptId));
              setState(() {
                if (node.children.isNotEmpty) {
                  if (expanded) {
                    _expandedIds.remove(node.department.deptId);
                  } else {
                    _expandedIds.add(node.department.deptId);
                  }
                }
              });
              return;
            }
            final allEntries = await _collectSelectableEntries(node);
            final allIds = allEntries.map((item) => item.id).toList();
            if (deptSelected) {
              selectionController.removeAll(allIds);
            } else {
              selectionController.addAll(allEntries);
            }
          },
        ),
      );
      if (expanded) {
        if (_loadingDeptIds.contains(node.department.deptId) &&
            members.isEmpty &&
            _searchedDepartments == null) {
          widgets.add(
            Padding(
              padding: EdgeInsets.fromLTRB(16 + (depth + 1) * 18, 8, 16, 8),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        for (final member in members) {
          final selected = selectionState.isSelected(member.userId);
          widgets.add(
            _OrgMemberTile(
              member: member,
              depth: depth + 1,
              selectionMode: widget.args.selectionMode,
              singleSelection: _isSingleSelection,
              selected: selected,
              onTap: () => _handleMemberTap(member),
            ),
          );
        }
        if (node.children.isNotEmpty) {
          widgets.addAll(
            _buildNodes(
              nodes: node.children,
              selectionState: selectionState,
              selectionController: selectionController,
              depth: depth + 1,
            ),
          );
        }
      }
    }
    return widgets;
  }

  bool nodeSelectableState(
    _OrgNode node,
    List<ContactDirectoryItem> members,
    dynamic selectionState,
  ) {
    if (members.isNotEmpty &&
        members.every((item) => selectionState.isSelected(item.userId))) {
      return true;
    }
    return false;
  }

  Future<List<ContactSelectionEntry>> _collectSelectableEntries(
    _OrgNode node,
  ) async {
    final result = <ContactSelectionEntry>[];
    Future<void> collect(_OrgNode current) async {
      final members =
          _searchedMembersByDept[current.department.deptId] ??
          await ref
              .read(contactsRepositoryProvider)
              .getContactsByDepartment(current.department.deptId);
      for (final member in members) {
        result.add(
          ContactSelectionEntry(
            id: member.userId,
            name: member.name,
            role: member.postName.trim().isEmpty
                ? member.departmentName
                : member.postName,
            avatarUrl: member.avatarUrl,
          ),
        );
      }
      for (final child in current.children) {
        await collect(child);
      }
    }

    await collect(node);
    return result;
  }

  void _handleMemberTap(ContactDirectoryItem member) {
    if (widget.args.selectionMode) {
      final selected = ref
          .read(contactSelectionControllerProvider.notifier)
          .toggle(
            ContactSelectionEntry(
              id: member.userId,
              name: member.name,
              role: member.postName.trim().isEmpty
                  ? member.departmentName
                  : member.postName,
              avatarUrl: member.avatarUrl,
            ),
          );
      if (_isSingleSelection && selected && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    context.pushNamed(
      RouteNames.contactsProfile,
      pathParameters: <String, String>{'userId': member.userId},
      extra: <String, String>{
        'name': member.name,
        'departmentName': member.departmentName,
      },
    );
  }
}

class _OrgNode {
  _OrgNode({required this.department});

  final DepartmentSummary department;
  final List<_OrgNode> children = <_OrgNode>[];
}

class _RootHeader extends StatelessWidget {
  const _RootHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              color: ThemeColors.chevronColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgDeptTile extends StatelessWidget {
  const _OrgDeptTile({
    required this.title,
    required this.depth,
    required this.expanded,
    required this.selectionMode,
    required this.singleSelection,
    required this.selected,
    required this.hasChildren,
    required this.onTap,
    this.onToggleExpand,
  });

  final String title;
  final int depth;
  final bool expanded;
  final bool selectionMode;
  final bool singleSelection;
  final bool selected;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 + depth * 18, 10, 16, 10),
        child: Row(
          children: [
            if (selectionMode && !singleSelection)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Checkbox(value: selected, onChanged: (_) => onTap()),
              ),
            SizedBox(
              width: 20,
              child: hasChildren
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggleExpand,
                      child: Icon(
                        expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        size: 18,
                        color: ThemeColors.chevronColor(context),
                      ),
                    )
                  : const Icon(
                      Icons.apartment_rounded,
                      size: 16,
                      color: Color(0xFF6FB214),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: expanded ? FontWeight.w600 : FontWeight.w500,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgMemberTile extends StatelessWidget {
  const _OrgMemberTile({
    required this.member,
    required this.depth,
    required this.selectionMode,
    required this.singleSelection,
    required this.selected,
    required this.onTap,
  });

  final ContactDirectoryItem member;
  final int depth;
  final bool selectionMode;
  final bool singleSelection;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 + depth * 18, 8, 16, 8),
        child: Row(
          children: [
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
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
            ContactsInitialAvatar(
              name: member.name,
              avatarUrl: member.avatarUrl,
              color: getUserAvatarColor(member.userId),
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                member.name,
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ),
            Text(
              member.postName.trim().isEmpty
                  ? member.departmentName
                  : member.postName,
              style: TextStyle(
                fontSize: 12,
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgErrorCard extends StatelessWidget {
  const _OrgErrorCard({required this.message, required this.onRetry});

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

class _OrgEmptyCard extends StatelessWidget {
  const _OrgEmptyCard({required this.message});

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
