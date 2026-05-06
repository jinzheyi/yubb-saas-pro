import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(strings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 24),
        children: [
          if (profile != null)
            _SettingsProfileCard(profile: profile)
          else if (profileAsync.hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                profileAsync.error.toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
              ),
            ),
          if (profileAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          _SettingsGroup(
            children: [
              _SettingsNavTile(
                icon: Icons.palette_outlined,
                iconColor: const Color(0xFF16B7D7),
                title: strings.settingsThemeMode,
                subtitle: strings.settingsThemeModeSummary,
                onTap: () => context.pushNamed(RouteNames.themeSettings),
              ),
              _SettingsNavTile(
                icon: Icons.translate_rounded,
                iconColor: const Color(0xFF246BFD),
                title: strings.settingsLanguage,
                subtitle: strings.settingsLanguageSummary,
                onTap: () => context.pushNamed(RouteNames.languageSettings),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              _SettingsNavTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: strings.profilePrivacy,
              ),
              _SettingsNavTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF8F96A3),
                title: strings.settingsAboutApp,
                trailing: Text(
                  strings.settingsVersionValue,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8F96A3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: Color(0xFFF0F2F6),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (profile.departmentName.trim().isNotEmpty)
        profile.departmentName.trim(),
      if (profile.postName.trim().isNotEmpty) profile.postName.trim(),
      if (profile.mobile.trim().isNotEmpty) profile.mobile.trim(),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.nickname.trim().isEmpty ? '--' : profile.nickname.trim(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202531),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            parts.isEmpty ? '--' : parts.join(' · '),
            style: const TextStyle(fontSize: 13, color: Color(0xFF8F96A3)),
          ),
        ],
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF202531),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8C0CC)),
          ],
        ),
      ),
    );
  }
}
