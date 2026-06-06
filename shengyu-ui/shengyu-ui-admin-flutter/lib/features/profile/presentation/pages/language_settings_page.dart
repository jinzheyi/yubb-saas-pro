import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class LanguageSettingsPage extends ConsumerStatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  ConsumerState<LanguageSettingsPage> createState() =>
      _LanguageSettingsPageState();
}

class _LanguageSettingsPageState
    extends ConsumerState<LanguageSettingsPage> {
  AppLanguageMode? _pendingMode;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(appLocaleControllerProvider);
    final controller = ref.read(appLocaleControllerProvider.notifier);

    final displayMode = _pendingMode ?? state.languageMode;

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

    final hasChanges = _pendingMode != null && _pendingMode != state.languageMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
        title: Text(strings.settingsLanguage),
        actions: [
          TextButton(
            onPressed: hasChanges
                ? () async {
                    await controller.selectLanguageMode(_pendingMode!);
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var index = 0; index < options.length; index++) ...[
                  _LanguageOptionTile(
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
