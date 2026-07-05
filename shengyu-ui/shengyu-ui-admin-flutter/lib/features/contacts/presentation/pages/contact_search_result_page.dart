import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_search_result.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class ContactSearchResultPage extends ConsumerWidget {
  const ContactSearchResultPage({super.key, required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final resultAsync = ref.watch(contactSearchProvider(keyword));
    final fallbackResult = const ContactSearchResult(
      contacts: [],
      departments: [],
    );

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: const ContactsBackButton(),
        centerTitle: true,
        title: Text(strings.contactsSearchResultTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: ThemeColors.surface(context),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              strings.contactsSearchKeyword(keyword),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (resultAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (resultAsync.hasError)
            _ResultErrorCard(
              message: resultAsync.error.toString(),
              onRetry: () => ref.invalidate(contactSearchProvider(keyword)),
            )
          else ...[
            _ContactResultBlock(
              title: strings.contactsPeopleSectionTitle,
              result: resultAsync.valueOrNull ?? fallbackResult,
            ),
            const SizedBox(height: 10),
            _DepartmentResultBlock(
              title: strings.contactsDepartmentSectionTitle,
              result: resultAsync.valueOrNull ?? fallbackResult,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactResultBlock extends StatelessWidget {
  const _ContactResultBlock({required this.title, required this.result});

  final String title;
  final ContactSearchResult result;

  @override
  Widget build(BuildContext context) {
    final items = result.contacts;
    return ContactsSectionCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      title: title,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              AppLocalizations.of(context).contactsSearchEmpty,
              style: TextStyle(
                fontSize: 13,
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ),
        for (var index = 0; index < items.length; index++) ...[
          ContactsChevronTile(
            onTap: () => context.pushNamed(
              RouteNames.contactsProfile,
              pathParameters: <String, String>{'userId': items[index].userId},
              extra: <String, String>{
                'name': items[index].name,
                'departmentName': items[index].departmentName,
              },
            ),
            leading: ContactsInitialAvatar(
              name: items[index].name,
              color: getUserAvatarColor(items[index].userId),
              seed: items[index].userId,
              avatarUrl: items[index].avatarUrl,
              size: 42,
            ),
            title: items[index].name,
            subtitle: items[index].departmentName,
          ),
          if (index != items.length - 1)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: ThemeColors.divider(context),
            ),
        ],
      ],
    );
  }
}

class _DepartmentResultBlock extends StatelessWidget {
  const _DepartmentResultBlock({required this.title, required this.result});

  final String title;
  final ContactSearchResult result;

  @override
  Widget build(BuildContext context) {
    final items = result.departments;
    return ContactsSectionCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      title: title,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              AppLocalizations.of(context).contactsSearchEmpty,
              style: TextStyle(
                fontSize: 13,
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ),
        for (var index = 0; index < items.length; index++) ...[
          ContactsChevronTile(
            onTap: () => context.pushNamed(
              RouteNames.contactsMyDepartment,
              extra: <String, String>{
                'deptId': items[index].deptId,
                'deptName': items[index].name,
              },
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8FC),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.apartment_rounded,
                color: Color(0xFF1FB0D8),
              ),
            ),
            title: items[index].name,
            subtitle: AppLocalizations.of(
              context,
            ).contactsCountPeople(items[index].memberCount),
          ),
          if (index != items.length - 1)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: ThemeColors.divider(context),
            ),
        ],
      ],
    );
  }
}

class _ResultErrorCard extends StatelessWidget {
  const _ResultErrorCard({required this.message, required this.onRetry});

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
