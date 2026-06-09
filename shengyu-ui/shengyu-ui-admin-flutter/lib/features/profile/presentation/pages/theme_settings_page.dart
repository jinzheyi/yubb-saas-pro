import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_mode_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage> {
  ThemeMode? _pendingMode;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(appThemeControllerProvider);
    final controller = ref.read(appThemeControllerProvider.notifier);
    final brightness = MediaQuery.platformBrightnessOf(context);

    final displayMode = _pendingMode ?? state.themeMode;
    final effectiveBrightness = switch (displayMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => brightness,
    };

    final options = [
      (
        mode: ThemeMode.system,
        title: strings.themeModeSystemTitle,
        description: strings.themeModeSystemDescription,
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

    final hasChanges = _pendingMode != null && _pendingMode != state.themeMode;

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () {
            if (hasChanges) {
              _showCancelConfirm(context);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        centerTitle: true,
        title: Text(strings.settingsThemeMode),
        actions: [
          TextButton(
            onPressed: hasChanges
                ? () async {
                    await controller.selectThemeMode(_pendingMode!);
                    if (mounted) {
                      setState(() {
                        _pendingMode = null;
                      });
                    }
                  }
                : null,
            child: Text(strings.confirmAction),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: ThemeColors.surface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var index = 0; index < options.length; index++) ...[
                  _ThemeOptionTile(
                    title: options[index].title,
                    description: options[index].description,
                    selected: displayMode == options[index].mode,
                    onTap: () {
                      setState(() {
                        _pendingMode = options[index].mode;
                      });
                    },
                  ),
                  if (index != options.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: ThemeColors.divider(context),
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

  void _showCancelConfirm(BuildContext context) {
    final strings = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.cancelAction),
        content: Text(strings.discardChangesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.continueEditAction),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _pendingMode = null;
              });
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: Text(strings.discardAction),
          ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeColors.textSecondary(context),
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
                    child: Text(
                      strings.themePreviewApplyBtn,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
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
