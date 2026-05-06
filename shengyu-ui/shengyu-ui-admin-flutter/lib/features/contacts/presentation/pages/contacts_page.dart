import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/states/contacts_page_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/primary_page_scaffold.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(contactsPageControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(contactsPageControllerProvider);
    final quickEntries = [
      _QuickEntry(
        strings.contactsMyGroups,
        AppIconKind.groupsFill,
        const Color(0xFFFF9738),
        RouteNames.contactsMyGroups,
      ),
      _QuickEntry(
        strings.contactsFavorites,
        AppIconKind.history,
        const Color(0xFFFFCA1F),
        RouteNames.contactsFavorites,
      ),
      _QuickEntry(
        strings.contactsOrganization,
        AppIconKind.widgetsOutline,
        const Color(0xFF8BCF19),
        RouteNames.contactsOrg,
      ),
      _QuickEntry(
        strings.contactsDepartments,
        AppIconKind.contactsFill,
        const Color(0xFF1FB0D8),
        RouteNames.contactsMyDepartment,
      ),
    ];
    final sections = _buildSections(state);

    return PrimaryPageScaffold(
      title: strings.contactsTitle,
      searchBar: PrimarySearchBar(
        hintText: strings.searchHint,
        onTap: () => _showSearchSheet(context),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(contactsPageControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                PrimaryMenuSection(
                  indent: 16,
                  endIndent: 16,
                  children: [
                    for (final entry in quickEntries)
                      PrimaryMenuTile(
                        icon: entry.icon,
                        iconColor: entry.color,
                        title: entry.title,
                        horizontalPadding: 16,
                        iconBoxSize: 34,
                        iconSize: 18,
                        onTap: () {
                          final routeName = entry.routeName;
                          if (routeName == null) {
                            return;
                          }
                          context.pushNamed(routeName);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      section: section,
                      onOpenContact: (contact) =>
                          _openContactActions(context, contact),
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
          if (sections.isNotEmpty)
            Positioned(
              right: 4,
              top: 182,
              child: _IndexRail(
                labels: sections.map((section) => section.indexLabel).toList(),
              ),
            ),
        ],
      ),
    );
  }

  List<_ContactSection> _buildSections(ContactsPageState state) {
    final sections = <String, List<_ContactItem>>{};
    for (final item in state.filteredItems) {
      final trimmedName = item.name.trim();
      final key = trimmedName.isEmpty
          ? '#'
          : trimmedName.substring(0, 1).toUpperCase();
      sections
          .putIfAbsent(key, () => <_ContactItem>[])
          .add(
            _ContactItem(
              item.userId,
              item.name,
              item.departmentName,
              item.avatarUrl,
            ),
          );
    }
    final keys = sections.keys.toList()..sort();
    return [for (final key in keys) _ContactSection(key, sections[key]!)];
  }

  void _openContactActions(BuildContext context, _ContactItem contact) {
    final strings = ref.read(appStringsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(
                  AppIconKind.personOutline,
                  size: 20,
                  color: Color(0xFF202531),
                ),
                title: Text(strings.groupSettingsViewProfile),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.pushNamed(
                    RouteNames.contactsProfile,
                    extra: <String, String>{
                      'userId': contact.userId,
                      'name': contact.name,
                      'departmentName': contact.departmentName,
                    },
                  );
                },
              ),
              ListTile(
                leading: const AppIcon(
                  AppIconKind.chatOutline,
                  size: 20,
                  color: Color(0xFF202531),
                ),
                title: Text(strings.groupSettingsSendMessage),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    final conversation = await ref.read(
                      directConversationProvider(contact.userId).future,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    context.pushNamed(
                      RouteNames.chat,
                      extra: ChatEntryArgs.latest(
                        chatId: conversation.chatId,
                        conversationType: ConversationType.direct,
                        targetId: conversation.targetId,
                        title: conversation.title.trim().isEmpty
                            ? contact.name
                            : conversation.title.trim(),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    _showComingSoon(context, error.toString());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSearchSheet(BuildContext context) async {
    final strings = ref.read(appStringsProvider);
    final controller = TextEditingController(
      text: ref.read(contactsPageControllerProvider).keyword,
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: strings.contactsSearchInputHint,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppIcon(
                        AppIconKind.search,
                        size: 18,
                        color: Color(0xFF98A1B2),
                      ),
                    ),
                  ),
                  onChanged: ref
                      .read(contactsPageControllerProvider.notifier)
                      .updateKeyword,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final keyword = controller.text.trim();
                      ref
                          .read(contactsPageControllerProvider.notifier)
                          .updateKeyword(keyword);
                      Navigator.of(context).pop();
                      if (keyword.isNotEmpty) {
                        context.pushNamed(
                          RouteNames.contactsSearchResult,
                          extra: keyword,
                        );
                      }
                    },
                    child: Text(strings.groupSettingsDone),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
  }
}

class _ContactsErrorCard extends StatelessWidget {
  const _ContactsErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PrimaryMenuSection(
      indent: 0,
      endIndent: 0,
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
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
    );
  }
}

class _ContactSectionBlock extends StatelessWidget {
  const _ContactSectionBlock({
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
        PrimaryIndexedSectionHeader(label: section.indexLabel),
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
                    endIndent: 16,
                    color: Color(0xFFF0F2F6),
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ContactsInitialAvatar(
              name: contact.name,
              color: _avatarColor(contact.name),
              avatarUrl: contact.avatarUrl,
              size: 38,
              borderRadius: 8,
              fontSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF202531),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.departmentName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8F96A3),
                    ),
                  ),
                ],
              ),
            ),
            const AppIcon(
              AppIconKind.chevronRight,
              color: Color(0xFFB8C0CC),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(String seed) {
    const colors = <Color>[
      Color(0xFFE97CAB),
      Color(0xFFF6CFA9),
      Color(0xFF93D3A8),
      Color(0xFF8FB8F7),
    ];
    final trimmedSeed = seed.trim();
    final index = trimmedSeed.isEmpty
        ? 0
        : trimmedSeed.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}

class _QuickEntry {
  const _QuickEntry(this.title, this.icon, this.color, this.routeName);

  final String title;
  final AppIconKind icon;
  final Color color;
  final String? routeName;
}

class _ContactItem {
  const _ContactItem(
    this.userId,
    this.name,
    this.departmentName,
    this.avatarUrl,
  );

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
  const _IndexRail({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in labels)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7380),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
