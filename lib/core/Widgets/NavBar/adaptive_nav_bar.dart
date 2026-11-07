import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

// ==================================================================
// ADAPTIVE NAV BAR
// ==================================================================
// iOS / macOS      → floating frosted-glass bar (content scrolls
//                    underneath and shows through, blurred)
// Android / others → Material 3 NavigationBar
//
// For the glass to show anything, the page's Scaffold needs:
//   extendBody: isCupertino(context)
// and scrolling lists should end with:
//   bottom: <your padding> + glassBottomInset(context)
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

/// Extra bottom space a scrolling list needs so its last item can
/// scroll clear of the floating glass bar. 0 on Android.
///
/// With `extendBody: true`, Scaffold reports the bar's height as
/// bottom padding to everything inside the body.
double glassBottomInset(BuildContext context) =>
    isCupertino(context) ? MediaQuery.paddingOf(context).bottom : 0;

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

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return _GlassTabBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        activeColor: activeColor,
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
              icon: _badged(Icon(item.icon), item),
              selectedIcon: _badged(
                Icon(item.activeIcon, color: activeColor),
                item,
              ),
            ),
        ],
      ),
    );
  }
}

Widget _badged(Widget icon, AdaptiveNavItem item) {
  if (item.badge <= 0) return icon;
  return Badge(
    backgroundColor: item.badgeColor,
    label: Text(item.badge > 99 ? '99+' : '${item.badge}'),
    child: icon,
  );
}

// ==================================================================
// iOS GLASS BAR
// ==================================================================

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.activeColor,
  });

  final List<AdaptiveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;

  static const double _height = 64;
  static const double _radius = 32;

  @override
  Widget build(BuildContext context) {
    // Sit just above the home indicator.
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        safeBottom > 0 ? safeBottom - 6 : 14,
      ),
      child: DecoratedBox(
        // Soft shadow outside the glass.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: _height,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                // Frosted tint: lighter at the top, like light hitting glass.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          Colors.white.withValues(alpha: .16),
                          Colors.white.withValues(alpha: .08),
                        ]
                      : [
                          Colors.white.withValues(alpha: .78),
                          Colors.white.withValues(alpha: .58),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? .18 : .75),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _GlassTab(
                        item: items[i],
                        selected: i == currentIndex,
                        activeColor: activeColor,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final AdaptiveNavItem item;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.grey.shade700;
    final color = selected ? activeColor : inactive;
    final icon = selected
        ? (item.iosActiveIcon ?? item.iosIcon ?? item.activeIcon)
        : (item.iosIcon ?? item.icon);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            // Selected tab gets its own tinted "lens".
            color: selected
                ? activeColor.withValues(alpha: .12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: _badged(Icon(icon, size: 23, color: color), item),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}