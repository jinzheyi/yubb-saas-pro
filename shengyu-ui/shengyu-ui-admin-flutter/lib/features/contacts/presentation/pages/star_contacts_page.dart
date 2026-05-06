import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class StarContactsPage extends ConsumerWidget {
  const StarContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final contactsAsync = ref.watch(starContactsProvider);

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
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          label: Text(
            strings.backAction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(strings.contactsFavorites),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(starContactsProvider);
          await ref.read(starContactsProvider.future);
        },
        child: contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      strings.contactsFavoritesEmpty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ContactsSectionCard(
                  padding: EdgeInsets.zero,
                  children: [
                    ContactsChevronTile(
                      leading: ContactsInitialAvatar(
                        name: contact.name,
                        color: const Color(0xFFE97CAB),
                        avatarUrl: contact.avatarUrl,
                        size: 44,
                        borderRadius: 12,
                        fontSize: 18,
                      ),
                      title: contact.name,
                      subtitle: contact.departmentName.isEmpty
                          ? null
                          : contact.departmentName,
                      onTap: () => _openActions(context, ref, contact),
                    ),
                  ],
                );
              },
            );
          },
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE54D4F),
                    ),
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    ContactDirectoryItem contact,
  ) {
    final strings = ref.read(appStringsProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
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
                leading: const Icon(Icons.chat_bubble_outline_rounded),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
