import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_department_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_profile.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contact_selection_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class SelectContactCardPage extends ConsumerStatefulWidget {
  const SelectContactCardPage({super.key});

  @override
  ConsumerState<SelectContactCardPage> createState() =>
      _SelectContactCardPageState();
}

class _SelectContactCardPageState extends ConsumerState<SelectContactCardPage> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<ContactDirectoryItem> _contacts = const <ContactDirectoryItem>[];
  final Map<String, ContactCardSharePayload> _payloadCache =
      <String, ContactCardSharePayload>{};

  @override
  void initState() {
    super.initState();
    ref.read(contactSelectionControllerProvider.notifier).start(limit: 1);
    Future.microtask(_loadContacts);
  }

  @override
  void dispose() {
    ref.read(contactSelectionControllerProvider.notifier).end();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final selectionState = ref.watch(contactSelectionControllerProvider);
    final selectedEntry = selectionState.entries.isEmpty
        ? null
        : selectionState.entries.values.first;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leadingWidth: 68,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF202531),
            padding: const EdgeInsets.only(left: 8),
          ),
          icon: const AppIcon(
            AppIconKind.chevronLeft,
            size: 22,
            color: Color(0xFF202531),
          ),
          label: Text(
            strings.backAction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(strings.chatSelectContactCardTitle),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, strings, selectionState)),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFECEFF5))),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedEntry == null
                      ? strings.chatSelectContactCardPlaceholder
                      : strings.chatSelectContactCardSelected(
                          selectedEntry.name,
                        ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: selectionState.count == 0 || _submitting
                        ? null
                        : _confirmSelection,
                    child: Text(strings.confirmAction),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations strings,
    dynamic selectionState,
  ) {
    if (_loading) {
      return Center(child: Text(strings.chatSelectContactCardLoading));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _loadContacts,
                child: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _CategorySection(
          items: [
            _CategoryItem(
              icon: AppIconKind.groupsFill,
              label: strings.contactsMyGroups,
              color: const Color(0xFFFFB347),
              onTap: () => _openCategory(
                RouteNames.contactsMyGroups,
                const ContactPickerArgs(selectionMode: true, selectionLimit: 1),
              ),
            ),
            _CategoryItem(
              icon: AppIconKind.starOutline,
              label: strings.contactsFavorites,
              color: const Color(0xFF246BFD),
              onTap: () => _openCategory(
                RouteNames.contactsMyFollowing,
                const ContactPickerArgs(selectionMode: true, selectionLimit: 1),
              ),
            ),
            _CategoryItem(
              icon: AppIconKind.tree,
              label: strings.contactsOrganization,
              color: const Color(0xFF10B981),
              onTap: () => _openCategory(
                RouteNames.contactsOrg,
                const ContactPickerArgs(selectionMode: true, selectionLimit: 1),
              ),
            ),
            _CategoryItem(
              icon: AppIconKind.apartment,
              label: strings.contactsDepartments,
              color: const Color(0xFF8F4CFF),
              onTap: () => _openCategory(
                RouteNames.contactsMyDepartment,
                const ContactDepartmentArgs(
                  selectionMode: true,
                  selectionLimit: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_contacts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 64),
            alignment: Alignment.center,
            child: Text(
              strings.chatSelectContactCardEmpty,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8F96A3)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var index = 0; index < _contacts.length; index++) ...[
                  ListTile(
                    onTap: () => _toggleLocalSelection(_contacts[index]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: ContactsInitialAvatar(
                      name: _contacts[index].name,
                      color: const Color(0xFF246BFD),
                      avatarUrl: _contacts[index].avatarUrl,
                      size: 42,
                      borderRadius: 21,
                    ),
                    title: Text(
                      _contacts[index].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202531),
                      ),
                    ),
                    subtitle: Text(
                      _contacts[index].postName.trim().isNotEmpty
                          ? _contacts[index].postName
                          : _contacts[index].departmentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                    trailing: Checkbox(
                      value: selectionState.isSelected(_contacts[index].userId),
                      onChanged: (_) => _toggleLocalSelection(_contacts[index]),
                      shape: const CircleBorder(),
                    ),
                  ),
                  if (index != _contacts.length - 1)
                    const Divider(
                      height: 1,
                      indent: 74,
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

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(contactsRepositoryProvider).getContacts();
      if (!mounted) {
        return;
      }
      final filtered = items
          .where((item) => item.userId.trim().isNotEmpty)
          .toList(growable: false);
      _payloadCache
        ..clear()
        ..addEntries(
          filtered.map(
            (item) => MapEntry(
              item.userId,
              ContactCardSharePayload(
                userId: item.userId,
                displayName: item.name,
                departmentName: item.departmentName,
                postName: item.postName,
                avatar: item.avatarUrl,
              ),
            ),
          ),
        );
      setState(() {
        _contacts = filtered;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCategory(String routeName, Object args) async {
    await context.pushNamed(routeName, extra: args);
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleLocalSelection(ContactDirectoryItem item) {
    final controller = ref.read(contactSelectionControllerProvider.notifier);
    final state = ref.read(contactSelectionControllerProvider);
    if (state.isSelected(item.userId)) {
      controller.removeAll(<String>[item.userId]);
      return;
    }
    controller.removeAll(state.entries.keys);
    controller.ensureSelected(
      ContactSelectionEntry(
        id: item.userId,
        name: item.name,
        role: item.postName.trim().isNotEmpty
            ? item.postName
            : item.departmentName,
        avatarUrl: item.avatarUrl,
      ),
    );
  }

  Future<void> _confirmSelection() async {
    final strings = AppLocalizations.of(context);
    final entries = ref.read(contactSelectionControllerProvider).entries;
    final selected = entries.isEmpty ? null : entries.values.first;
    if (selected == null || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final payload =
          _payloadCache[selected.id] ??
          await _resolvePayloadFromProfile(selected.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(payload);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().isEmpty
                ? strings.chatSelectContactCardLoadFailed
                : error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<ContactCardSharePayload> _resolvePayloadFromProfile(
    String userId,
  ) async {
    final ContactProfile profile = await ref.read(
      contactProfileProvider(userId).future,
    );
    return ContactCardSharePayload(
      userId: profile.userId,
      displayName: profile.name,
      departmentName: profile.departmentName,
      postName: profile.postName,
      avatar: profile.avatarUrl,
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.items});

  final List<_CategoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ListTile(
              onTap: items[index].onTap,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: items[index].color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  items[index].icon,
                  size: 22,
                  color: items[index].color,
                ),
              ),
              title: Text(
                items[index].label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF202531),
                ),
              ),
              trailing: const AppIcon(
                AppIconKind.chevronRight,
                size: 18,
                color: Color(0xFFB8C0CC),
              ),
            ),
            if (index != items.length - 1)
              const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: Color(0xFFF0F2F6),
              ),
          ],
        ],
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final AppIconKind icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
