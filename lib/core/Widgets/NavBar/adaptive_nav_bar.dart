import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ==================================================================
// ADAPTIVE NAV BAR
// ==================================================================
// iOS / macOS      → CupertinoTabBar (thin, translucent, small labels)
// Android / others → Material 3 NavigationBar (pill indicator)
//
// To preview the iOS look on Android, set
//   ThemeData(platform: TargetPlatform.iOS)
// in MaterialApp while developing.
// ==================================================================

class AdaptiveNavItem {
  const AdaptiveNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.iosIcon,
    this.iosActiveIcon,
    this.badge = 0,
    this.badgeColor,
  });

  final String label;

  /// Material icons (Android).
  final IconData icon;
  final IconData activeIcon;

  /// Cupertino icons (iOS). Falls back to the Material ones.
  final IconData? iosIcon;
  final IconData? iosActiveIcon;

  /// Shows a count when > 0.
  final int badge;
  final Color? badgeColor;
}

bool isCupertino(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

class AdaptiveNavBar extends StatelessWidget {
  const AdaptiveNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = const Color(0xFF091993),
    this.indicatorColor,
  });

  final List<AdaptiveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;

  /// Android pill colour. Defaults to a light tint of [activeColor].
  final Color? indicatorColor;

  Widget _icon(IconData icon, AdaptiveNavItem item, {Color? color}) {
    final child = Icon(icon, color: color);
    if (item.badge <= 0) return child;

    return Badge(
      backgroundColor: item.badgeColor,
      label: Text(item.badge > 99 ? '99+' : '${item.badge}'),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------------
    // iOS
    // ---------------------------------------------------------------
    if (isCupertino(context)) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        activeColor: activeColor,
        inactiveColor: CupertinoColors.systemGrey,
        iconSize: 26,
        height: 54,
        items: [
          for (final item in items)
            BottomNavigationBarItem(
              label: item.label,
              icon: _icon(item.iosIcon ?? item.icon, item),
              activeIcon: _icon(
                item.iosActiveIcon ?? item.iosIcon ?? item.activeIcon,
                item,
              ),
            ),
        ],
      );
    }

    // ---------------------------------------------------------------
    // ANDROID
    // ---------------------------------------------------------------
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: indicatorColor ?? activeColor.withValues(alpha: .12),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final item in items)
            NavigationDestination(
              label: item.label,
              icon: _icon(item.icon, item),
              selectedIcon: _icon(item.activeIcon, item, color: activeColor),
            ),
        ],
      ),
    );
  }
}
