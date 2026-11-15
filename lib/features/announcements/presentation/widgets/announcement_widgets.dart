import 'dart:async';
import 'dart:math' as math;

import 'package:app/features/announcements/models/announcement_model.dart';
import 'package:app/features/announcements/provider/announcement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ====================================================================
// SHARED ANNOUNCEMENT UI
// ====================================================================

class AnnColors {
  static const primary = Color(0xFF091993);
  static const primaryLight = Color(0xFF2638C4);
  static const background = Color(0xFFF6F7FB);
  static const textDark = Color(0xFF20232E);
  static const textSoft = Color(0xFF6B7080);
  static const border = Color(0xFFE8EAF0);
  static const urgent = Color(0xFFDC2626);
  static const important = Color(0xFFEA8A0C);
  static const green = Color(0xFF16A34A);

  static Color forPriority(int priority) {
    switch (priority) {
      case Priority.urgent:
        return urgent;
      case Priority.important:
        return important;
      default:
        return primary;
    }
  }
}

IconData priorityIcon(int priority) {
  switch (priority) {
    case Priority.urgent:
      return Icons.priority_high_rounded;
    case Priority.important:
      return Icons.star_rounded;
    default:
      return Icons.campaign_rounded;
  }
}

/// "Just now", "5m", "3h", "Yesterday", "Mon", "12 Mar", "12 Mar 2025".
String timeAgo(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 && now.day == date.day) return '${diff.inHours}h ago';
  if (diff.inDays < 2 && now.day - date.day == 1) return 'Yesterday';

  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (diff.inDays < 7) return days[date.weekday - 1];

  return fullDate(date, withYear: date.year != now.year);
}

String fullDate(DateTime d, {bool withYear = true, bool withTime = false}) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  var s = '${d.day} ${months[d.month - 1]}';
  if (withYear) s += ' ${d.year}';
  if (withTime) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    s += ', $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }
  return s;
}

String roleLabel(String role) {
  switch (role) {
    case 'SuperAdmin':
      return 'Super admin';
    case 'Admin':
      return 'School admin';
    default:
      return role;
  }
}

// ====================================================================
// BELL WITH UNREAD BADGE — drop into any AppBar `actions`
// ====================================================================

class AnnouncementBell extends ConsumerStatefulWidget {
  const AnnouncementBell({super.key, this.color});

  final Color? color;

  @override
  ConsumerState<AnnouncementBell> createState() => _AnnouncementBellState();
}

// Bell with a live unread badge.
// • Unread > 0 → the bell rings (swings + hops) every few seconds.
// • A new announcement arrives → it rings straight away with a tap
//   of vibration, and the badge pops to the new number.
// • Nothing unread → it sits still.
// • Respects the phone's "reduce motion" setting.
class _AnnouncementBellState extends ConsumerState<AnnouncementBell>
    with SingleTickerProviderStateMixin {
  static const _ringEvery = Duration(seconds: 4);

  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  Timer? _timer;

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _ringNow() {
    if (!mounted || _reduceMotion) return;
    _ring.forward(from: 0);
  }

  /// Start ringing on a loop while there's something unread.
  void _sync(int count) {
    if (count > 0 && !_reduceMotion) {
      if (_timer != null) return;
      Future.delayed(const Duration(milliseconds: 700), _ringNow);
      _timer = Timer.periodic(_ringEvery, (_) => _ringNow());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(unreadAnnouncementsProvider).valueOrNull ?? 0;

    // New announcement → ring right away.
    ref.listen(unreadAnnouncementsProvider, (prev, next) {
      final before = prev?.valueOrNull ?? 0;
      final now = next.valueOrNull ?? 0;
      if (now > before) {
        HapticFeedback.lightImpact();
        _ringNow();
      }
    });

    _sync(count);

    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Icon(
        count > 0
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        key: ValueKey(count > 0),
        color: widget.color,
      ),
    );

    return IconButton(
      tooltip: 'Announcements',
      onPressed: () {
        HapticFeedback.selectionClick();
        context.push('/announcements');
      },
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ---------------- ringing bell ----------------
            Center(
              child: AnimatedBuilder(
                animation: _ring,
                child: icon,
                builder: (_, child) {
                  final t = _ring.value;
                  // Swing that fades out, pivoting from the top.
                  final angle = math.sin(t * math.pi * 6) * .38 * (1 - t);
                  // Small hop at the start of each ring.
                  final hop = -math.sin(math.min(t * 3, 1) * math.pi) * 3;
                  return Transform.translate(
                    offset: Offset(0, hop),
                    child: Transform.rotate(
                      angle: angle,
                      alignment: const Alignment(0, -.85),
                      child: child,
                    ),
                  );
                },
              ),
            ),

            // ---------------- badge (pops on change) ----------------
            Positioned(
              right: -7,
              top: -5,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: Curves.elasticOut,
                    reverseCurve: Curves.easeIn,
                  ),
                  child: child,
                ),
                child: count > 0
                    ? _Badge(key: ValueKey(count), count: count)
                    : const SizedBox.shrink(key: ValueKey(0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 17),
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AnnColors.urgent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AnnColors.urgent.withValues(alpha: .4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

// ====================================================================
// PULSING DOT (unread marker on a card)
// ====================================================================

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Halo that grows and fades
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.scale(
              scale: 1 + _c.value * 1.6,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: .45 * (1 - _c.value)),
                ),
              ),
            ),
          ),
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// SMALL PIECES
// ====================================================================

class AnnTag extends StatelessWidget {
  const AnnTag(this.text, {super.key, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// ANNOUNCEMENT CARD (feed)
// ====================================================================

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  final AnnouncementModel announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final color = AnnColors.forPriority(a.priority);
    final unread = !a.isRead && !a.isMine;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unread ? color.withOpacity(.35) : AnnColors.border,
          width: unread ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(priorityIcon(a.priority), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (a.isPinned) ...[
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: AnnColors.important,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              a.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AnnColors.textDark,
                                fontSize: 14.5,
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo(a.createdAt),
                            style: TextStyle(
                              color: unread ? color : AnnColors.textSoft,
                              fontSize: 11,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            PulsingDot(color: color),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AnnColors.textSoft,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (a.priority != Priority.normal)
                            AnnTag(
                              Priority.label(a.priority),
                              color: color,
                              icon: priorityIcon(a.priority),
                            ),
                          AnnTag(
                            a.targetLabel,
                            color: AnnColors.primary,
                            icon: Icons.groups_rounded,
                          ),
                          AnnTag(
                            a.isMine ? 'You' : a.createdByName,
                            color: AnnColors.textSoft,
                            icon: Icons.person_rounded,
                          ),
                          if (a.isExpired)
                            const AnnTag(
                              'Expired',
                              color: AnnColors.textSoft,
                              icon: Icons.history_toggle_off_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
