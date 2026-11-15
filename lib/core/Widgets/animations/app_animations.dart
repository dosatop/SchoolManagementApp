import 'dart:math' as math;

import 'package:flutter/material.dart';

// ====================================================================
// APP ANIMATIONS (no extra packages)
// ====================================================================
// Small building blocks used across the dashboards:
//
//   FadeSlideIn   – fades + slides a widget in once, after a delay.
//   Entrance      – FadeSlideIn with a delay from its position (stagger).
//   staggered()   – wraps every child of a list in an Entrance.
//   PressScale    – shrinks a card slightly while a finger is on it.
//   CountUp       – a number that counts up to its value.
//   FloatingBubble– slow up-and-down drift for decorative circles.
//
// All of them respect the phone's "reduce motion" setting.

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

// --------------------------------------------------------------------
// FADE + SLIDE IN (plays once when the widget first appears)
// --------------------------------------------------------------------

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, 22),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Where the widget starts, in pixels, relative to its final place.
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (_reduceMotion(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: widget.offset * (1 - _t.value),
          child: child,
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// STAGGERED ENTRANCE
// --------------------------------------------------------------------

class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = 60,
    this.step = 55,
    this.offset = const Offset(0, 22),
  });

  final int index;
  final Widget child;

  /// Milliseconds before the first item, and between items.
  final int baseDelay;
  final int step;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    // Cap the delay so long lists don't keep the user waiting.
    final ms = baseDelay + math.min(index, 10) * step;
    return FadeSlideIn(
      delay: Duration(milliseconds: ms),
      offset: offset,
      child: child,
    );
  }
}

/// Wraps every widget in [children] in an [Entrance], in order.
List<Widget> staggered(
  List<Widget> children, {
  int start = 0,
  int baseDelay = 60,
  int step = 55,
}) {
  return [
    for (var i = 0; i < children.length; i++)
      Entrance(
        index: start + i,
        baseDelay: baseDelay,
        step: step,
        child: children[i],
      ),
  ];
}

// --------------------------------------------------------------------
// PRESS SCALE (cards shrink a touch under the finger)
// --------------------------------------------------------------------
// Uses a Listener, so the card's own InkWell / onTap still work.

class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = .965});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// --------------------------------------------------------------------
// COUNT UP
// --------------------------------------------------------------------

class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) {
      return Text('${value.round()}$suffix', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

// --------------------------------------------------------------------
// FLOATING BUBBLE
// --------------------------------------------------------------------

class FloatingBubble extends StatefulWidget {
  const FloatingBubble({
    super.key,
    required this.child,
    this.distance = 8,
    this.phase = 0,
    this.period = const Duration(seconds: 7),
  });

  final Widget child;
  final double distance;
  final double phase;
  final Duration period;

  @override
  State<FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!_reduceMotion(context)) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          math.cos(_controller.value * 2 * math.pi + widget.phase) *
              widget.distance *
              .5,
          math.sin(_controller.value * 2 * math.pi + widget.phase) *
              widget.distance,
        ),
        child: child,
      ),
    );
  }
}
