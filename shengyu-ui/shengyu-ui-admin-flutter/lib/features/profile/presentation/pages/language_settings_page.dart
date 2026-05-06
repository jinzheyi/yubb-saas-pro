import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(appLocaleControllerProvider);
    final controller = ref.read(appLocaleControllerProvider.notifier);

    final options = [
      (
        mode: AppLanguageMode.system,
        title: strings.languageModeSystemTitle,
        description: strings.languageModeSystemDescription,
      ),
      (
        mode: AppLanguageMode.zhCn,
        title: strings.languageModeZhCnTitle,
        description: strings.languageModeZhCnDescription,
      ),
      (
        mode: AppLanguageMode.en,
        title: strings.languageModeEnTitle,
        description: strings.languageModeEnDescription,
      ),
    ];

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
        title: Text(strings.languageSettingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var index = 0; index < options.length; index++) ...[
                  _LanguageOptionTile(
                    title: options[index].title,
                    description: options[index].description,
                    selected: state.languageMode == options[index].mode,
                    onTap: () =>
                        controller.selectLanguageMode(options[index].mode),
                  ),
                  if (index != options.length - 1)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF0F2F6),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  strings.languageEffectiveLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202531),
                  ),
                ),
                const Spacer(),
                Text(
                  state.resolvedTag,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8F96A3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8F96A3),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFF246BFD)
                  : const Color(0xFFC6CCD7),
            ),
          ],
        ),
      ),
    );
  }
}
