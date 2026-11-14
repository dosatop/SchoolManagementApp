import 'package:app/core/Widgets/NavBar/adaptive_nav_bar.dart';
import 'package:app/features/announcements/presentation/widgets/announcement_widgets.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/students/presentation/student_assignments_page.dart';
import 'package:app/features/students/presentation/student_profile_page.dart';
import 'package:app/features/students/presentation/student_results_page.dart';
import 'package:app/features/students/presentation/student_subjects_page.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// SHARED
// ==================================================================

const _primary = StudentColors.primary;
const _textDark = StudentColors.textDark;
const _term = StudentTermParams.current;

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authProvider.notifier).logout();
  } catch (_) {
    // A failing logout endpoint must not block going back to login.
  }
  if (context.mounted) context.go('/login');
}

/// Submitted if the API says so directly, or includes a submission.
bool _isSubmitted(dynamic item) {
  if (item is! Map) return false;

  for (final key in ['isSubmitted', 'submitted', 'hasSubmitted']) {
    if (item[key] == true) return true;
  }

  final status = sStr(item, ['submissionStatus', 'status'])?.toLowerCase();
  if (status == 'submitted' || status == 'graded') return true;

  return item['submission'] is Map || item['submittedAt'] != null;
}

// ==================================================================
// DASHBOARD SHELL (BOTTOM NAVIGATION)
// ==================================================================

class StudentDashboardPage extends ConsumerStatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  ConsumerState<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage> {
  static const Duration _exitDelay = Duration(seconds: 2);

  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  void _goToTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  // Other tab -> Home. Home -> tap twice to exit.
  void _handleBackPressed() {
    if (_currentIndex != 0) {
      _goToTab(0);
      return;
    }

    final now = DateTime.now();

    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) <= _exitDelay) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }

    _lastBackPressed = now;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: _exitDelay,
          margin: const EdgeInsets.fromLTRB(50, 0, 50, 12),
          backgroundColor: _textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          content: const Text(
            'Are you sure you want to exit? Press back again to close.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Badge on the Tasks tab = assignments still to submit.
    final assignments = sList(
      ref.watch(studentAssignmentsProvider(_term)).valueOrNull,
      ['assignments'],
    );
    final pending = assignments.where((a) => !_isSubmitted(a)).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: StudentColors.background,
        // iOS: pages scroll underneath the glass bar.
        extendBody: isCupertino(context),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _StudentHomeTab(onNavigate: _goToTab),
            const StudentAssignmentsPage(),
            const StudentResultsPage(),
            const StudentProfilePage(),
          ],
        ),
        // iOS → Cupertino tab bar, Android → Material 3 navigation bar.
        bottomNavigationBar: AdaptiveNavBar(
          currentIndex: _currentIndex,
          onTap: _goToTab,
          activeColor: _primary,
          indicatorColor: StudentColors.primaryLight,
          items: [
            const AdaptiveNavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              iosIcon: CupertinoIcons.house,
              iosActiveIcon: CupertinoIcons.house_fill,
            ),
            AdaptiveNavItem(
              label: 'Tasks',
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              iosIcon: CupertinoIcons.doc_text,
              iosActiveIcon: CupertinoIcons.doc_text_fill,
              badge: pending,
              badgeColor: Colors.orange.shade700,
            ),
            const AdaptiveNavItem(
              label: 'Results',
              icon: Icons.insights_outlined,
              activeIcon: Icons.insights_rounded,
              iosIcon: CupertinoIcons.chart_bar,
              iosActiveIcon: CupertinoIcons.chart_bar_fill,
            ),
            const AdaptiveNavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              iosIcon: CupertinoIcons.person,
              iosActiveIcon: CupertinoIcons.person_fill,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// HOME TAB
// ==================================================================

class _StudentHomeTab extends ConsumerStatefulWidget {
  const _StudentHomeTab({required this.onNavigate});

  /// 1 = Tasks, 2 = Results, 3 = Profile.
  final ValueChanged<int> onNavigate;

  @override
  ConsumerState<_StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends ConsumerState<_StudentHomeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final profileAsync = ref.watch(studentProfileProvider);
    final student = profileAsync.valueOrNull;
    final profileLoading = profileAsync.isLoading && student == null;
    final profileError = profileAsync.hasError && student == null
        ? profileAsync.error
        : null;

    final subjectsAsync = ref.watch(studentSubjectsProvider);
    final assignmentsAsync = ref.watch(studentAssignmentsProvider(_term));
    final attendanceAsync = ref.watch(studentAttendanceProvider(_term));
    final resultsAsync = ref.watch(studentResultsProvider(_term));

    final subjects = sList(subjectsAsync.valueOrNull, ['subjects']);
    final assignments = sList(assignmentsAsync.valueOrNull, ['assignments']);
    final pending = assignments.where((a) => !_isSubmitted(a)).toList();
    final results = sList(resultsAsync.valueOrNull, ['results', 'subjects']);

    final attendanceRate = _attendanceRate(attendanceAsync.valueOrNull);
    final average = _average(results);

    return Scaffold(
      backgroundColor: StudentColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              18,
              14,
              18,
              32 + glassBottomInset(context),
            ),
            children: [
              if (profileError != null)
                _ProfileErrorCard(error: profileError, onRetry: _refresh)
              else
                _hero(
                  name: profileLoading
                      ? null
                      : (student?.fullName ?? 'Student'),
                  className: student?.className,
                  studentNumber: student?.studentNumber,
                  attendanceRate: attendanceRate,
                  attendanceLoading:
                      attendanceAsync.isLoading && !attendanceAsync.hasValue,
                  subjects: _value(subjectsAsync, () => '${subjects.length}'),
                  todo: _value(assignmentsAsync, () => '${pending.length}'),
                  average: _value(
                    resultsAsync,
                    () => average == null
                        ? '—'
                        : '${average.toStringAsFixed(0)}%',
                  ),
                ),

              const SizedBox(height: 24),

              // --------------------------------------------------------
              // DUE SOON
              // --------------------------------------------------------
              SectionHeader(
                'Due soon',
                subtitle: pending.isEmpty
                    ? 'Assignments still to submit'
                    : '${pending.length} still to submit',
                actionLabel: pending.length > 3 ? 'See all' : null,
                onAction: () => widget.onNavigate(1),
              ),
              const SizedBox(height: 12),
              _dueSoon(assignmentsAsync, pending),

              const SizedBox(height: 26),

              // --------------------------------------------------------
              // QUICK ACCESS
              // --------------------------------------------------------
              const SectionHeader('Quick access', subtitle: 'Your school day'),
              const SizedBox(height: 12),
              _quickGrid(),

              const SizedBox(height: 26),

              // --------------------------------------------------------
              // LATEST RESULTS
              // --------------------------------------------------------
              SectionHeader(
                'This term\'s results',
                subtitle: 'Your strongest subjects so far',
                actionLabel: results.isNotEmpty ? 'View all' : null,
                onAction: () => widget.onNavigate(2),
              ),
              const SizedBox(height: 12),
              _latestResults(resultsAsync, results),

              const SizedBox(height: 26),

              // --------------------------------------------------------
              // LEARNING SUPPORT
              // --------------------------------------------------------
              const SectionHeader(
                'Learning support',
                subtitle: 'Get more help with your studies',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _learningCard(
                      icon: Icons.auto_stories_rounded,
                      title: 'Online Study',
                      subtitle: 'Learn at your own pace',
                      colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      route: '/student/online-study',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _learningCard(
                      icon: Icons.support_agent_rounded,
                      title: 'Online Tutor',
                      subtitle: 'Get help from a tutor',
                      colors: const [Color(0xFF059669), Color(0xFF0D9488)],
                      route: '/student/online-tutor',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(studentSubjectsProvider);
    ref.invalidate(studentAssignmentsProvider(_term));
    ref.invalidate(studentAttendanceProvider(_term));
    ref.invalidate(studentResultsProvider(_term));

    await Future.wait([
      sSafe(ref.read(studentProfileProvider.notifier).refresh()),
      sSafe(ref.read(studentSubjectsProvider.future)),
      sSafe(ref.read(studentAssignmentsProvider(_term).future)),
      sSafe(ref.read(studentAttendanceProvider(_term).future)),
      sSafe(ref.read(studentResultsProvider(_term).future)),
    ]);
  }

  /// '…' while loading, '—' on error, otherwise the value.
  String _value(AsyncValue<dynamic> async, String Function() value) {
    if (async.isLoading && !async.hasValue) return '…';
    if (async.hasError && !async.hasValue) return '—';
    return value();
  }

  // ================================================================
  // HERO
  // ================================================================

  Widget _hero({
    required String? name,
    String? className,
    String? studentNumber,
    required double? attendanceRate,
    required bool attendanceLoading,
    required String subjects,
    required String todo,
    required String average,
  }) {
    final initials = studentInitials(name);

    return Container(
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: .25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -40, top: -40, child: _bubble(150, .07)),
          Positioned(left: -30, bottom: -50, child: _bubble(120, .05)),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- Greeting row ----------------
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _todayLabel(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .65),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_greeting()} ${_greetingEmoji()}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (name == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Shimmer(
                                child: ShimmerBox(
                                  width: 160,
                                  height: 22,
                                  onDark: true,
                                ),
                              ),
                            )
                          else
                            Text(
                              name.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ---------------- Announcements bell ----------------
                    // Red badge = unread announcements; tap → feed.
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .25),
                        ),
                      ),
                      child: const AnnouncementBell(color: Colors.white),
                    ),

                    // ---------------- Avatar ----------------
                    GestureDetector(
                      onTap: () => widget.onNavigate(3),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .35),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: initials.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                              )
                            : Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                if (_has(className) || _has(studentNumber)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_has(className))
                        _pill(Icons.class_outlined, className!),
                      if (_has(studentNumber))
                        _pill(Icons.badge_outlined, 'No. $studentNumber'),
                    ],
                  ),
                ],

                const SizedBox(height: 18),

                // ---------------- Stats panel ----------------
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/student/attendance'),
                        child: ProgressRing(
                          value: (attendanceRate ?? 0) / 100,
                          size: 62,
                          stroke: 6,
                          child: attendanceLoading
                              ? const Shimmer(
                                  child: ShimmerBox(
                                    width: 26,
                                    height: 12,
                                    onDark: true,
                                  ),
                                )
                              : Text(
                                  attendanceRate == null
                                      ? '—'
                                      : '${attendanceRate.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 62,
                        child: Text(
                          'Attendance',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Colors.white.withValues(alpha: .18),
                      ),
                      _heroTapStat('Subjects', subjects, onTap: _openSubjects),
                      _heroTapStat(
                        'To do',
                        todo,
                        onTap: () => widget.onNavigate(1),
                      ),
                      _heroTapStat(
                        'Average',
                        average,
                        onTap: () => widget.onNavigate(2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Subjects is no longer a tab: open it as its own page (back arrow).
  void _openSubjects() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StudentSubjectsPage()));
  }

  Widget _heroTapStat(
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(children: [HeroStat(label, value, loading: value == '…')]),
      ),
    );
  }

  Widget _bubble(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DUE SOON
  // ================================================================

  Widget _dueSoon(AsyncValue<dynamic> async, List<dynamic> pending) {
    if (async.isLoading && !async.hasValue) {
      return const Shimmer(
        child: Column(
          children: [
            ShimmerCard(),
            SizedBox(height: 10),
            ShimmerCard(trailing: false),
          ],
        ),
      );
    }

    if (async.hasError && !async.hasValue) {
      return _inlineError(
        'Unable to load assignments',
        () => ref.invalidate(studentAssignmentsProvider(_term)),
      );
    }

    if (pending.isEmpty) {
      return SoftCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(
              Icons.celebration_rounded,
              color: Colors.green.shade600,
              size: 48,
              circle: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All caught up!',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'You have no assignments to submit right now.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final sorted = [...pending]
      ..sort((a, b) {
        final da = sLocal(a, ['dueDate', 'deadline']);
        final db = sLocal(b, ['dueDate', 'deadline']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    return Column(
      children: [
        for (final item in sorted.take(3)) ...[
          _assignmentCard(item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _assignmentCard(dynamic item) {
    final title = sStr(item, ['title', 'name']) ?? 'Assignment';
    final subject = sStr(item, ['subjectName', 'subject']);
    final teacher = sStr(item, ['teacherName']);
    final due = sLocal(item, ['dueDate', 'deadline']);
    final badge = _dueBadge(due);

    return SoftCard(
      onTap: () => widget.onNavigate(1),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: badge.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  children: [
                    IconBadge(
                      Icons.assignment_rounded,
                      color: badge.color,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (subject != null) subject,
                              if (teacher != null) teacher,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge.label,
                        style: TextStyle(
                          color: badge.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String label, Color color}) _dueBadge(DateTime? due) {
    if (due == null) return (label: 'No date', color: Colors.grey.shade600);

    final days = studentDaysFromToday(due);

    if (days < 0) return (label: 'Overdue', color: Colors.red.shade600);
    if (days == 0) return (label: 'Today', color: Colors.red.shade600);
    if (days == 1) return (label: 'Tomorrow', color: Colors.orange.shade700);
    if (days <= 7) {
      return (label: 'In $days days', color: Colors.orange.shade700);
    }
    return (label: sShortDate(due), color: _primary);
  }

  // ================================================================
  // QUICK ACCESS GRID
  // ================================================================

  Widget _quickGrid() {
    final items = [
      (
        Icons.calendar_month_rounded,
        'Timetable',
        const Color(0xFF7C3AED),
        () => context.push('/student/timetable'),
      ),
      (
        Icons.fact_check_rounded,
        'Attendance',
        const Color(0xFF0D9488),
        () => context.push('/student/attendance'),
      ),
      (
        Icons.quiz_rounded,
        'Exams',
        const Color(0xFFDC2626),
        () => context.push('/student/exams'),
      ),
      (Icons.menu_book_rounded, 'Subjects', _primary, _openSubjects),
      (
        Icons.assignment_rounded,
        'Assignments',
        const Color(0xFFEA580C),
        () => widget.onNavigate(1),
      ),
      (
        Icons.insights_rounded,
        'Results',
        const Color(0xFF16A34A),
        () => widget.onNavigate(2),
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final (icon, title, color, onTap) in items)
          SoftCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBadge(icon, color: color, size: 44, circle: true),
                const SizedBox(height: 9),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ================================================================
  // LATEST RESULTS
  // ================================================================

  Widget _latestResults(AsyncValue<dynamic> async, List<dynamic> results) {
    if (async.isLoading && !async.hasValue) {
      return const Shimmer(child: ShimmerCard(lines: 3));
    }

    if (async.hasError && !async.hasValue) {
      return _inlineError(
        'Unable to load results',
        () => ref.invalidate(studentResultsProvider(_term)),
      );
    }

    final scored = [
      for (final r in results)
        if (_total(r) != null) (r: r, total: _total(r)!.toDouble()),
    ]..sort((a, b) => b.total.compareTo(a.total));

    if (scored.isEmpty) {
      return SoftCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(
              Icons.hourglass_top_rounded,
              color: Colors.grey.shade600,
              size: 44,
              circle: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No scores yet this term. They\'ll appear here once your '
                'teachers upload them.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SoftCard(
      onTap: () => widget.onNavigate(2),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          for (var i = 0; i < scored.length && i < 3; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
            _resultRow(scored[i].r, scored[i].total),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(dynamic r, double total) {
    final subject = sStr(r, ['subjectName', 'subject', 'name']) ?? 'Subject';
    final grade = sStr(r, ['grade']) ?? studentGradeFor(total);
    final color = studentGradeColor(grade);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (total / 100).clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            studentFmt(total),
            style: const TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Text(
              grade,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LEARNING CARD
  // ================================================================

  Widget _learningCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required String route,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(route),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .8),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // INLINE ERROR
  // ================================================================

  Widget _inlineError(String text, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DATA HELPERS
  // ================================================================

  num? _total(dynamic r) {
    final total = sNum(r, ['totalScore', 'total', 'score']);
    if (total != null) return total;

    final test = sNum(r, ['testScore', 'caScore']);
    final exam = sNum(r, ['examScore']);
    if (test != null && exam != null) return test + exam;

    return null;
  }

  double? _average(List<dynamic> results) {
    final totals = [
      for (final r in results)
        if (_total(r) != null) _total(r)!.toDouble(),
    ];
    if (totals.isEmpty) return null;
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  /// Late counts as attended; Excused/Holiday are ignored.
  double? _attendanceRate(dynamic data) {
    if (data is Map) {
      for (final key in ['attendancePercentage', 'percentage', 'rate']) {
        final value = num.tryParse('${data[key]}');
        if (value != null) return value.clamp(0, 100).toDouble();
      }

      final summary = data['summary'];
      if (summary is Map) {
        final nested = _attendanceRate(summary);
        if (nested != null) return nested;
      }
    }

    var counted = 0;
    var attended = 0;

    for (final record in sList(data, ['attendance', 'records'])) {
      final status = sStr(record, ['status'])?.toLowerCase();
      if (status == null || status == 'excused' || status == 'holiday') {
        continue;
      }

      counted++;
      if (status == 'present' || status == 'late') attended++;
    }

    if (counted == 0) return null;
    return attended / counted * 100;
  }

  // ================================================================
  // DATE HELPERS
  // ================================================================

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '👋';
    return '🌙';
  }

  /// MONDAY, 2 NOV
  String _todayLabel() {
    final now = DateTime.now();
    return '${sWeekday(now)}, ${sShortDate(now)}'.toUpperCase();
  }
}

// ==================================================================
// PROFILE ERROR CARD
// ==================================================================
// 401 / 403 = wrong saved session; retrying won't help, so offer a
// clean sign-in instead.

class _ProfileErrorCard extends ConsumerWidget {
  const _ProfileErrorCard({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = error is DioException
        ? (error as DioException).response?.statusCode
        : null;
    final sessionProblem = status == 401 || status == 403;

    return SoftCard(
      padding: const EdgeInsets.all(20),
      borderColor: Colors.red.shade100,
      child: Column(
        children: [
          IconBadge(
            sessionProblem
                ? Icons.lock_outline_rounded
                : Icons.cloud_off_rounded,
            color: Colors.red.shade400,
            size: 58,
            circle: true,
          ),
          const SizedBox(height: 12),
          Text(
            sessionProblem
                ? 'Please sign in again'
                : 'Unable to load your profile',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sessionProblem
                ? 'Your session has expired or belongs to a different account.'
                : 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: sessionProblem
                  ? () => _signOut(context, ref)
                  : onRetry,
              icon: Icon(
                sessionProblem ? Icons.login_rounded : Icons.refresh_rounded,
                size: 18,
              ),
              label: Text(sessionProblem ? 'Sign in' : 'Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _has(String? value) => value != null && value.trim().isNotEmpty;