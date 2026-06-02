import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/session_cleanup_service.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/primary_page_scaffold.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final session = ref.watch(authSessionProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    if (!session.isAuthenticated) {
      return _buildUnauthenticatedView(context, strings);
    }

    if (profileAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profileAsync.hasError) {
      return _buildErrorView(ref, context, strings, session);
    }

    final profile = profileAsync.valueOrNull;
    if (profile == null || profile.userId.isEmpty) {
      return _buildErrorView(ref, context, strings, session);
    }

    final username = profile.nickname.isNotEmpty
        ? profile.nickname
        : session.userId;
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
              avatarUrl: profile.avatarUrl,
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
                    final cleanupService = ref.read(sessionCleanupServiceProvider);
                    await cleanupService.clearAndRedirectToLogin(
                      onCleared: () {
                        if (context.mounted) {
                          context.goNamed(RouteNames.login);
                        }
                      },
                    );
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

  String _buildSummary(dynamic strings, UserProfile profile) {
    final post = profile.postName.isNotEmpty
        ? profile.postName
        : strings.profilePostFallback;
    final dept = profile.departmentName.isNotEmpty
        ? profile.departmentName
        : strings.profileDepartmentFallback;
    return '$post, $dept';
  }

  String _buildSecondaryLine(UserProfile profile) {
    final mobile = profile.mobile.trim();
    if (mobile.isNotEmpty) {
      return mobile;
    }
    final email = profile.email.trim();
    if (email.isNotEmpty) {
      return email;
    }
    return '';
  }

  Widget _buildErrorView(
    WidgetRef ref,
    BuildContext context,
    dynamic strings,
    AuthSession session,
  ) {
    return ColoredBox(
      color: const Color(0xFFF5F7FB),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProfileProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(
              username: session.userId.isNotEmpty
                  ? session.userId
                  : strings.profileUnknownUser,
              summary: '',
              secondaryLine: '',
              avatarUrl: null,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                strings.profileLoadError,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE54D4F),
                ),
              ),
            ),
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
                    final cleanupService = ref.read(sessionCleanupServiceProvider);
                    await cleanupService.clearAndRedirectToLogin(
                      onCleared: () {
                        if (context.mounted) {
                          context.goNamed(RouteNames.login);
                        }
                      },
                    );
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

  Widget _buildUnauthenticatedView(
    BuildContext context,
    dynamic strings,
  ) {
    return ColoredBox(
      color: const Color(0xFFF5F7FB),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 64, color: Color(0xFFB0B0B0)),
            const SizedBox(height: 16),
            Text(
              strings.profileUnknownUser,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    if (context.mounted) {
                      context.goNamed(RouteNames.login);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D6FF5),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    strings.loginAction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
    return AppAvatar(
      name: name,
      avatarUrl: avatarUrl,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      size: 56,
      borderRadius: 14,
      fontSize: fontSize,
      textColor: Colors.white,
    );
  }
}
