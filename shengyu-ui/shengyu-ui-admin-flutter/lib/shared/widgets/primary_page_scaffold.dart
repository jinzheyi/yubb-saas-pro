import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class PrimaryPageScaffold extends StatelessWidget {
  const PrimaryPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.searchBar,
    this.headerBottomSpacing = 12,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? searchBar;
  final double headerBottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF202531),
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          if (searchBar != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: searchBar!,
            ),
          ],
          SizedBox(height: headerBottomSpacing),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class PrimarySearchBar extends StatelessWidget {
  const PrimarySearchBar({super.key, required this.hintText, this.onTap});

  final String hintText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F8),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const AppIcon(
                AppIconKind.search,
                size: 19,
                color: Color(0xFF98A1B2),
              ),
              const SizedBox(width: 8),
              Text(
                hintText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF98A1B2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final AppIconKind icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Material(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 32,
            height: 32,
            child: AppIcon(icon, size: 19, color: const Color(0xFF202531)),
          ),
        ),
      ),
    );
  }
}

class PrimarySectionCard extends StatelessWidget {
  const PrimarySectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A162033),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PrimaryShortcutItem {
  const PrimaryShortcutItem({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
  });

  final Object icon;
  final String label;
  final Color color;
  final Color? iconColor;
}

class PrimaryShortcutStrip extends StatelessWidget {
  const PrimaryShortcutStrip({
    super.key,
    required this.items,
    this.onTapItem,
    this.height = 82,
    this.horizontalPadding = 16,
  });

  final List<PrimaryShortcutItem> items;
  final ValueChanged<PrimaryShortcutItem>? onTapItem;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: onTapItem == null ? null : () => onTapItem!(item),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: _buildIconWidget(
                      item.icon,
                      size: 23,
                      color: item.iconColor ?? const Color(0xFF697386),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF697386),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemCount: items.length,
      ),
    );
  }
}

class PrimaryMenuSection extends StatelessWidget {
  const PrimaryMenuSection({
    super.key,
    required this.children,
    this.indent = 64,
    this.endIndent = 20,
  });

  final List<Widget> children;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                indent: indent,
                endIndent: endIndent,
                color: const Color(0xFFF0F2F6),
              ),
          ],
        ],
      ),
    );
  }
}

class PrimaryMenuTile extends StatelessWidget {
  const PrimaryMenuTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.onTap,
    this.horizontalPadding = 20,
    this.verticalPadding = 16,
    this.iconBoxSize = 30,
    this.iconSize = 18,
    this.iconBorderRadius = 8,
  });

  final Object icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconBoxSize;
  final double iconSize;
  final double iconBorderRadius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(iconBorderRadius),
              ),
              alignment: Alignment.center,
              child: _buildIconWidget(
                icon,
                size: iconSize,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF202531),
                ),
              ),
            ),
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

class PrimaryInitialAvatar extends StatelessWidget {
  const PrimaryInitialAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 40,
    this.borderRadius = 10,
    this.fontSize = 16,
    this.textColor = Colors.white,
  });

  final String name;
  final Color color;
  final double size;
  final double borderRadius;
  final double fontSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
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
          color: textColor,
        ),
      ),
    );
  }
}

class PrimaryIndexedSectionHeader extends StatelessWidget {
  const PrimaryIndexedSectionHeader({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 6),
  });

  final String label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F7FB),
      padding: padding,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8F96A3),
        ),
      ),
    );
  }
}

class PrimaryInfoBanner extends StatelessWidget {
  const PrimaryInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.iconColor = const Color(0xFF2F6BFF),
    this.iconBackgroundColor = const Color(0xFFEEF3FF),
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE7EBF2),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12,
    this.messageMaxLines = 1,
  });

  final Object icon;
  final String message;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final int messageMaxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: _buildIconWidget(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: messageMaxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7380),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryIconGridItem {
  const PrimaryIconGridItem({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final Object icon;
  final Color color;
}

class PrimarySectionHeader extends StatelessWidget {
  const PrimarySectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202531),
            ),
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class PrimaryIconGridSection extends StatelessWidget {
  const PrimaryIconGridSection({
    super.key,
    required this.title,
    required this.items,
    this.trailing,
    this.onTapItem,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 18),
  });

  final String title;
  final List<PrimaryIconGridItem> items;
  final Widget? trailing;
  final ValueChanged<PrimaryIconGridItem>? onTapItem;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return PrimarySectionCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimarySectionHeader(title: title, trailing: trailing),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _PrimaryIconGridTile(
                item: item,
                onTap: onTapItem == null ? null : () => onTapItem!(item),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrimaryIconGridTile extends StatelessWidget {
  const _PrimaryIconGridTile({required this.item, this.onTap});

  final PrimaryIconGridItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: _buildIconWidget(item.icon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202531),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildIconWidget(
  Object icon, {
  required double size,
  required Color color,
}) {
  if (icon is AppIconKind) {
    return AppIcon(icon, size: size, color: color);
  }
  if (icon is IconData) {
    return Icon(icon, size: size, color: color);
  }
  return SizedBox(width: size, height: size);
}
