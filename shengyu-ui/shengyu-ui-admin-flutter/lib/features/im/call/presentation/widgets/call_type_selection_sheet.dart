import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class CallTypeSelectionSheet extends StatelessWidget {
  const CallTypeSelectionSheet({
    super.key,
    required this.displayName,
    required this.voiceLabel,
    required this.videoLabel,
  });

  final String displayName;
  final String voiceLabel;
  final String videoLabel;

  static Future<CallType?> show(
    BuildContext context, {
    required String displayName,
    required String voiceLabel,
    required String videoLabel,
  }) {
    return showModalBottomSheet<CallType>(
      context: context,
      backgroundColor: ThemeColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CallTypeSelectionSheet(
        displayName: displayName,
        voiceLabel: voiceLabel,
        videoLabel: videoLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.divider(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.callSheetTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              strings.callSheetWithName(displayName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: ThemeColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 14),
            _CallTypeTile(
              icon: Icons.phone_outlined,
              label: voiceLabel,
              onTap: () => Navigator.of(context).pop(CallType.audio),
            ),
            _CallTypeTile(
              icon: Icons.videocam_outlined,
              label: videoLabel,
              onTap: () => Navigator.of(context).pop(CallType.video),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallTypeTile extends StatelessWidget {
  const _CallTypeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Icon(icon, color: ThemeColors.textPrimary(context)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ThemeColors.textPrimary(context),
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ThemeColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
