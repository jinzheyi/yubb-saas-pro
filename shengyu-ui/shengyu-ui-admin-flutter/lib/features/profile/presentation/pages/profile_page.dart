import 'dart:async';

import 'package:file_picker/file_picker.dart';
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
              nickname: profile.nickname,
              onTapAvatar: () => _showAvatarActionSheet(context, ref),
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

  /// 弹出头像操作面板（参考 uniappx 老项目）
  Future<void> _showAvatarActionSheet(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final hasAvatar = profile != null && profile.avatarUrl.isNotEmpty;

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF3D6FF5)),
              title: Text(
                hasAvatar ? strings.profileReuploadAvatar : strings.profileUploadAvatar,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(context, ref);
              },
            ),
            if (hasAvatar) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF4B4B)),
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
    );
  }

  /// 选择图片并上传
  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || !context.mounted) {
      return;
    }
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    final fileName = picked.name.isNotEmpty ? picked.name : 'avatar.jpg';

    // 显示上传进度
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (uploadState.isUploading) ...[
                      CircularProgressIndicator(value: uploadState.progress > 0 ? uploadState.progress : null),
                      const SizedBox(height: 16),
                      Text(strings.profileAvatarUploading),
                    ] else ...[
                      const Icon(Icons.check_circle, size: 48, color: Color(0xFF07C160)),
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

    final success = await ref.read(avatarUploadStateProvider.notifier).upload(
      fileName: fileName,
      bytes: bytes,
    );

    // 关闭进度对话框
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (success) {
      if (context.mounted) _showToast(context, strings.profileAvatarUploadSuccess, success: true);
    } else {
      if (context.mounted) _showToast(context, strings.profileAvatarUploadFailed, success: false);
    }

    // 等待 dialogFuture 完成，避免未处理的异常
    await dialogFuture.catchError((_) {});
  }

  /// 确认删除头像
  Future<void> _confirmRemoveAvatar(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF4B4B)),
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

    if (success) {
      _showToast(context, strings.profileAvatarRemoveSuccess, success: true);
    } else {
      _showToast(context, strings.profileAvatarRemoveFailed, success: false);
    }

    await dialogFuture.catchError((_) {});
  }

  void _showToast(BuildContext context, String message, {required bool success}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || message.trim().isEmpty) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CenterToast(message: message, success: success, onDismiss: () => entry.remove()),
    );
    overlay.insert(entry);
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
              nickname: '',
              onTapAvatar: () => _showAvatarActionSheet(context, ref),
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

/// 居中 Toast 提示
class _CenterToast extends StatefulWidget {
  const _CenterToast({required this.message, required this.success, required this.onDismiss});
  final String message;
  final bool success;
  final VoidCallback onDismiss;

  @override
  State<_CenterToast> createState() => _CenterToastState();
}

class _CenterToastState extends State<_CenterToast> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xCC1F2329),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.success ? Icons.check_circle : Icons.error_outline,
                color: widget.success ? const Color(0xFF07C160) : const Color(0xFFFF4B4B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
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
    required this.nickname,
    required this.onTapAvatar,
  });

  final String username;
  final String summary;
  final String secondaryLine;
  final String? avatarUrl;
  final String nickname;
  final VoidCallback onTapAvatar;

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
              GestureDetector(
                onTap: onTapAvatar,
                child: Stack(
                  children: [
                    _ProfileAvatar(
                      name: username,
                      avatarUrl: avatarUrl,
                      fontSize: theme.textTheme.headlineSmall?.fontSize ?? 24,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3D6FF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
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
