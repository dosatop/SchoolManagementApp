import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// ==================================================================
// ADAPTIVE NAV BAR
// ==================================================================
// iOS / macOS      → floating "liquid glass" bar (tap OR slide it)
// Android / others → Material 3 NavigationBar
//
// In the dashboard:
//   Scaffold(
//     extendBody: isCupertino(context),
//     body: SlidingIndexedStack(index: ..., children: [...]),
//     bottomNavigationBar: AdaptiveNavBar(...),
//   )
//
// SlidingIndexedStack slides between pages AND stops every page
// above the floating bar, so nothing is hidden behind it.
//
// Preview the iOS look on Android with
//   ThemeData(platform: TargetPlatform.iOS)
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

// Bar geometry (shared by the bar and the page padding).
const double _kBarHeight = 66;
const double _kBarGap = 12; // breathing room between page and bar

/// Bottom margin under the floating bar (just above the home indicator).
double _barBottomMargin(BuildContext context) {
  final safe = MediaQuery.viewPaddingOf(context).bottom;
  return safe > 0 ? safe - 8 : 14;
}

/// Total space the floating glass bar takes at the bottom of the
/// screen, plus a small gap. 0 on Android.
double glassBarSpace(BuildContext context) => isCupertino(context)
    ? _kBarHeight + _barBottomMargin(context) + _kBarGap
    : 0;

/// Extra bottom space a list needs to clear the glass bar.
/// Returns 0 inside [SlidingIndexedStack] (it already makes the space),
/// so existing `+ glassBottomInset(context)` calls never double up.
double glassBottomInset(BuildContext context) {
  if (context.dependOnInheritedWidgetOfExactType<_GlassSpaceHandled>() !=
      null) {
    return 0;
  }
  return glassBarSpace(context);
}

class _GlassSpaceHandled extends InheritedWidget {
  const _GlassSpaceHandled({required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
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

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return _LiquidGlassBar(
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
// COLOUR MATRIX
// ==================================================================

/// Saturation (1 = unchanged) and brightness (0 = unchanged, ±255).
List<double> _vibrancy(double saturation, [double brightness = 0]) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - saturation;
  return [
    r * i + saturation, g * i, b * i, 0, brightness, //
    r * i, g * i + saturation, b * i, 0, brightness, //
    r * i, g * i, b * i + saturation, 0, brightness, //
    0, 0, 0, 1, 0,
  ];
}

// ==================================================================
// iOS LIQUID GLASS BAR
// ==================================================================
// • Tap a tab → the lens springs there.
// • Slide your finger along the bar → the lens follows, stretching
//   like liquid, then snaps to the nearest tab when you let go.
// ==================================================================

class _LiquidGlassBar extends StatefulWidget {
  const _LiquidGlassBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.activeColor,
  });

  final List<AdaptiveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;

  @override
  State<_LiquidGlassBar> createState() => _LiquidGlassBarState();
}

class _LiquidGlassBarState extends State<_LiquidGlassBar>
    with SingleTickerProviderStateMixin {
  static const double _height = _kBarHeight;
  static const double _radius = _kBarHeight / 2;
  static const double _inset = 4;
  static const double _magnify = 1.28;

  /// Slightly under-damped → a small wobble when the lens lands.
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 24,
  );

  /// Lens position in "tabs" (0 = first tab, 1.5 = between 2nd & 3rd).
  late final AnimationController _pos;

  bool _dragging = false;
  double _dragSpeed = 0; // for the stretch while dragging

  @override
  void initState() {
    super.initState();
    _pos = AnimationController.unbounded(
      vsync: this,
      value: widget.currentIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant _LiquidGlassBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex && !_dragging) {
      _springTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _springTo(int index, [double? velocity]) {
    _pos.animateWith(
      SpringSimulation(
        _spring,
        _pos.value,
        index.toDouble(),
        velocity ?? _pos.velocity,
      ),
    );
  }

  int get _last => widget.items.length - 1;

  // ---------------- slide ----------------

  void _dragStart(DragStartDetails d, double tabWidth) {
    _dragging = true;
    _pos.stop();
    // Jump the lens under the finger so it feels "picked up".
    final under = ((d.localPosition.dx - _inset) / tabWidth - .5);
    _pos.value = under.clamp(0, _last.toDouble());
  }

  void _dragUpdate(DragUpdateDetails d, double tabWidth) {
    final delta = d.delta.dx / tabWidth;
    setState(() {
      _pos.value = (_pos.value + delta).clamp(-.15, _last + .15);
      _dragSpeed = (delta * 60).abs();
    });

    // Switch the page live as the lens crosses into another tab.
    final nearest = _pos.value.round().clamp(0, _last);
    if (nearest != widget.currentIndex) widget.onTap(nearest);
  }

  void _dragEnd(DragEndDetails d, double tabWidth) {
    _dragging = false;
    final velocity = (d.primaryVelocity ?? 0) / tabWidth;

    // A flick carries the lens a little further.
    final target = (_pos.value + velocity * .10).round().clamp(0, _last);

    setState(() => _dragSpeed = 0);
    _springTo(target, velocity);

    if (target != widget.currentIndex) widget.onTap(target);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, _barBottomMargin(context)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .40 : .14),
              blurRadius: 36,
              spreadRadius: -4,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .25 : .05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            // Vivid, deep blur — most of the "liquid" look.
            filter: ImageFilter.compose(
              outer: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              inner: ColorFilter.matrix(_vibrancy(2.2, dark ? -6 : 8)),
            ),
            child: CustomPaint(
              foregroundPainter: _GlassRimPainter(radius: _radius, dark: dark),
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  // Thin tint so what's behind really shows through.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: dark
                        ? [
                            Colors.white.withValues(alpha: .12),
                            Colors.white.withValues(alpha: .04),
                          ]
                        : [
                            Colors.white.withValues(alpha: .42),
                            Colors.white.withValues(alpha: .20),
                          ],
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final tabWidth =
                        (c.maxWidth - _inset * 2) / widget.items.length;

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (d) => _dragStart(d, tabWidth),
                      onHorizontalDragUpdate: (d) => _dragUpdate(d, tabWidth),
                      onHorizontalDragEnd: (d) => _dragEnd(d, tabWidth),
                      child: AnimatedBuilder(
                        animation: _pos,
                        builder: (context, _) {
                          final position = _pos.value;

                          // Stretch with speed: wider + flatter while moving.
                          final speed = _dragging
                              ? _dragSpeed
                              : _pos.velocity.abs();
                          final stretch = (speed / 9).clamp(0.0, 1.0);
                          final scaleX = 1 + .32 * stretch;
                          final scaleY = 1 - .10 * stretch;

                          final lit = position.round().clamp(0, _last);

                          // Lens rectangle (stretched while moving).
                          final rowWidth = tabWidth * widget.items.length;
                          final rowHeight = _height - _inset * 2;
                          final centerX = _inset + tabWidth * (position + .5);
                          final lensRect = Rect.fromCenter(
                            center: Offset(centerX, _height / 2),
                            width: tabWidth * scaleX,
                            height: rowHeight * scaleY,
                          );
                          final lensRadius = lensRect.height / 2;

                          Widget tabsRow({required bool magnified}) => Row(
                            children: [
                              for (var i = 0; i < widget.items.length; i++)
                                Expanded(
                                  child: _GlassTab(
                                    item: widget.items[i],
                                    focus: (1 - (position - i).abs()).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    selected: i == lit,
                                    magnified: magnified,
                                    activeColor: widget.activeColor,
                                    dark: dark,
                                    onTap: () {
                                      if (i != widget.currentIndex) {
                                        widget.onTap(i);
                                      }
                                    },
                                  ),
                                ),
                            ],
                          );

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 1. Normal tabs (fade out under the lens).
                              Padding(
                                padding: const EdgeInsets.all(_inset),
                                child: tabsRow(magnified: false),
                              ),

                              // 2. The glass drop itself.
                              Positioned.fromRect(
                                rect: lensRect,
                                child: IgnorePointer(
                                  child: _Lens(
                                    radius: lensRadius,
                                    dark: dark,
                                    tint: widget.activeColor,
                                  ),
                                ),
                              ),

                              // 3. MAGNIFIED copy of the tabs, seen
                              //    only through the lens.
                              Positioned.fromRect(
                                rect: lensRect,
                                child: IgnorePointer(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      lensRadius,
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: _inset - lensRect.left,
                                          top: _inset - lensRect.top,
                                          width: rowWidth,
                                          height: rowHeight,
                                          child: Transform.scale(
                                            scale: _magnify,
                                            // Zoom around the lens centre.
                                            alignment: Alignment(
                                              (centerX - _inset) /
                                                      rowWidth *
                                                      2 -
                                                  1,
                                              0,
                                            ),
                                            child: tabsRow(magnified: true),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 4. Glass rim on top of everything.
                              Positioned.fromRect(
                                rect: lensRect,
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _GlassRimPainter(
                                      radius: lensRadius,
                                      dark: dark,
                                      strong: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
// LENS — a brighter, clearer drop of glass
// ------------------------------------------------------------------

class _Lens extends StatelessWidget {
  const _Lens({required this.radius, required this.dark, required this.tint});

  final double radius;
  final bool dark;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: dark ? .30 : .16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          // Brighter, more vivid behind the drop.
          filter: ColorFilter.matrix(_vibrancy(1.35, dark ? 18 : 24)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Clear in the middle, denser at the edges — like a lens.
              gradient: RadialGradient(
                radius: 1.1,
                colors: dark
                    ? [
                        Colors.white.withValues(alpha: .10),
                        Colors.white.withValues(alpha: .22),
                      ]
                    : [
                        Colors.white.withValues(alpha: .55),
                        Color.alphaBlend(
                          tint.withValues(alpha: .10),
                          Colors.white.withValues(alpha: .80),
                        ),
                      ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
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
    required this.focus,
    required this.selected,
    required this.magnified,
    required this.activeColor,
    required this.dark,
    required this.onTap,
  });

  final AdaptiveNavItem item;

  /// 0 = lens far away, 1 = lens right on top.
  final double focus;
  final bool selected;

  /// true = the copy drawn inside the lens (always in the active
  /// colour); false = the normal tab, which fades out as the lens
  /// covers it so you only see the magnified version.
  final bool magnified;
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

    final inactive = widget.dark
        ? Colors.white.withValues(alpha: .78)
        : const Color(0xFF3C3C43).withValues(alpha: .80);
    final color = widget.magnified
        ? widget.activeColor
        : Color.lerp(inactive, widget.activeColor, widget.focus * .4)!;

    final icon = widget.focus > .5 || widget.selected
        ? (item.iosActiveIcon ?? item.iosIcon ?? item.activeIcon)
        : (item.iosIcon ?? item.icon);

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _badged(Icon(icon, size: 23, color: color), item),
        const SizedBox(height: 2),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: widget.magnified || widget.focus > .5
                ? FontWeight.w700
                : FontWeight.w500,
            letterSpacing: -.1,
          ),
        ),
      ],
    );

    // Copy inside the lens: just draw it.
    if (widget.magnified) return content;

    // Normal tab: tappable, fades out as the lens covers it.
    return Semantics(
      button: true,
      selected: widget.selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? .88 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Opacity(
            opacity: (1 - widget.focus * 1.4).clamp(0.0, 1.0),
            child: content,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// RIM — thick, light-catching glass edge
// ------------------------------------------------------------------

class _GlassRimPainter extends CustomPainter {
  _GlassRimPainter({
    required this.radius,
    required this.dark,
    this.strong = false,
  });

  final double radius;
  final bool dark;
  final bool strong;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      rect.deflate(.6),
      Radius.circular(radius),
    );
    final inner = RRect.fromRectAndRadius(
      rect.deflate(2.2),
      Radius.circular(math.max(0, radius - 1.6)),
    );

    final a = strong ? 1.0 : .85;

    // Outer rim: bright top-left, fades, glows back bottom-right.
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: (dark ? .55 : 1) * a),
            Colors.white.withValues(alpha: (dark ? .05 : .15) * a),
            Colors.white.withValues(alpha: (dark ? .30 : .70) * a),
          ],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );

    // Inner rim: gives the glass thickness.
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            Colors.white.withValues(alpha: (dark ? .18 : .45) * a),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    // Curved sheen across the top.
    canvas.save();
    canvas.clipRRect(outer);
    final sheenRect = Rect.fromLTWH(
      size.width * .04,
      -size.height * .55,
      size.width * .92,
      size.height * 1.05,
    );
    canvas.drawOval(
      sheenRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: (dark ? .10 : .32) * a),
          ],
        ).createShader(sheenRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter old) =>
      old.dark != dark || old.radius != radius || old.strong != strong;
}

// ==================================================================
// SLIDING INDEXED STACK
// ==================================================================
// Drop-in replacement for IndexedStack:
//   • keeps every tab alive (scroll position, loaded data)
//   • slides + fades between tabs in the direction you moved
//   • stopAboveBar (default true): every page ends ABOVE the
//     floating glass bar, so you always see the full page.
//     Set false to let content scroll underneath the glass instead.
// ==================================================================

class SlidingIndexedStack extends StatefulWidget {
  const SlidingIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.stopAboveBar = true,
    this.duration = const Duration(milliseconds: 340),
  });

  final int index;
  final List<Widget> children;
  final bool stopAboveBar;
  final Duration duration;

  @override
  State<SlidingIndexedStack> createState() => _SlidingIndexedStackState();
}

class _SlidingIndexedStackState extends State<SlidingIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  late int _previous = widget.index;
  int _direction = 1;

  @override
  void didUpdateWidget(covariant SlidingIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _previous = old.index;
      _direction = widget.index > old.index ? 1 : -1;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget stack = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        final animating = _c.value < 1;

        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              _layer(i, t, animating),
          ],
        );
      },
    );

    // Stop pages above the floating bar (worked out from the bar's own
    // size, so it doesn't depend on what Scaffold reports).
    if (widget.stopAboveBar && isCupertino(context)) {
      stack = Padding(
        padding: EdgeInsets.only(bottom: glassBarSpace(context)),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: _GlassSpaceHandled(child: stack),
        ),
      );
    }

    return stack;
  }

  // Every child always gets the same wrapper, so its State is kept.
  Widget _layer(int i, double t, bool animating) {
    final active = i == widget.index;
    final outgoing = animating && i == _previous && _previous != widget.index;
    final visible = active || outgoing;

    var dx = 0.0;
    var opacity = 1.0;

    if (active && animating) {
      dx = _direction * .10 * (1 - t);
      opacity = t;
    } else if (outgoing) {
      dx = -_direction * .06 * t;
      opacity = 1 - t;
    }

    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: IgnorePointer(
          ignoring: !active,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: FractionalTranslation(
              translation: Offset(dx, 0),
              child: widget.children[i],
            ),
          ),
        ),
      ),
    );
  }
}
