import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/states/contacts_page_state.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(contactsPageControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(contactsPageControllerProvider);
    final myGroupsAsync = ref.watch(myGroupsProvider);
    // 红点数据源：优先使用 BadgeService 后端推送数据（实时、全局），
    // 兼容本地 myGroups 数据（无网络或首次加载时）
    final badgeState = ref.watch(badgeServiceProvider);
    final backendPending = badgeState.menuBadges[BadgeMenuIds.contactsGroupJoinRequest] ?? 0;
    final localPending = myGroupsAsync.valueOrNull?.any(
          (item) => item.pendingJoinRequestCount > 0,
        ) ??
        false;
    final hasPendingGroupRequest = backendPending > 0 || localPending;

    final sections = _buildSections(state);
    _syncKeyword(state.keyword);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 44,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            strings.contactsTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202531),
                            ),
                          ),
                        ),
                      ),
                      _ContactsSearchBar(
                        controller: _searchController,
                        hintText: strings.searchHint,
                        onChanged: (value) => ref
                            .read(contactsPageControllerProvider.notifier)
                            .updateKeyword(value),
                        onClear: () => ref
                            .read(contactsPageControllerProvider.notifier)
                            .updateKeyword(''),
                        onSearch: _openSearchResult,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref
                        .read(contactsPageControllerProvider.notifier)
                        .refresh(),
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _CategoryGroup(
                          items: [
                            _CategoryEntry(
                              title: strings.contactsMyGroups,
                              icon: AppIconKind.groupsFill,
                              color: const Color(0xFFFB923C),
                              showDot: hasPendingGroupRequest,
                              onTap: () => context.pushNamed(
                                RouteNames.contactsMyGroups,
                              ),
                            ),
                            _CategoryEntry(
                              title: strings.contactsFavorites,
                              icon: AppIconKind.starOutline,
                              color: const Color(0xFFFACC15),
                              onTap: () => context.pushNamed(
                                RouteNames.contactsMyFollowing,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _CategoryGroup(
                          items: [
                            _CategoryEntry(
                              title: strings.contactsOrganization,
                              icon: AppIconKind.tree,
                              color: const Color(0xFF84CC16),
                              onTap: () =>
                                  context.pushNamed(RouteNames.contactsOrg),
                            ),
                            _CategoryEntry(
                              title: strings.contactsDepartments,
                              icon: AppIconKind.apartment,
                              color: const Color(0xFF06B6D4),
                              onTap: () => context.pushNamed(
                                RouteNames.contactsMyDepartment,
                              ),
                            ),
                          ],
                        ),
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _ContactsErrorCard(
                              message: state.errorMessage!,
                              onRetry: () => ref
                                  .read(contactsPageControllerProvider.notifier)
                                  .load(),
                            ),
                          )
                        else ...[
                          for (final section in sections)
                            _ContactSectionBlock(
                              key: _sectionKeys.putIfAbsent(
                                section.indexLabel,
                                GlobalKey.new,
                              ),
                              section: section,
                              onOpenContact: (contact) => context.pushNamed(
                                RouteNames.contactsProfile,
                                pathParameters: <String, String>{
                                  'userId': contact.userId,
                                },
                                extra: <String, String>{
                                  'name': contact.name,
                                  'departmentName': contact.departmentName,
                                },
                              ),
                            ),
                          if (sections.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Text(
                                  strings.contactsListEmpty,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8F96A3),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (sections.isNotEmpty)
              Positioned(
                right: 6,
                top: MediaQuery.of(context).padding.top + 176,
                child: _IndexRail(
                  labels: sections
                      .map((section) => section.indexLabel)
                      .toList(),
                  onTap: _scrollToSection,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _syncKeyword(String keyword) {
    if (_searchController.text == keyword) {
      return;
    }
    _searchController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
  }

  List<_ContactSection> _buildSections(ContactsPageState state) {
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    final groups = <String, List<_ContactItem>>{
      for (final letter in letters) letter: <_ContactItem>[],
    };
    for (final item in state.filteredItems) {
      final letter = _normalizePinyin(item.name, item.pinyin);
      if (!groups.containsKey(letter)) {
        continue;
      }
      groups[letter]!.add(
        _ContactItem(
          userId: item.userId,
          name: item.name,
          departmentName: item.departmentName,
          avatarUrl: item.avatarUrl,
        ),
      );
    }
    return [
      for (final entry in groups.entries)
        if (entry.value.isNotEmpty)
          _ContactSection(
            entry.key,
            entry.value..sort((left, right) => left.name.compareTo(right.name)),
          ),
    ];
  }

  String _normalizePinyin(String name, String rawPinyin) {
    var letter = rawPinyin.trim();
    if (letter.length > 1) {
      letter = letter.substring(0, 1);
    }
    if (letter.isEmpty) {
      return _fallbackLetter(name);
    }
    final normalized = letter.toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(normalized)
        ? normalized
        : _fallbackLetter(name);
  }

  String _fallbackLetter(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'A';
    }
    final firstCode = trimmed.codeUnitAt(0);
    if (firstCode >= 19968 && firstCode <= 40869) {
      final index = (firstCode - 19968) % 26;
      return String.fromCharCode(65 + index);
    }
    final letter = trimmed.substring(0, 1).toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(letter) ? letter : 'A';
  }

  void _scrollToSection(String label) {
    final context = _sectionKeys[label]?.currentContext;
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

  void _openSearchResult() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      return;
    }
    context.pushNamed(RouteNames.contactsSearchResult, extra: keyword);
  }
}

class _ContactsSearchBar extends StatelessWidget {
  const _ContactsSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onSearch,
            child: const Icon(
              ShengyuIconFont.chaxun,
              size: 16,
              color: Color(0xFF98A1B2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF98A1B2),
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF202531)),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    ShengyuIconFont.fasong,
                    size: 16,
                    color: Color(0xFF98A1B2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({required this.items});

  final List<_CategoryEntry> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _CategoryTile(item: items[index]),
            if (index != items.length - 1)
              const Divider(
                height: 1,
                indent: 64,
                endIndent: 0,
                color: Color(0xFFF0F0F0),
              ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item});

  final _CategoryEntry item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(item.icon, size: 18, color: Colors.white),
                ),
                if (item.showDot)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF04438),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 16, color: Color(0xFF202531)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsErrorCard extends StatelessWidget {
  const _ContactsErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: Text(strings.retry)),
        ],
      ),
    );
  }
}

class _ContactSectionBlock extends StatelessWidget {
  const _ContactSectionBlock({
    super.key,
    required this.section,
    required this.onOpenContact,
  });

  final _ContactSection section;
  final ValueChanged<_ContactItem> onOpenContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFF5F7FB),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            section.indexLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8F96A3),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: [
              for (var index = 0; index < section.contacts.length; index++) ...[
                _ContactTile(
                  contact: section.contacts[index],
                  onTap: () => onOpenContact(section.contacts[index]),
                ),
                if (index != section.contacts.length - 1)
                  const Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 0,
                    color: Color(0xFFF0F0F0),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onTap});

  final _ContactItem contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ContactsInitialAvatar(
              name: contact.name,
              color: getUserAvatarColor(contact.userId),
              avatarUrl: contact.avatarUrl,
              size: 40,
              borderRadius: 10,
              fontSize: 15,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF202531),
                    ),
                  ),
                  if (contact.departmentName.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.departmentName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEntry {
  const _CategoryEntry({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.showDot = false,
  });

  final String title;
  final AppIconKind icon;
  final Color color;
  final VoidCallback onTap;
  final bool showDot;
}

class _ContactItem {
  const _ContactItem({
    required this.userId,
    required this.name,
    required this.departmentName,
    required this.avatarUrl,
  });

  final String userId;
  final String name;
  final String departmentName;
  final String avatarUrl;
}

class _ContactSection {
  const _ContactSection(this.indexLabel, this.contacts);

  final String indexLabel;
  final List<_ContactItem> contacts;
}

class _IndexRail extends StatelessWidget {
  const _IndexRail({required this.labels, required this.onTap});

  final List<String> labels;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in labels)
            GestureDetector(
              onTap: () => onTap(label),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202531),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
