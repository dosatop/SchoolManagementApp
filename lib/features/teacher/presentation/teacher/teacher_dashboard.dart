import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/teacher/presentation/assignment/teacher_assignments_page.dart';
import 'package:app/features/teacher/presentation/attendance/teacher_attendance_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_class_attendance_page.dart';
import 'package:app/features/teacher/presentation/class/teacher_classes-page.dart';
import 'package:app/features/teacher/presentation/student/teacher_students_page.dart';
import 'package:app/features/teacher/presentation/teacher/teacher_profile_page.dart';
import 'package:app/features/teacher/presentation/teacher_timetable_page.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _primary = StudentColors.primary;
const _textDark = StudentColors.textDark;

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
  static const _exitDelay = Duration(seconds: 2);

  int _currentIndex = 0;
  DateTime? _lastBack;

  void _goToTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  // Other tab -> Home. Home -> press twice to exit.
  void _handleBack() {
    if (_currentIndex != 0) {
      _goToTab(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) <= _exitDelay) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: StudentColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _TeacherHomePage(onNavigate: _goToTab),
            const TeacherClassesPage(),
            const TeacherAssignmentsPage(),
            const TeacherProfilePage(),
          ],
        ),
        bottomNavigationBar: Container(
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            indicatorColor: StudentColors.primaryLight,
            elevation: 0,
            height: 68,
            selectedIndex: _currentIndex,
            onDestinationSelected: _goToTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: _primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.class_outlined),
                selectedIcon: Icon(Icons.class_rounded, color: _primary),
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
        ),
      ),
    );
  }
}

// ==================================================================
// HOME TAB
// ==================================================================

class _TeacherHomePage extends ConsumerStatefulWidget {
  const _TeacherHomePage({required this.onNavigate});

  /// 1 = Classes, 2 = Tasks, 3 = Profile.
  final ValueChanged<int> onNavigate;

  @override
  ConsumerState<_TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<_TeacherHomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final profileAsync = ref.watch(teacherProfileProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    // "My classes" = class-teacher classes + classes I teach a subject in.
    final classTeacherAsync = ref.watch(teacherClassesProvider);
    final subjectsAsync = ref.watch(teacherSubjectsProvider);

    final myClasses = _mergeClasses(
      sList(classTeacherAsync.valueOrNull, ['classes', 'data']),
      sList(subjectsAsync.valueOrNull, ['subjects', 'data']),
    );

    final classesLoading =
        (classTeacherAsync.isLoading && !classTeacherAsync.hasValue) ||
        (subjectsAsync.isLoading && !subjectsAsync.hasValue);
    final classesFailed =
        classTeacherAsync.hasError &&
        subjectsAsync.hasError &&
        myClasses.isEmpty;

    // Students per class.
    final studentsByClass = <String, Set<String>>{};
    var studentsLoading = false;
    for (final c in myClasses) {
      final async = ref.watch(teacherStudentsProvider(c.id));
      if (async.isLoading && !async.hasValue) {
        studentsLoading = true;
        continue;
      }
      studentsByClass[c.id] = {
        for (final s in sList(async.valueOrNull, ['students', 'data']))
          if (sStr(s, ['studentId', 'id']) != null) sStr(s, ['studentId', 'id'])!,
      };
    }
    final uniqueStudents = studentsByClass.values.fold<Set<String>>(
      {},
      (all, ids) => all..addAll(ids),
    );

    final teacherName = _teacherName(profileAsync.valueOrNull);
    final assignments = sList(assignmentsAsync.valueOrNull, [
      'assignments',
      'data',
    ]);

    final registerClasses = myClasses.where((c) => c.isClassTeacher).toList();

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
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            children: [
              _hero(
                name: profileAsync.isLoading && teacherName == null
                    ? null
                    : teacherName ?? 'Teacher',
                classes: classesLoading ? null : myClasses.length,
                students: classesLoading || studentsLoading
                    ? null
                    : uniqueStudents.length,
                assignments: assignmentsAsync.isLoading && assignments.isEmpty
                    ? null
                    : assignments.length,
              ),

              // ------------------------------------------------------
              // CLASS REGISTER (class teachers only)
              // ------------------------------------------------------
              if (registerClasses.isNotEmpty) ...[
                const SizedBox(height: 22),
                const SectionHeader(
                  'Class register',
                  subtitle: 'Take today\'s attendance for your class',
                ),
                const SizedBox(height: 12),
                for (final c in registerClasses) ...[
                  _registerCard(c, studentsByClass[c.id]?.length),
                  const SizedBox(height: 10),
                ],
              ],

              const SizedBox(height: 22),
              const SectionHeader('Quick actions'),
              const SizedBox(height: 12),
              _quickActions(),

              const SizedBox(height: 24),
              SectionHeader(
                'My classes',
                subtitle: myClasses.isEmpty
                    ? null
                    : '${myClasses.length} class${myClasses.length == 1 ? '' : 'es'}',
                actionLabel: myClasses.length > 4 ? 'See all' : null,
                onAction: () => widget.onNavigate(1),
              ),
              const SizedBox(height: 12),
              _classesSection(
                loading: classesLoading,
                failed: classesFailed,
                classes: myClasses,
                studentsByClass: studentsByClass,
              ),

              const SizedBox(height: 24),
              SectionHeader(
                'Upcoming assignments',
                actionLabel: assignments.isEmpty ? null : 'See all',
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

  Future<void> _refresh() async {
    final current = _mergeClasses(
      sList(ref.read(teacherClassesProvider).valueOrNull, ['classes', 'data']),
      sList(ref.read(teacherSubjectsProvider).valueOrNull, [
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

    await Future.wait([
      sSafe(ref.read(teacherProfileProvider.future)),
      sSafe(ref.read(teacherClassesProvider.future)),
      sSafe(ref.read(teacherSubjectsProvider.future)),
      sSafe(ref.read(teacherAssignmentsProvider.future)),
    ]);
  }

  // ================================================================
  // HERO
  // ================================================================

  Widget _hero({
    required String? name,
    required int? classes,
    required int? students,
    required int? assignments,
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
          Positioned(right: -40, top: -40, child: _bubble(150, .07)),
          Positioned(left: -30, bottom: -50, child: _bubble(120, .05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
                            '${sWeekday(DateTime.now())}, '
                                    '${sShortDate(DateTime.now())}'
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .65),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _greeting(),
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
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigate(3),
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .35),
                            width: 2,
                          ),
                        ),
                        child: initials.isEmpty
                            ? const Icon(Icons.person_rounded, color: Colors.white)
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
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Row(
                    children: [
                      _heroStat('Classes', classes, () => widget.onNavigate(1)),
                      _divider(),
                      _heroStat(
                        'Students',
                        students,
                        () => _open(const TeacherStudentsPage()),
                      ),
                      _divider(),
                      _heroStat(
                        'Assignments',
                        assignments,
                        () => widget.onNavigate(2),
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

  Widget _heroStat(String label, int? value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [HeroStat(label, '${value ?? ''}', loading: value == null)],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: Colors.white.withValues(alpha: .18),
  );

  Widget _bubble(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );

  // ================================================================
  // CLASS REGISTER CARD
  // ================================================================

  Widget _registerCard(_MyClass c, int? students) {
    return SoftCard(
      onTap: () => _openClassTeacher(c),
      padding: const EdgeInsets.all(14),
      borderColor: Colors.green.shade100,
      child: Row(
        children: [
          IconBadge(Icons.how_to_reg_rounded, color: Colors.green.shade600),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  students == null
                      ? 'Class teacher'
                      : 'Class teacher · $students student${students == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _open(
              TeacherClassAttendancePage(
                classId: c.id,
                className: c.name,
                subjectId: null,
                subjectName: 'Class attendance',
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.fact_check_rounded, size: 16),
            label: const Text(
              'Register',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK ACTIONS
  // ================================================================

  Widget _quickActions() {
    final items = [
      (
        Icons.fact_check_rounded,
        'Attendance',
        const Color(0xFF16A34A),
        () => _open(const TeacherAttendancePage()),
      ),
      (
        Icons.groups_rounded,
        'Students',
        const Color(0xFF7C3AED),
        () => _open(const TeacherStudentsPage()),
      ),
      (
        Icons.calendar_month_rounded,
        'Timetable',
        const Color(0xFF2563EB),
        () => _open(const TeacherTimetablePage()),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: SoftCard(
              onTap: items[i].$4,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  IconBadge(
                    items[i].$1,
                    color: items[i].$3,
                    size: 46,
                    circle: true,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    items[i].$2,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
    if (loading && classes.isEmpty) {
      return const Shimmer(
        child: Column(
          children: [ShimmerCard(), SizedBox(height: 10), ShimmerCard()],
        ),
      );
    }

    if (failed) {
      return _errorCard('Unable to load your classes', () {
        ref.invalidate(teacherClassesProvider);
        ref.invalidate(teacherSubjectsProvider);
      });
    }

    if (classes.isEmpty) {
      return _emptyCard(
        Icons.class_outlined,
        'No classes yet',
        'Classes assigned to you by the admin will show up here.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < classes.length && i < 4; i++) ...[
          _classCard(
            classes[i],
            StudentColors.accents[i % StudentColors.accents.length],
            studentsByClass[classes[i].id]?.length ??
                classes[i].reportedStudents,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _classCard(_MyClass item, Color color, int? students) {
    return SoftCard(
      onTap: () => _openClass(item),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: .75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _short(item.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.isClassTeacher) ...[
                      const SizedBox(width: 8),
                      _tag('Class teacher', Colors.green.shade700),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.subjects.isNotEmpty)
                      item.subjects.map((s) => s.name).join(', '),
                    if (students != null)
                      '$students student${students == 1 ? '' : 's'}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  /// Opens the right page for a class:
  ///   one subject only -> that subject's class page
  ///   class teacher only -> class teacher hub
  ///   otherwise -> Classes tab (pick there)
  void _openClass(_MyClass c) {
    if (c.subjects.length == 1 && !c.isClassTeacher) {
      final s = c.subjects.first;
      context.push(
        '/teacher/classes/details',
        extra: {
          'subjectId': s.id,
          'subjectName': s.name,
          'classId': c.id,
          'className': c.name,
          'isClassTeacher': false,
        },
      );
      return;
    }
    if (c.subjects.isEmpty && c.isClassTeacher) {
      _openClassTeacher(c);
      return;
    }
    widget.onNavigate(1);
  }

  void _openClassTeacher(_MyClass c) {
    context.push(
      '/teacher/classes/class-teacher-details',
      extra: {'classId': c.id, 'className': c.name},
    );
  }

  // ================================================================
  // UPCOMING ASSIGNMENTS
  // ================================================================

  Widget _assignmentsSection(AsyncValue<dynamic> async, List<dynamic> list) {
    if (async.isLoading && list.isEmpty) {
      return const Shimmer(
        child: Column(
          children: [ShimmerCard(), SizedBox(height: 10), ShimmerCard()],
        ),
      );
    }

    if (async.hasError && list.isEmpty) {
      return _errorCard(
        'Unable to load assignments',
        () => ref.invalidate(teacherAssignmentsProvider),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming =
        list.where((a) {
          final due = sLocal(a, ['dueDate', 'deadline']);
          return due == null || !due.isBefore(today);
        }).toList()..sort((a, b) {
          final da = sLocal(a, ['dueDate', 'deadline']);
          final db = sLocal(b, ['dueDate', 'deadline']);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

    if (upcoming.isEmpty) {
      return _emptyCard(
        Icons.task_alt_rounded,
        'All caught up',
        'You have no upcoming assignments.',
      );
    }

    return Column(
      children: [
        for (final a in upcoming.take(3)) ...[
          _assignmentCard(a),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _assignmentCard(dynamic item) {
    final title = sStr(item, ['title', 'name']) ?? 'Assignment';
    final className = sStr(item, ['className', 'class']);
    final subject = sStr(item, ['subjectName', 'subject']);
    final due = sLocal(item, ['dueDate', 'deadline']);
    final badge = _dueBadge(due);
    final id = sStr(item, ['assignmentId', 'id']);
    final submissions = sNum(item, ['submissionCount', 'submissionsCount']);

    return SoftCard(
      onTap: id == null
          ? () => widget.onNavigate(2)
          : () => context.push('/teacher/assignments/details/$id'),
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (subject != null) subject,
                              if (className != null) className,
                              if (submissions != null)
                                '${submissions.toInt()} submitted',
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
                    _tag(badge.label, badge.color),
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
    if (days < 0) return (label: 'Closed', color: Colors.grey.shade600);
    if (days == 0) return (label: 'Today', color: Colors.red.shade600);
    if (days == 1) return (label: 'Tomorrow', color: Colors.orange.shade700);
    if (days <= 7) {
      return (label: 'In $days days', color: Colors.orange.shade700);
    }
    return (label: sShortDate(due), color: _primary);
  }

  // ================================================================
  // SMALL PIECES
  // ================================================================

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _errorCard(String message, VoidCallback onRetry) {
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
              message,
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

  Widget _emptyCard(IconData icon, String title, String message) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconBadge(icon, color: _primary, size: 46, circle: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DATA HELPERS
  // ================================================================

  String? _teacherName(dynamic data) {
    if (data is! Map) return null;

    final first = sStr(data, ['firstName', 'firstname', 'first_name']);
    final last = sStr(data, ['lastName', 'lastname', 'last_name', 'surname']);
    if (first != null) return last != null ? '$first $last' : first;

    final full = sStr(data, ['fullName', 'name', 'displayName', 'teacherName']);
    if (full != null) return full;

    for (final key in ['teacher', 'user', 'profile', 'data']) {
      final nested = _teacherName(data[key]);
      if (nested != null) return nested;
    }
    return null;
  }

  int? _studentsIn(dynamic item) {
    if (item is! Map) return null;
    final v = item['studentCount'] ?? item['studentsCount'] ?? item['students'];
    if (v is num) return v.toInt();
    if (v is List) return v.length;
    return null;
  }

  /// One entry per class from class-teacher classes + subject rows.
  /// Class-teacher classes first, then by name.
  List<_MyClass> _mergeClasses(List<dynamic> classRows, List<dynamic> subjectRows) {
    final byId = <String, _MyClass>{};

    for (final row in classRows) {
      final id = sStr(row, ['classId', 'id']);
      if (id == null) continue;
      final entry = byId.putIfAbsent(
        id,
        () => _MyClass(id: id, name: sStr(row, ['className', 'name']) ?? 'Class'),
      );
      entry.isClassTeacher = true;
      entry.reportedStudents ??= _studentsIn(row);
    }

    for (final row in subjectRows) {
      final id = sStr(row, ['classId']);
      if (id == null) continue;
      final entry = byId.putIfAbsent(
        id,
        () => _MyClass(id: id, name: sStr(row, ['className']) ?? 'Class'),
      );
      final subjectId = sStr(row, ['subjectId']);
      final subjectName = sStr(row, ['subjectName', 'subject']);
      if (subjectId != null &&
          subjectName != null &&
          !entry.subjects.any((s) => s.id == subjectId)) {
        entry.subjects.add((id: subjectId, name: subjectName));
      }
    }

    return byId.values.toList()
      ..sort((a, b) {
        if (a.isClassTeacher != b.isClassTeacher) {
          return a.isClassTeacher ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  String _short(String className) {
    final digits = RegExp(r'\d+').firstMatch(className)?.group(0);
    final letters = className
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !RegExp(r'^\d+$').hasMatch(w))
        .map((w) => w[0].toUpperCase())
        .take(digits == null ? 3 : 2)
        .join();
    return '$letters${digits ?? ''}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }
}

// ==================================================================
// MERGED CLASS MODEL
// ==================================================================

class _MyClass {
  _MyClass({required this.id, required this.name});

  final String id;
  final String name;
  bool isClassTeacher = false;
  final List<({String id, String name})> subjects = [];
  int? reportedStudents;
}
