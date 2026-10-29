import 'package:app/features/teacher/presentation/assignment/teacher_assignments_page.dart';
import 'package:app/features/teacher/presentation/attendance/teacher_attendance_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_classes-page.dart';
import 'package:app/features/teacher/presentation/student/teacher_students_page.dart';
import 'package:app/features/teacher/presentation/teacher/teacher_profile_page.dart';
import 'package:app/features/teacher/presentation/teacher_timetable_page.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
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
// DASHBOARD SHELL (BOTTOM NAVIGATION)
// ==================================================================

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  int _currentIndex = 0;

  // No manual preloading: the home tab watches teacherProfileProvider,
  // teacherClassesProvider, teacherAssignmentsProvider and
  // teacherStudentsProvider, which fetch on their own.

  void _goToTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      // IndexedStack keeps every tab alive between switches.
      // The pages are built here (not cached in initState) so they always
      // get the current callback. Their State objects are still kept,
      // because each page keeps the same type and position.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TeacherHomePage(onNavigate: _goToTab),
          const TeacherClassesPage(),
          const TeacherAssignmentsPage(),
          const TeacherProfilePage(),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: _primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: _primary),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: _primary),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: _primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// HOME TAB
// ==================================================================

class _TeacherHomePage extends ConsumerStatefulWidget {
  const _TeacherHomePage({required this.onNavigate});

  /// Switches the bottom-navigation tab (1 = Classes, 2 = Tasks).
  final ValueChanged<int> onNavigate;

  @override
  ConsumerState<_TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<_TeacherHomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final profileAsync = ref.watch(teacherProfileProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    // Two sources make up "my classes":
    //   /teacher/classes  -> classes where the teacher is CLASS TEACHER
    //   /teacher/subjects -> subject + class rows the teacher TEACHES
    final classTeacherAsync = ref.watch(teacherClassesProvider);
    final subjectsAsync = ref.watch(teacherSubjectsProvider);

    final myClasses = _mergeClasses(
      _list(classTeacherAsync.valueOrNull, ['classes', 'data']),
      _list(subjectsAsync.valueOrNull, ['subjects', 'data']),
    );

    final classesLoading =
        (classTeacherAsync.isLoading && !classTeacherAsync.hasValue) ||
        (subjectsAsync.isLoading && !subjectsAsync.hasValue);

    final classesFailed =
        classTeacherAsync.hasError &&
        subjectsAsync.hasError &&
        myClasses.isEmpty;

    // Students per class (same provider the class pages use).
    final studentsByClass = <String, Set<String>>{};
    var studentsLoading = false;

    for (final c in myClasses) {
      final async = ref.watch(teacherStudentsProvider(c.id));

      if (async.isLoading && !async.hasValue) {
        studentsLoading = true;
        continue;
      }

      studentsByClass[c.id] = _studentIds(async.valueOrNull);
    }

    final uniqueStudents = studentsByClass.values.fold<Set<String>>(
      <String>{},
      (all, ids) => all..addAll(ids),
    );

    final teacherName = _teacherName(profileAsync.valueOrNull);
    final assignments = _list(assignmentsAsync.valueOrNull, [
      'assignments',
      'data',
    ]);

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
              _welcomeCard(
                name: profileAsync.isLoading && teacherName == null
                    ? null
                    : teacherName ?? 'Teacher',
              ),

              const SizedBox(height: 18),

              _statsRow(
                classCount: classesLoading ? null : myClasses.length,
                studentCount: classesLoading || studentsLoading
                    ? null
                    : uniqueStudents.length,
                assignmentCount:
                    assignmentsAsync.isLoading && assignments.isEmpty
                    ? null
                    : assignments.length,
              ),

              const SizedBox(height: 26),

              _sectionTitle('Quick actions'),

              const SizedBox(height: 12),

              _quickActions(),

              const SizedBox(height: 26),

              _sectionTitle(
                'My classes',
                action: myClasses.length > 3 ? 'See all' : null,
                onAction: () => widget.onNavigate(1),
              ),

              const SizedBox(height: 12),

              _classesSection(
                loading: classesLoading,
                failed: classesFailed,
                classes: myClasses,
                studentsByClass: studentsByClass,
              ),

              const SizedBox(height: 26),

              _sectionTitle(
                'Upcoming assignments',
                action: assignments.isEmpty ? null : 'See all',
                onAction: () => widget.onNavigate(2),
              ),

              const SizedBox(height: 12),

              _assignmentsSection(assignmentsAsync, assignments),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refresh() async {
    // Refresh every class's student list so the Students count updates.
    final current = _mergeClasses(
      _list(ref.read(teacherClassesProvider).valueOrNull, ['classes', 'data']),
      _list(ref.read(teacherSubjectsProvider).valueOrNull, [
        'subjects',
        'data',
      ]),
    );

    for (final c in current) {
      ref.invalidate(teacherStudentsProvider(c.id));
    }

    ref.invalidate(teacherProfileProvider);
    ref.invalidate(teacherClassesProvider);
    ref.invalidate(teacherSubjectsProvider);
    ref.invalidate(teacherAssignmentsProvider);

    // Wait for all; one failure shouldn't break the others.
    await Future.wait([
      ref.read(teacherProfileProvider.future).then((_) {}, onError: (_) {}),
      ref.read(teacherClassesProvider.future).then((_) {}, onError: (_) {}),
      ref.read(teacherSubjectsProvider.future).then((_) {}, onError: (_) {}),
      ref.read(teacherAssignmentsProvider.future).then((_) {}, onError: (_) {}),
    ]);
  }

  // ================================================================
  // WELCOME CARD
  // ================================================================

  Widget _welcomeCard({required String? name}) {
    final initial = (name != null && name.trim().isNotEmpty)
        ? name.trim()[0].toUpperCase()
        : '';

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
      child: Row(
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 2),

                if (name == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Shimmer(
                      child: ShimmerBox(width: 150, height: 20, onDark: true),
                    ),
                  )
                else
                  Text(
                    name,
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

          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
            ),
            child: Center(
              child: initial.isEmpty
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    )
                  : Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STATS
  // ================================================================

  Widget _statsRow({
    required int? classCount,
    required int? studentCount,
    required int? assignmentCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.class_outlined,
            label: 'Classes',
            value: classCount,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.groups_outlined,
            label: 'Students',
            value: studentCount,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.assignment_outlined,
            label: 'Assignments',
            value: assignmentCount,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int? value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          if (value == null)
            const Shimmer(child: ShimmerBox(width: 34, height: 22))
          else
            Text(
              '$value',
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
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle(String title, {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }

  // ================================================================
  // QUICK ACTIONS
  // ================================================================
  // Classes and Assignments already live in the bottom bar, so only
  // the pages that aren't reachable from there are here.

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            icon: Icons.fact_check_outlined,
            label: 'Attendance',
            color: Colors.green,
            onTap: () => _open(const TeacherAttendancePage()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            icon: Icons.groups_outlined,
            label: 'Students',
            color: Colors.purple,
            onTap: () => _open(const TeacherStudentsPage()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            icon: Icons.calendar_month_outlined,
            label: 'Timetable',
            color: Colors.blue,
            onTap: () => _open(const TeacherTimetablePage()),
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
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
                label,
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

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  // ================================================================
  // MY CLASSES
  // ================================================================

  Widget _classesSection({
    required bool loading,
    required bool failed,
    required List<_MyClass> classes,
    required Map<String, Set<String>> studentsByClass,
  }) {
    if (loading && classes.isEmpty) return _loadingCard();

    if (failed) {
      return _errorCard(
        message: 'Unable to load your classes',
        onRetry: () {
          ref.invalidate(teacherClassesProvider);
          ref.invalidate(teacherSubjectsProvider);
        },
      );
    }

    if (classes.isEmpty) {
      return _emptyCard(
        icon: Icons.class_outlined,
        title: 'No classes yet',
        message: 'Classes assigned to you will show up here.',
      );
    }

    const colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.indigo,
    ];

    final visible = classes.take(3).toList();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++)
          _classCard(
            visible[i],
            colors[i % colors.length],
            studentsByClass[visible[i].id]?.length ??
                visible[i].reportedStudents,
          ),
      ],
    );
  }

  Widget _classCard(_MyClass item, Color color, int? students) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => widget.onNavigate(1),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: color, size: 22),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.isClassTeacher) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Class teacher',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (item.subjects.isNotEmpty)
                            item.subjects.join(', '),
                          if (students != null)
                            '$students student${students == 1 ? '' : 's'}',
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

                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // UPCOMING ASSIGNMENTS
  // ================================================================

  Widget _assignmentsSection(
    AsyncValue<dynamic> async,
    List<dynamic> assignments,
  ) {
    if (async.isLoading && assignments.isEmpty) return _loadingCard();

    if (async.hasError && assignments.isEmpty) {
      return _errorCard(
        message: 'Unable to load assignments',
        onRetry: () => ref.invalidate(teacherAssignmentsProvider),
      );
    }

    // Upcoming first (soonest due), then anything without a date.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming =
        assignments.where((a) {
          final due = _dueDate(a);
          return due == null || !due.isBefore(today);
        }).toList()..sort((a, b) {
          final da = _dueDate(a);
          final db = _dueDate(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

    if (upcoming.isEmpty) {
      return _emptyCard(
        icon: Icons.task_alt_rounded,
        title: 'All caught up',
        message: 'You have no upcoming assignments.',
      );
    }

    return Column(
      children: [for (final item in upcoming.take(3)) _assignmentCard(item)],
    );
  }

  Widget _assignmentCard(dynamic item) {
    final title = _str(item, ['title', 'name']) ?? 'Assignment';
    final className = _str(item, ['className', 'class']);
    final subject = _str(item, ['subjectName', 'subject']);
    final due = _dueDate(item);
    final badge = _dueBadge(due);
    final id = _str(item, ['assignmentId', 'id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id == null
              ? () => widget.onNavigate(2)
              : () => context.push('/teacher/assignments/details/$id'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
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
                          if (className != null) className,
                          if (due != null) _shortDate(due),
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
    if (days <= 7)
      return (label: 'In $days days', color: Colors.orange.shade700);
    return (label: _shortDate(due), color: _primary);
  }

  // ================================================================
  // STATE CARDS
  // ================================================================

  /// Shimmer skeleton for a section that is still loading.
  Widget _loadingCard({int count = 2}) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ShimmerCard(trailing: i.isEven),
          ],
        ],
      ),
    );
  }

  Widget _errorCard({required String message, required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
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

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: _primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primary, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DATA HELPERS
  // ================================================================

  List<dynamic> _list(dynamic data, List<String> keys) {
    if (data is List) return data;

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _list(value, keys);
          if (nested.isNotEmpty) return nested;
        }
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

  /// Teacher name from the profile response (flat or nested).
  String? _teacherName(dynamic data) {
    if (data is! Map) return null;

    final first = _str(data, ['firstName', 'firstname', 'first_name']);
    final last = _str(data, ['lastName', 'lastname', 'last_name', 'surname']);

    if (first != null) return last != null ? '$first $last' : first;

    final full = _str(data, ['fullName', 'name', 'displayName', 'teacherName']);
    if (full != null) return full;

    for (final key in ['teacher', 'user', 'profile', 'data']) {
      final nested = _teacherName(data[key]);
      if (nested != null) return nested;
    }

    return null;
  }

  int? _studentsIn(dynamic item) {
    if (item is! Map) return null;

    final value =
        item['studentCount'] ?? item['studentsCount'] ?? item['students'];

    if (value is num) return value.toInt();
    if (value is List) return value.length;
    return null;
  }

  /// Merges class-teacher classes and subject-teaching rows into one
  /// entry per class.
  ///
  /// Example with your data:
  ///   Year 10 -> Class teacher · Livestock Farming
  ///   Year 11 -> Livestock Farming
  ///   Year 12 -> Livestock Farming
  ///
  /// Class-teacher classes come first, then the rest by name.
  List<_MyClass> _mergeClasses(
    List<dynamic> classTeacherRows,
    List<dynamic> subjectRows,
  ) {
    final byId = <String, _MyClass>{};

    for (final row in classTeacherRows) {
      final id = _str(row, ['classId', 'id']);
      if (id == null) continue;

      final entry = byId.putIfAbsent(
        id,
        () =>
            _MyClass(id: id, name: _str(row, ['className', 'name']) ?? 'Class'),
      );

      entry.isClassTeacher = true;
      entry.reportedStudents ??= _studentsIn(row);
    }

    for (final row in subjectRows) {
      final id = _str(row, ['classId']);
      if (id == null) continue;

      final entry = byId.putIfAbsent(
        id,
        () => _MyClass(id: id, name: _str(row, ['className']) ?? 'Class'),
      );

      final subject = _str(row, ['subjectName', 'subject']);
      if (subject != null && !entry.subjects.contains(subject)) {
        entry.subjects.add(subject);
      }
    }

    final result = byId.values.toList()
      ..sort((a, b) {
        if (a.isClassTeacher != b.isClassTeacher) {
          return a.isClassTeacher ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return result;
  }

  Set<String> _studentIds(dynamic data) {
    final ids = <String>{};

    for (final student in _list(data, ['students', 'data'])) {
      final id = _str(student, ['studentId', 'id']);
      if (id != null) ids.add(id);
    }

    return ids;
  }

  DateTime? _dueDate(dynamic item) {
    final raw = _str(item, ['dueDate', 'deadline']);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
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

  /// MONDAY, 26 OCT
  String _todayLabel() {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}'
        .toUpperCase();
  }

  /// 26 Oct
  String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
}

// ==================================================================
// MERGED CLASS MODEL
// ==================================================================

class _MyClass {
  _MyClass({required this.id, required this.name});

  final String id;
  final String name;

  /// True when the teacher is this class's class teacher.
  bool isClassTeacher = false;

  /// Subjects the teacher teaches in this class.
  final List<String> subjects = [];

  /// studentCount from /teacher/classes, used until the real list loads.
  int? reportedStudents;
}