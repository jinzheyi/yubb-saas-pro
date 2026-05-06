import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_mode_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(appThemeControllerProvider);
    final controller = ref.read(appThemeControllerProvider.notifier);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final effectiveBrightness = switch (state.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => brightness,
    };

    final options = [
      (
        mode: ThemeMode.system,
        title: strings.languageModeSystemTitle,
        description: strings.languageModeSystemDescription,
      ),
      (
        mode: ThemeMode.light,
        title: strings.themeModeLightTitle,
        description: strings.themeModeLightDescription,
      ),
      (
        mode: ThemeMode.dark,
        title: strings.themeModeDarkTitle,
        description: strings.themeModeDarkDescription,
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
        title: Text(strings.themeSettingsTitle),
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
                  _ThemeOptionTile(
                    title: options[index].title,
                    description: options[index].description,
                    selected: state.themeMode == options[index].mode,
                    onTap: () =>
                        controller.selectThemeMode(options[index].mode),
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
          _ThemePreviewCard(brightness: effectiveBrightness),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
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

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isDark = brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.themePreviewTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF202531),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10151F) : const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF246BFD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A3140)
                              : const Color(0xFFE9EEF7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A3140) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      strings.themePreviewMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF202531),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF246BFD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '立即生效',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
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
