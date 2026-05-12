import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ContactsBackButton extends StatelessWidget {
  const ContactsBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: const AppIcon(
        AppIconKind.chevronLeft,
        size: 20,
        color: Color(0xFF202531),
      ),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}

class ContactsSectionCard extends StatelessWidget {
  const ContactsSectionCard({
    super.key,
    this.title,
    required this.children,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202531),
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

class ContactsChevronTile extends StatelessWidget {
  const ContactsChevronTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            const AppIcon(
              AppIconKind.chevronRight,
              color: Color(0xFFB8C0CC),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class ContactsLabelValueTile extends StatelessWidget {
  const ContactsLabelValueTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8F96A3)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF202531),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactsInitialAvatar extends StatelessWidget {
  const ContactsInitialAvatar({
    super.key,
    required this.name,
    required this.color,
    this.avatarUrl,
    this.size = 40,
    this.borderRadius = 10,
    this.fontSize = 16,
  });

  final String name;
  final Color color;
  final String? avatarUrl;
  final double size;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = avatarUrl?.trim() ?? '';
    if (resolvedAvatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          resolvedAvatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
