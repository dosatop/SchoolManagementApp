import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// SHARED STUDENT UI + DATA HELPERS
// ==================================================================
// Used by the Subjects, Assignments, Results and Attendance pages so
// they look and behave the same way.

class StudentColors {
  StudentColors._();

  static const primary = Color(0xFF091993);
  static const primaryLight = Color(0xFFE9ECFF);
  static const background = Color(0xFFF6F7FB);
  static const textDark = Color(0xFF20232E);

  /// Rotating accent colours for lists of subjects.
  static const accents = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.indigo,
    Colors.pink,
    Colors.green,
  ];
}

// ==================================================================
// DATA HELPERS
// ==================================================================
// The API returns plain lists or wrapped objects. These read both, so
// small response-shape differences don't break the pages.

List<dynamic> sList(dynamic data, [List<String> keys = const []]) {
  if (data is List) return data;

  if (data is Map) {
    for (final key in [...keys, 'data', 'items', 'records']) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = sList(value, keys);
        if (nested.isNotEmpty) return nested;
      }
    }
  }

  return const [];
}

String? sStr(dynamic item, List<String> keys) {
  if (item is! Map) return null;

  for (final key in keys) {
    var value = item[key];
    if (value is Map) value = value['name'] ?? value['fullName'];
    if (value == null || value is Map || value is List) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }

  return null;
}

num? sNum(dynamic item, List<String> keys) {
  if (item is! Map) return null;

  for (final key in keys) {
    final value = item[key];
    if (value is num) return value;
    if (value != null) {
      final parsed = num.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
  }

  return null;
}

/// Calendar day of an API date. Dates stored as UTC midnight keep
/// their UTC day so UTC+1 never shifts them.
DateTime? sDay(dynamic item, List<String> keys) {
  final raw = sStr(item, keys);
  if (raw == null) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  final utc = parsed.isUtc ? parsed : parsed.toUtc();
  return DateTime(utc.year, utc.month, utc.day);
}

/// Local date-time (for due dates with a time).
DateTime? sLocal(dynamic item, List<String> keys) {
  final raw = sStr(item, keys);
  if (raw == null) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const sMonths = [
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

/// Mon, 26 Oct 2026
String sPrettyDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${sMonths[d.month - 1]} ${d.year}';

/// 26 Oct
String sShortDate(DateTime d) => '${d.day} ${sMonths[d.month - 1]}';

/// Monday
String sWeekday(DateTime d) => _weekdaysLong[d.weekday - 1];

/// Today / Yesterday / Mon, 26 Oct 2026
String sDayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return sPrettyDate(d);
}

/// Swallows errors so pull-to-refresh always finishes.
Future<void> sSafe(Future<dynamic> future) =>
    future.then((_) {}, onError: (_) {});

// ==================================================================
// STATUS COLOURS
// ==================================================================

({Color bg, Color fg}) sStatusColors(String status) {
  switch (status.toLowerCase()) {
    case 'present':
    case 'submitted':
    case 'graded':
      return (bg: Colors.green.shade50, fg: Colors.green.shade700);
    case 'absent':
    case 'overdue':
      return (bg: Colors.red.shade50, fg: Colors.red.shade700);
    case 'late':
    case 'pending':
    case 'to do':
      return (bg: Colors.orange.shade50, fg: Colors.orange.shade800);
    case 'excused':
      return (bg: Colors.blue.shade50, fg: Colors.blue.shade700);
    default:
      return (bg: Colors.grey.shade100, fg: Colors.grey.shade700);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = sStatusColors(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ==================================================================
// PAGE STATES (loading / error / empty)
// ==================================================================
// All are scrollable so pull-to-refresh still works.

class StudentLoadingView extends StatelessWidget {
  const StudentLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return _ScrollCenter(
      child: const CircularProgressIndicator(color: StudentColors.primary),
    );
  }
}

class StudentEmptyView extends StatelessWidget {
  const StudentEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _ScrollCenter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: StudentColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: StudentColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudentColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Error view. 401/403 means a bad session, so it offers sign-in
/// instead of retry. Shows the server's message when there is one.
class StudentErrorView extends ConsumerWidget {
  const StudentErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Something went wrong',
  });

  final Object error;
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dio = error is DioException ? error as DioException : null;
    final status = dio?.response?.statusCode;
    final sessionProblem = status == 401 || status == 403;

    String? serverMessage;
    final data = dio?.response?.data;
    if (data is Map && data['message'] != null) {
      serverMessage = data['message'].toString();
    }

    return _ScrollCenter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              sessionProblem
                  ? Icons.lock_outline_rounded
                  : Icons.cloud_off_rounded,
              color: Colors.red.shade400,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sessionProblem ? 'Please sign in again' : title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudentColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sessionProblem
                ? 'Your session has expired or belongs to a different account.'
                : serverMessage ?? 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: sessionProblem
                ? () async {
                    try {
                      await ref.read(authProvider.notifier).logout();
                    } catch (_) {}
                    if (context.mounted) context.go('/login');
                  }
                : onRetry,
            icon: Icon(
              sessionProblem ? Icons.login_rounded : Icons.refresh_rounded,
              size: 18,
            ),
            label: Text(sessionProblem ? 'Sign in' : 'Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollCenter extends StatelessWidget {
  const _ScrollCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .6,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(28), child: child),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// APP BAR
// ==================================================================
// Shows a back arrow only when the page was pushed (e.g. Attendance),
// not when it is a bottom-navigation tab.

PreferredSizeWidget studentAppBar(
  String title, {
  String? subtitle,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    foregroundColor: StudentColors.textDark,
    elevation: 0,
    titleSpacing: 20,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null && subtitle.trim().isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
      ],
    ),
    actions: actions,
  );
}

/// Blue gradient summary card used at the top of the pages.
class StudentSummaryCard extends StatelessWidget {
  const StudentSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.progress,
    this.icon = Icons.insights_outlined,
    this.footer,
  });

  final String label;
  final String value;
  final String caption;

  /// 0..1 for the ring. Null hides the ring and shows [icon].
  final double? progress;
  final IconData icon;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudentColors.primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 66,
                height: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (progress != null)
                      SizedBox(
                        width: 66,
                        height: 66,
                        child: CircularProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: .18),
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Icon(icon, color: Colors.white, size: 26),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

/// Small translucent stat used inside [StudentSummaryCard.footer].
class SummaryStat extends StatelessWidget {
  const SummaryStat(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
