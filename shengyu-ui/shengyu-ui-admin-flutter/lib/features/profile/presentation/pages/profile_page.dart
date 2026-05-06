import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/primary_page_scaffold.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final session = ref.watch(authSessionProvider);
    final authController = ref.read(authSessionProvider.notifier);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    final username = _resolveName(strings, session.userId, profile);
    final summary = _buildSummary(strings, profile);
    final secondaryLine = _buildSecondaryLine(profile);

    return ColoredBox(
      color: const Color(0xFFF5F7FB),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProfileProvider);
          await ref.read(currentUserProfileProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(
              username: username,
              summary: summary,
              secondaryLine: secondaryLine,
              avatarUrl: profile?.avatarUrl,
            ),
            if (profileAsync.hasError)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  profileAsync.error.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE54D4F),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            PrimaryMenuSection(
              children: [
                PrimaryMenuTile(
                  icon: AppIconKind.widgetsOutline,
                  iconColor: const Color(0xFF16B7D7),
                  title: strings.profileThemeSwitch,
                  onTap: () => context.pushNamed(RouteNames.themeSettings),
                ),
                PrimaryMenuTile(
                  icon: AppIconKind.history,
                  iconColor: const Color(0xFFFF972B),
                  title: strings.profileFavorites,
                  onTap: () => context.pushNamed(RouteNames.favorites),
                ),
                PrimaryMenuTile(
                  icon: AppIconKind.sync,
                  iconColor: const Color(0xFFFFB96E),
                  title: strings.profileSectionSettings,
                  onTap: () => context.pushNamed(RouteNames.settings),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () async {
                    await authController.clearSession();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    strings.profileLogout,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4B4B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveName(
    dynamic strings,
    String sessionUserId,
    UserProfile? profile,
  ) {
    if (profile != null && profile.nickname.isNotEmpty) {
      return profile.nickname;
    }
    if (sessionUserId.isNotEmpty) {
      return sessionUserId;
    }
    return strings.profileUnknownUser;
  }

  String _buildSummary(dynamic strings, UserProfile? profile) {
    final post = profile?.postName.isNotEmpty == true
        ? profile!.postName
        : strings.profilePostFallback;
    final dept = profile?.departmentName.isNotEmpty == true
        ? profile!.departmentName
        : strings.profileDepartmentFallback;
    return '$post, $dept';
  }

  String _buildSecondaryLine(UserProfile? profile) {
    final mobile = profile?.mobile.trim() ?? '';
    if (mobile.isNotEmpty) {
      return mobile;
    }
    final email = profile?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email;
    }
    return '';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.username,
    required this.summary,
    required this.secondaryLine,
    required this.avatarUrl,
  });

  final String username;
  final String summary;
  final String secondaryLine;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: const Color(0xFF3D6FF5),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatar(
                name: username,
                avatarUrl: avatarUrl,
                fontSize: theme.textTheme.headlineSmall?.fontSize ?? 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (secondaryLine.isNotEmpty)
                      Text(
                        secondaryLine,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFDDE6FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.avatarUrl,
    required this.fontSize,
  });

  final String name;
  final String? avatarUrl;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = avatarUrl?.trim() ?? '';
    if (resolvedAvatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          resolvedAvatar,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return PrimaryInitialAvatar(
      name: name,
      color: Colors.white.withValues(alpha: 0.2),
      size: 56,
      borderRadius: 14,
      fontSize: fontSize,
    );
  }
}
