import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/students/presentation/student_assignments_page.dart';
import 'package:app/features/students/presentation/student_profile_page.dart';
import 'package:app/features/students/presentation/student_results_page.dart';
import 'package:app/features/students/presentation/student_subjects_page.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// THEME
// ==================================================================

const Color _primary = Color(0xFF091993);
const Color _primaryLight = Color(0xFFE9ECFF);
const Color _background = Color(0xFFF6F7FB);
const Color _textDark = Color(0xFF20232E);

// ==================================================================
// SHARED ACTIONS
// ==================================================================

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authProvider.notifier).logout();
  } catch (_) {
    // A failing logout endpoint must not block going back to login.
  }

  if (!context.mounted) return;

  context.go('/login');
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
    setState(() => _currentIndex = index);
  }

  // ================================================================
  // BACK BUTTON
  // ================================================================
  // Other tab -> back to Home. Home -> tap twice to exit.

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

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: _exitDelay,
        margin: const EdgeInsets.only(left: 80, right: 80, bottom: 10),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: _textDark,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_double_arrow_left_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Tap again to exit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: _background,

        // IndexedStack keeps every tab alive between switches.
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _StudentHomeTab(onNavigate: _goToTab),
            const StudentSubjectsPage(),
            const StudentAssignmentsPage(),
            const StudentResultsPage(),
            const StudentProfilePage(),
          ],
        ),

        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: _primaryLight,
          elevation: 8,
          height: 70,
          selectedIndex: _currentIndex,
          onDestinationSelected: _goToTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: _primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded, color: _primary),
              label: 'Subjects',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: _primary),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: _primary),
              label: 'Results',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: _primary),
              label: 'Profile',
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

  /// Switches the bottom-navigation tab
  /// (1 = Subjects, 2 = Tasks, 3 = Results, 4 = Profile).
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

    final loading = profileAsync.isLoading && student == null;
    final error = profileAsync.hasError && student == null
        ? profileAsync.error
        : null;

    // Real data from the student endpoints.
    final subjectsAsync = ref.watch(studentSubjectsProvider);
    final assignmentsAsync = ref.watch(
      studentAssignmentsProvider(StudentTermParams.current),
    );
    final attendanceAsync = ref.watch(
      studentAttendanceProvider(StudentTermParams.current),
    );

    final subjects = _list(subjectsAsync.valueOrNull, ['subjects']);
    final assignments = _list(assignmentsAsync.valueOrNull, ['assignments']);
    final pending = assignments.where((a) => !_isSubmitted(a)).toList();

    final attendanceRate = _attendanceRate(attendanceAsync.valueOrNull);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (error != null)
                _ProfileErrorCard(error: error, onRetry: _refresh)
              else
                _welcomeCard(
                  name: loading ? null : (student?.fullName ?? 'Student'),
                  studentNumber: student?.studentNumber,
                  className: student?.className,
                  schoolName: student?.schoolName,
                ),

              const SizedBox(height: 18),

              // ------------------------------------------------------
              // STATS
              // ------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Subjects',
                      value: _statValue(
                        subjectsAsync,
                        () => '${subjects.length}',
                      ),
                      color: _primary,
                      onTap: () => widget.onNavigate(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      icon: Icons.assignment_rounded,
                      label: 'To do',
                      value: _statValue(
                        assignmentsAsync,
                        () => '${pending.length}',
                      ),
                      color: Colors.orange,
                      onTap: () => widget.onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      icon: Icons.fact_check_rounded,
                      label: 'Attendance',
                      value: _statValue(
                        attendanceAsync,
                        () => attendanceRate == null
                            ? '—'
                            : '${attendanceRate.toStringAsFixed(0)}%',
                      ),
                      color: Colors.teal,
                      onTap: () => context.push('/student/attendance'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ------------------------------------------------------
              // DUE SOON
              // ------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _sectionTitle(
                      'Due soon',
                      subtitle: 'Assignments still to submit',
                    ),
                  ),
                  if (pending.length > 3)
                    TextButton(
                      onPressed: () => widget.onNavigate(2),
                      style: TextButton.styleFrom(
                        foregroundColor: _primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              _dueSoon(assignmentsAsync, pending),

              const SizedBox(height: 26),

              // ------------------------------------------------------
              // QUICK ACCESS (pages not in the bottom bar)
              // ------------------------------------------------------
              _sectionTitle('Quick access', subtitle: 'Your school day'),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _quickTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Timetable',
                      color: Colors.purple,
                      onTap: () => context.push('/student/timetable'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickTile(
                      icon: Icons.fact_check_rounded,
                      title: 'Attendance',
                      color: Colors.teal,
                      onTap: () => context.push('/student/attendance'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickTile(
                      icon: Icons.quiz_rounded,
                      title: 'Exams',
                      color: Colors.red,
                      onTap: () => context.push('/student/exams'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ------------------------------------------------------
              // SHORTCUTS TO TABS
              // ------------------------------------------------------
              _sectionTitle('Academics', subtitle: 'Jump straight in'),

              const SizedBox(height: 12),

              _shortcutRow(
                icon: Icons.menu_book_rounded,
                title: 'My subjects',
                subtitle: 'Subjects and teachers',
                color: _primary,
                onTap: () => widget.onNavigate(1),
              ),
              _shortcutRow(
                icon: Icons.assignment_rounded,
                title: 'Assignments',
                subtitle: 'Work to submit',
                color: Colors.orange,
                onTap: () => widget.onNavigate(2),
              ),
              _shortcutRow(
                icon: Icons.bar_chart_rounded,
                title: 'Results',
                subtitle: 'Test and exam scores',
                color: Colors.green,
                onTap: () => widget.onNavigate(3),
              ),

              const SizedBox(height: 26),

              // ------------------------------------------------------
              // LEARNING SUPPORT
              // ------------------------------------------------------
              _sectionTitle(
                'Learning support',
                subtitle: 'Get more help with your studies',
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _learningCard(
                      icon: Icons.auto_stories_outlined,
                      title: 'Online Study',
                      subtitle: 'Study at your own pace',
                      color: _primary,
                      route: '/student/online-study',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _learningCard(
                      icon: Icons.support_agent_outlined,
                      title: 'Online Tutor',
                      subtitle: 'Learn with a tutor',
                      color: Colors.green,
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
    ref.invalidate(studentAssignmentsProvider(StudentTermParams.current));
    ref.invalidate(studentAttendanceProvider(StudentTermParams.current));

    await Future.wait([
      ref
          .read(studentProfileProvider.notifier)
          .refresh()
          .then((_) {}, onError: (_) {}),
      ref.read(studentSubjectsProvider.future).then((_) {}, onError: (_) {}),
      ref
          .read(studentAssignmentsProvider(StudentTermParams.current).future)
          .then((_) {}, onError: (_) {}),
      ref
          .read(studentAttendanceProvider(StudentTermParams.current).future)
          .then((_) {}, onError: (_) {}),
    ]);
  }

  // ================================================================
  // STATS
  // ================================================================

  /// '…' while loading, '—' on error, otherwise the computed value.
  String _statValue(AsyncValue<dynamic> async, String Function() value) {
    if (async.isLoading && !async.hasValue) return '…';
    if (async.hasError && !async.hasValue) return '—';
    return value();
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // DUE SOON
  // ================================================================

  Widget _dueSoon(AsyncValue<dynamic> async, List<dynamic> pending) {
    if (async.isLoading && !async.hasValue) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
        ),
      );
    }

    if (async.hasError && !async.hasValue) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unable to load assignments',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(
                studentAssignmentsProvider(StudentTermParams.current),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (pending.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                color: Colors.green.shade600,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'All caught up',
              style: TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have no assignments to submit.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Soonest due first; no due date goes last.
    final sorted = [...pending]
      ..sort((a, b) {
        final da = _dueDate(a);
        final db = _dueDate(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    return Column(
      children: [for (final item in sorted.take(3)) _assignmentCard(item)],
    );
  }

  Widget _assignmentCard(dynamic item) {
    final title = _str(item, ['title', 'name']) ?? 'Assignment';
    final subject = _str(item, ['subjectName', 'subject']);
    final teacher = _str(item, ['teacherName']);
    final due = _dueDate(item);
    final badge = _dueBadge(due);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () => widget.onNavigate(2),
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badge.color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: badge.color,
                    size: 21,
                  ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                    horizontal: 10,
                    vertical: 6,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({String label, Color color}) _dueBadge(DateTime? due) {
    if (due == null) return (label: 'No date', color: Colors.grey.shade600);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(today).inDays;

    if (days < 0) return (label: 'Overdue', color: Colors.red.shade600);
    if (days == 0) return (label: 'Today', color: Colors.red.shade600);
    if (days == 1) return (label: 'Tomorrow', color: Colors.orange.shade700);
    if (days <= 7) {
      return (label: 'In $days days', color: Colors.orange.shade700);
    }
    return (label: '${due.day} ${_months[due.month - 1]}', color: _primary);
  }

  // ================================================================
  // DATA HELPERS
  // ================================================================
  // The student endpoints return plain lists or wrapped objects;
  // these read both, so small API shape changes don't break the page.

  List<dynamic> _list(dynamic data, List<String> keys) {
    if (data is List) return data;

    if (data is Map) {
      for (final key in [...keys, 'data', 'items', 'records']) {
        final value = data[key];
        if (value is List) return value;
      }
    }

    return const [];
  }

  String? _str(dynamic item, List<String> keys) {
    if (item is! Map) return null;

    for (final key in keys) {
      final value = item[key];
      if (value != null && value is! Map && value is! List) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }

    return null;
  }

  DateTime? _dueDate(dynamic item) {
    final raw = _str(item, ['dueDate', 'deadline']);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// Submitted if the API says so directly, or includes a submission.
  bool _isSubmitted(dynamic item) {
    if (item is! Map) return false;

    for (final key in ['isSubmitted', 'submitted', 'hasSubmitted']) {
      if (item[key] == true) return true;
    }

    final status = _str(item, ['submissionStatus', 'status'])?.toLowerCase();
    if (status == 'submitted' || status == 'graded') return true;

    return item['submission'] is Map || item['submittedAt'] != null;
  }

  /// Attendance % from either a summary (percentage / present+total)
  /// or a list of records. Late counts as attended; Excused is ignored.
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

    final records = _list(data, ['attendance']);
    var counted = 0;
    var attended = 0;

    for (final record in records) {
      final status = _str(record, ['status'])?.toLowerCase();
      if (status == null || status == 'excused') continue;

      counted++;
      if (status == 'present' || status == 'late') attended++;
    }

    if (counted == 0) return null;

    return attended / counted * 100;
  }

  // ================================================================
  // WELCOME CARD
  // ================================================================

  Widget _welcomeCard({
    required String? name,
    String? studentNumber,
    String? className,
    String? schoolName,
  }) {
    final initials = _initials(name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _todayLabel(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_greeting()},',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name ?? 'Loading…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => widget.onNavigate(4),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .25),
                    ),
                  ),
                  child: Center(
                    child: initials.isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 28,
                          )
                        : Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_hasText(className) ||
              _hasText(studentNumber) ||
              _hasText(schoolName)) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_hasText(className))
                  _pill(Icons.class_outlined, className!),
                if (_hasText(studentNumber))
                  _pill(Icons.badge_outlined, 'Roll No. $studentNumber'),
                if (_hasText(schoolName))
                  _pill(Icons.school_outlined, schoolName!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
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
  // QUICK TILE
  // ================================================================

  Widget _quickTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SHORTCUT ROW
  // ================================================================

  Widget _shortcutRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // LEARNING SUPPORT CARD
  // ================================================================

  Widget _learningCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // DATE HELPERS
  // ================================================================

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// TUESDAY, 27 OCT
  String _todayLabel() {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}'
        .toUpperCase();
  }
}

// ==================================================================
// PROFILE ERROR CARD
// ==================================================================
// 401 / 403 means the saved session is wrong (e.g. a teacher token
// left over from another login), so retrying won't help. Offer a
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              sessionProblem
                  ? Icons.lock_outline_rounded
                  : Icons.cloud_off_rounded,
              color: Colors.red.shade400,
              size: 28,
            ),
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
              fontWeight: FontWeight.bold,
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

// ==================================================================
// HELPERS
// ==================================================================

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _initials(String? name) {
  if (!_hasText(name)) return '';

  final words = name!
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  if (words.length == 1) return words.first[0].toUpperCase();

  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
