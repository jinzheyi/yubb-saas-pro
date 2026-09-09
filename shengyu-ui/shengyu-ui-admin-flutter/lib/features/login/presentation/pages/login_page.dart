import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/providers/login_providers.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/states/login_page_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final locale = ref.watch(appLocaleProvider);
    final localeState = ref.watch(appLocaleControllerProvider);
    final state = ref.watch(loginControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A6FF7), Color(0xFFF4F6FA), Color(0xFFF4F6FA)],
            stops: [0, 0.24, 0.24],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _showLanguageSheet(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      icon: const AppIcon(
                        AppIconKind.badge,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        _languageLabel(strings, localeState.languageMode),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '钰信',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: const Color(0xFF246BFD),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              strings.appName,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strings.loginIntro,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              strings.usernamePasswordLogin,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF246BFD,
                                                    ),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              strings.phoneLogin,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    TextField(
                                      controller: _usernameController,
                                      onChanged: ref
                                          .read(
                                            loginControllerProvider.notifier,
                                          )
                                          .updateUsername,
                                      decoration: InputDecoration(
                                        labelText: strings.usernameLabel,
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: AppIcon(
                                            AppIconKind.personOutline,
                                            size: 18,
                                            color: Color(0xFF98A1B2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      onChanged: ref
                                          .read(
                                            loginControllerProvider.notifier,
                                          )
                                          .updatePassword,
                                      decoration: InputDecoration(
                                        labelText: strings.passwordLabel,
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: AppIcon(
                                            AppIconKind.folder,
                                            size: 18,
                                            color: Color(0xFF98A1B2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (state.error != null) ...[
                                      const SizedBox(height: 12),
                                      AppErrorView(
                                        error: state.error,
                                        onRetry: null,
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    FilledButton(
                                      onPressed:
                                          state.status ==
                                              LoginPageStatus.submitting
                                          ? null
                                          : () async {
                                              await ref
                                                  .read(
                                                    loginControllerProvider
                                                        .notifier,
                                                  )
                                                  .submit(locale: locale);
                                              if (!context.mounted) {
                                                return;
                                              }
                                              if (ref
                                                      .read(
                                                        loginControllerProvider,
                                                      )
                                                      .error ==
                                                  null) {
                                                context.goNamed(
                                                  RouteNames.conversations,
                                                );
                                              }
                                            },
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: Text(strings.loginAction),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () => context.pushNamed(
                                        RouteNames.register,
                                      ),
                                      child: const Text('注册/加入企业'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    'Copyright © 2026 钰信',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    final state = ref.read(appLocaleControllerProvider);
    final controller = ref.read(appLocaleControllerProvider.notifier);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(strings.languageSettingsTitle)),
              _LanguageOptionTile(
                title: strings.languageModeSystemTitle,
                description: strings.languageModeSystemDescription,
                selected: state.languageMode == AppLanguageMode.system,
                onTap: () async {
                  await controller.selectLanguageMode(AppLanguageMode.system);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              _LanguageOptionTile(
                title: strings.languageModeZhCnTitle,
                description: strings.languageModeZhCnDescription,
                selected: state.languageMode == AppLanguageMode.zhCn,
                onTap: () async {
                  await controller.selectLanguageMode(AppLanguageMode.zhCn);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              _LanguageOptionTile(
                title: strings.languageModeEnTitle,
                description: strings.languageModeEnDescription,
                selected: state.languageMode == AppLanguageMode.en,
                onTap: () async {
                  await controller.selectLanguageMode(AppLanguageMode.en);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _languageLabel(AppLocalizations strings, AppLanguageMode mode) {
    return switch (mode) {
      AppLanguageMode.system => strings.languageModeSystemTitle,
      AppLanguageMode.zhCn => strings.languageModeZhCnTitle,
      AppLanguageMode.en => strings.languageModeEnTitle,
      AppLanguageMode.ja => strings.languageModeJaTitle,
      AppLanguageMode.ko => strings.languageModeKoTitle,
    };
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(title),
      subtitle: Text(description),
      trailing: selected
          ? const AppIcon(
              AppIconKind.checkCircle,
              size: 20,
              color: Color(0xFF246BFD),
            )
          : null,
    );
  }
}
