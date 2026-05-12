import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class ContactProfilePage extends ConsumerWidget {
  const ContactProfilePage({
    super.key,
    required this.userId,
    required this.name,
    required this.departmentName,
  });

  final String userId;
  final String name;
  final String departmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final profileAsync = userId.isEmpty
        ? null
        : ref.watch(contactProfileProvider(userId));
    final profile = profileAsync?.valueOrNull;
    final placeholder = strings.workbenchMetricPlaceholder;
    final displayName = profile?.name.isNotEmpty == true
        ? profile!.name
        : (name.isNotEmpty ? name : strings.profileUnknownUser);
    final displayDept = profile?.departmentName.isNotEmpty == true
        ? profile!.departmentName
        : departmentName;
    final displayPhone = profile?.phone.isNotEmpty == true
        ? profile!.phone
        : placeholder;
    final displayEmail = profile?.email.isNotEmpty == true
        ? profile!.email
        : placeholder;
    final displayPost = profile?.postName.isNotEmpty == true
        ? profile!.postName
        : placeholder;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: const ContactsBackButton(),
        centerTitle: true,
        title: Text(strings.contactsProfileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (profileAsync?.hasError == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                profileAsync!.error.toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
              ),
            ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              children: [
                ContactsInitialAvatar(
                  name: displayName,
                  color: const Color(0xFFE97CAB),
                  avatarUrl: profile?.avatarUrl,
                  size: 60,
                  borderRadius: 16,
                  fontSize: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202531),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayDept,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ContactsSectionCard(
            children: [
              ContactsLabelValueTile(
                label: strings.contactsPhoneLabel,
                value: displayPhone,
              ),
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFF0F2F6),
              ),
              ContactsLabelValueTile(
                label: strings.contactsEmailLabel,
                value: displayEmail,
              ),
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFF0F2F6),
              ),
              ContactsLabelValueTile(
                label: strings.contactsPostLabel,
                value: displayPost,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton(
              onPressed: userId.isEmpty
                  ? null
                  : () async {
                      try {
                        final conversation = await ref.read(
                          directConversationProvider(userId).future,
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
                                ? displayName
                                : conversation.title.trim(),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
              child: Text(strings.groupSettingsSendMessage),
            ),
          ),
        ],
      ),
    );
  }
}
