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
// iOS LIQUID GLASS BAR
// ==================================================================
// What makes it look like iOS 26 / WhatsApp rather than plain blur:
//   1. Vibrancy  — the backdrop is blurred AND colour-boosted, so
//                  what's behind looks rich, not milky.
//   2. Specular  — a light-catching rim: bright at the top edge,
//                  fading round to the bottom, plus a soft sheen.
//   3. The lens  — the selected tab is its own glass bubble that
//                  glides between tabs with a little spring.
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
  static const double _inset = 4;

  /// Saturation matrix (1 = unchanged, >1 = more vivid).
  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
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
        // Shadow that lifts the glass off the page.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .35 : .10),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .2 : .04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            // 1. Vibrancy: boost colour first, then blur it.
            filter: ImageFilter.compose(
              outer: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              inner: ColorFilter.matrix(_saturation(1.9)),
            ),
            child: CustomPaint(
              // 2. Specular rim drawn on top of everything.
              foregroundPainter: _SpecularRimPainter(
                radius: _radius,
                dark: dark,
              ),
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  // Very light tint — mostly see-through.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: dark
                        ? [
                            Colors.white.withValues(alpha: .14),
                            Colors.white.withValues(alpha: .06),
                          ]
                        : [
                            Colors.white.withValues(alpha: .52),
                            Colors.white.withValues(alpha: .30),
                          ],
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final tabWidth = (c.maxWidth - _inset * 2) / items.length;

                    return Stack(
                      children: [
                        // 3. The lens, gliding to the selected tab.
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          left: _inset + tabWidth * currentIndex,
                          top: _inset,
                          bottom: _inset,
                          width: tabWidth,
                          child: _Lens(dark: dark, tint: activeColor),
                        ),

                        // Tabs
                        Padding(
                          padding: const EdgeInsets.all(_inset),
                          child: Row(
                            children: [
                              for (var i = 0; i < items.length; i++)
                                Expanded(
                                  child: _GlassTab(
                                    item: items[i],
                                    selected: i == currentIndex,
                                    activeColor: activeColor,
                                    dark: dark,
                                    onTap: () => onTap(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// LENS (selected-tab bubble)
// ------------------------------------------------------------------

class _Lens extends StatelessWidget {
  const _Lens({required this.dark, required this.tint});

  final bool dark;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        // Brighter glass than the bar, with a whisper of the brand colour.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  Colors.white.withValues(alpha: .22),
                  Colors.white.withValues(alpha: .10),
                ]
              : [
                  Color.alphaBlend(
                    tint.withValues(alpha: .06),
                    Colors.white.withValues(alpha: .92),
                  ),
                  Color.alphaBlend(
                    tint.withValues(alpha: .10),
                    Colors.white.withValues(alpha: .62),
                  ),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? .25 : .9),
          width: .8,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: dark ? .25 : .12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// TAB
// ------------------------------------------------------------------

class _GlassTab extends StatefulWidget {
  const _GlassTab({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.dark,
    required this.onTap,
  });

  final AdaptiveNavItem item;
  final bool selected;
  final Color activeColor;
  final bool dark;
  final VoidCallback onTap;

  @override
  State<_GlassTab> createState() => _GlassTabState();
}

class _GlassTabState extends State<_GlassTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = widget.selected;

    final inactive = widget.dark
        ? Colors.white.withValues(alpha: .75)
        : const Color(0xFF3C3C43).withValues(alpha: .75);
    final color = selected ? widget.activeColor : inactive;

    final icon = selected
        ? (item.iosActiveIcon ?? item.iosIcon ?? item.activeIcon)
        : (item.iosIcon ?? item.icon);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        // Squeeze slightly while pressed, like pressing on glass.
        child: AnimatedScale(
          scale: _pressed ? .9 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: _badged(Icon(icon, size: 23, color: color), item),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -.1,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// SPECULAR RIM
// ------------------------------------------------------------------
// A light-catching edge: bright along the top, almost gone at the
// sides, a faint return glow at the bottom — plus a soft sheen
// across the upper half.

class _SpecularRimPainter extends CustomPainter {
  _SpecularRimPainter({required this.radius, required this.dark});

  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(.5),
      Radius.circular(radius),
    );

    // Rim
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: dark ? .45 : .95),
          Colors.white.withValues(alpha: dark ? .06 : .18),
          Colors.white.withValues(alpha: dark ? .18 : .55),
        ],
        stops: const [0, .55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, rim);

    // Sheen across the top half
    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: dark ? .10 : .35),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * .55), sheen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpecularRimPainter old) =>
      old.dark != dark || old.radius != radius;
}
