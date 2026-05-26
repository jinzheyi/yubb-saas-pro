import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_paths.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
    required this.strings,
  });

  final Widget child;
  final String currentLocation;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final shouldShowBottomNav = _isPrimaryTabLocation(currentLocation);
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: shouldShowBottomNav
          ? _AppBottomNavigationBar(
              currentLocation: currentLocation,
              strings: strings,
            )
          : null,
    );
  }

  bool _isPrimaryTabLocation(String location) {
    return location == RoutePaths.conversations ||
        location == RoutePaths.contacts ||
        location == RoutePaths.workbench ||
        location == RoutePaths.profile;
  }
}

class _AppBottomNavigationBar extends ConsumerWidget {
  const _AppBottomNavigationBar({
    required this.currentLocation,
    required this.strings,
  });

  final String currentLocation;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeState = ref.watch(badgeServiceProvider);

    final items = <_ShellNavItem>[
      _ShellNavItem(
        location: RoutePaths.conversations,
        routeName: RouteNames.conversations,
        icon: AppIconKind.chatOutline,
        activeIcon: AppIconKind.chatFill,
        label: strings.tabConversations,
        badgeCount: badgeState.conversationsTabBadge,
      ),
      _ShellNavItem(
        location: RoutePaths.contacts,
        routeName: RouteNames.contacts,
        icon: AppIconKind.contactsOutline,
        activeIcon: AppIconKind.contactsFill,
        label: strings.tabContacts,
        badgeCount: badgeState.contactsTabBadge,
      ),
      _ShellNavItem(
        location: RoutePaths.workbench,
        routeName: RouteNames.workbench,
        icon: AppIconKind.widgetsOutline,
        activeIcon: AppIconKind.widgetsFill,
        label: strings.tabWorkbench,
        badgeCount: badgeState.workbenchTabBadge,
      ),
      _ShellNavItem(
        location: RoutePaths.profile,
        routeName: RouteNames.profile,
        icon: AppIconKind.personOutline,
        activeIcon: AppIconKind.personFill,
        label: strings.tabProfile,
        badgeCount: 0,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE2E7EF))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _BottomNavButton(
                    item: item,
                    selected: currentLocation == item.location,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.item, required this.selected});

  final _ShellNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : const Color(0xFF8F96A3);
    return InkWell(
      onTap: () => context.goNamed(item.routeName),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AppIcon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: color,
              ),
              if (item.badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -10,
                  child: _Badge(count: item.badgeCount),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 角标组件，参考微信样式
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF54A45),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.location,
    required this.routeName,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final String location;
  final String routeName;
  final AppIconKind icon;
  final AppIconKind activeIcon;
  final String label;
  final int badgeCount;
}
