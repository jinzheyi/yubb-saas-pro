import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_paths.dart';
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

class _AppBottomNavigationBar extends StatelessWidget {
  const _AppBottomNavigationBar({
    required this.currentLocation,
    required this.strings,
  });

  final String currentLocation;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final items = <_ShellNavItem>[
      _ShellNavItem(
        location: RoutePaths.conversations,
        routeName: RouteNames.conversations,
        icon: AppIconKind.chatOutline,
        activeIcon: AppIconKind.chatFill,
        label: strings.tabConversations,
      ),
      _ShellNavItem(
        location: RoutePaths.contacts,
        routeName: RouteNames.contacts,
        icon: AppIconKind.contactsOutline,
        activeIcon: AppIconKind.contactsFill,
        label: strings.tabContacts,
      ),
      _ShellNavItem(
        location: RoutePaths.workbench,
        routeName: RouteNames.workbench,
        icon: AppIconKind.widgetsOutline,
        activeIcon: AppIconKind.widgetsFill,
        label: strings.tabWorkbench,
      ),
      _ShellNavItem(
        location: RoutePaths.profile,
        routeName: RouteNames.profile,
        icon: AppIconKind.personOutline,
        activeIcon: AppIconKind.personFill,
        label: strings.tabProfile,
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
          AppIcon(
            selected ? item.activeIcon : item.icon,
            size: 24,
            color: color,
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

class _ShellNavItem {
  const _ShellNavItem({
    required this.location,
    required this.routeName,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String location;
  final String routeName;
  final AppIconKind icon;
  final AppIconKind activeIcon;
  final String label;
}
