import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/features/update/presentation/providers/update_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    final updateInfo = ref.watch(updateControllerProvider).valueOrNull;
    final hasUpdate = updateInfo?.hasUpdate == true;
    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(strings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 24),
        children: [
          if (profile != null)
            _SettingsProfileCard(
              profile: profile,
              onTapAvatar: () => _showAvatarActionSheet(context, ref),
            )
          else if (profileAsync.hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                profileAsync.error.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: ThemeColors.errorText(context),
                ),
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
                icon: Icons.devices_outlined,
                iconColor: const Color(0xFF34C759),
                title: strings.deviceListTitle,
                onTap: () => context.pushNamed(RouteNames.deviceList),
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),
              _SettingsNavTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: strings.profilePrivacy,
              ),
              _SettingsNavTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF8F96A3),
                title: strings.settingsAboutApp,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasUpdate)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5484D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasUpdate) const SizedBox(width: 8),
                    Text(
                      strings.settingsVersionValue,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                onTap: () => context.pushNamed(RouteNames.aboutApp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 弹出头像操作面板
  Future<void> _showAvatarActionSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final strings = AppLocalizations.of(context);
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final hasAvatar = profile != null && profile.avatarUrl.isNotEmpty;

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Material(
          color: ThemeColors.scaffoldBg(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF3D6FF5),
                ),
                title: Text(
                  hasAvatar
                      ? strings.profileReuploadAvatar
                      : strings.profileUploadAvatar,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(context, ref);
                },
              ),
              if (hasAvatar) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFF4B4B),
                  ),
                  title: Text(
                    strings.profileRemoveCustomAvatar,
                    style: const TextStyle(color: Color(0xFFFF4B4B)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmRemoveAvatar(context, ref);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) return;
    final fileName = picked.name.isNotEmpty ? picked.name : 'avatar.jpg';

    if (!context.mounted) return;
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Consumer(
          builder: (dialogContext, ref, _) {
            final uploadState = ref.watch(avatarUploadStateProvider);
            return Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.surface(dialogContext),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (uploadState.isUploading) ...[
                      CircularProgressIndicator(
                        value: uploadState.progress > 0
                            ? uploadState.progress
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(strings.profileAvatarUploading),
                    ] else ...[
                      const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Color(0xFF07C160),
                      ),
                      const SizedBox(height: 16),
                      Text(strings.profileAvatarUploadSuccess),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    final success = await ref
        .read(avatarUploadStateProvider.notifier)
        .upload(fileName: fileName, bytes: bytes);

    // 关闭进度对话框
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? strings.profileAvatarUploadSuccess
                : strings.profileAvatarUploadFailed,
          ),
          backgroundColor: success
              ? const Color(0xFF07C160)
              : const Color(0xFFFF4B4B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await dialogFuture.catchError((_) {});
  }

  Future<void> _confirmRemoveAvatar(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.profileConfirmRemoveAvatar),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4B4B),
            ),
            child: Text(strings.confirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final success = await ref.read(avatarUploadStateProvider.notifier).delete();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? strings.profileAvatarRemoveSuccess
                : strings.profileAvatarRemoveFailed,
          ),
          backgroundColor: success
              ? const Color(0xFF07C160)
              : const Color(0xFFFF4B4B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await dialogFuture.catchError((_) {});
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ThemeColors.surface(context),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: ThemeColors.divider(context),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard({
    required this.profile,
    required this.onTapAvatar,
  });

  final UserProfile profile;
  final VoidCallback onTapAvatar;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (profile.departmentName.trim().isNotEmpty)
        profile.departmentName.trim(),
      if (profile.postName.trim().isNotEmpty) profile.postName.trim(),
      if (profile.mobile.trim().isNotEmpty) profile.mobile.trim(),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ThemeColors.surface(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onTapAvatar,
                child: Stack(
                  children: [
                    AppAvatar(
                      name: profile.nickname,
                      avatarUrl: profile.avatarUrl.isNotEmpty
                          ? profile.avatarUrl
                          : null,
                      seed: profile.userId,
                      size: 56,
                      borderRadius: 14,
                      fontSize: 18,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D6FF5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname.trim().isEmpty
                          ? '--'
                          : profile.nickname.trim(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parts.isEmpty ? '--' : parts.join(' · '),
                      style: TextStyle(
                        fontSize: 13,
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: ThemeColors.chevronColor(context),
              ),
          ],
        ),
      ),
    );
  }
}
