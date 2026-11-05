import 'dart:math' as math;

import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';

// ==================================================================
// STUDENT UI KIT
// ==================================================================
// Small building blocks shared by the student pages so they all look
// the same. Sits on top of student_common.dart (colours, shimmer,
// empty/error views).
// ==================================================================

const kStudentGradient = LinearGradient(
  colors: [StudentColors.primary, Color(0xFF2B3FD1)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ==================================================================
// SOFT CARD
// ==================================================================

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(15),
    this.radius = 18,
    this.borderColor,
    this.color = Colors.white,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? const Color(0xFFE9EBF2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ==================================================================
// ICON BADGE
// ==================================================================

class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    required this.color,
    this.size = 44,
    this.iconSize,
    this.circle = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * .48),
    );
  }
}

// ==================================================================
// SECTION HEADER
// ==================================================================

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: StudentColors.primary,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ==================================================================
// PILL TABS (segmented filter with counts)
// ==================================================================

class PillTab<T> {
  const PillTab(this.value, this.label, {this.count, this.color});

  final T value;
  final String label;
  final int? count;
  final Color? color;
}

class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 12),
  });

  final List<PillTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final tab in tabs) ...[
            _pill(tab),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _pill(PillTab<T> tab) {
    final isSelected = tab.value == selected;
    final color = tab.color ?? StudentColors.primary;

    return GestureDetector(
      onTap: () => onChanged(tab.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE3E6EF),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (tab.count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: .22)
                      : color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tab.count}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// PROGRESS RING
// ==================================================================

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.stroke = 7,
    this.color = Colors.white,
    this.trackColor,
    this.child,
  });

  /// 0..1
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(
            value: v,
            stroke: stroke,
            color: color,
            track: trackColor ?? color.withValues(alpha: .2),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflated = rect.deflate(stroke / 2);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawArc(deflated, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      deflated,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

// ==================================================================
// HERO STAT (white-on-blue number + label)
// ==================================================================

class HeroStat extends StatelessWidget {
  const HeroStat(this.label, this.value, {super.key, this.loading = false});

  final String label;
  final String value;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading)
            const Shimmer(
              child: ShimmerBox(width: 32, height: 18, onDark: true),
            )
          else
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SEARCH FIELD
// ==================================================================

class StudentSearchField extends StatelessWidget {
  const StudentSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: StudentColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// SHEET HANDLE
// ==================================================================

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ==================================================================
// HELPERS
// ==================================================================

String studentInitials(String? name, {String fallback = ''}) {
  final words = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  if (words.isEmpty) return fallback;
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

String studentFmt(num n) =>
    n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

/// Common Nigerian grading. Adjust to your school's scale.
String studentGradeFor(double score) {
  if (score >= 70) return 'A';
  if (score >= 60) return 'B';
  if (score >= 50) return 'C';
  if (score >= 45) return 'D';
  if (score >= 40) return 'E';
  return 'F';
}

Color studentGradeColor(String? grade) {
  final g = (grade ?? '').trim().toUpperCase();
  switch (g.isEmpty ? '' : g[0]) {
    case 'A':
      return const Color(0xFF16A34A);
    case 'B':
      return const Color(0xFF2563EB);
    case 'C':
      return const Color(0xFF0D9488);
    case 'D':
    case 'E':
      return const Color(0xFFEA580C);
    case 'F':
      return const Color(0xFFDC2626);
    default:
      return Colors.grey.shade600;
  }
}

/// Days from today to [date] (negative = past).
int studentDaysFromToday(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateTime(date.year, date.month, date.day).difference(today).inDays;
}
