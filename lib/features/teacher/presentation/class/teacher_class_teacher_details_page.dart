import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/teacher/presentation/class/teacher_class_attendance_page.dart';
import 'package:app/features/teacher/presentation/student/teacher_students_page.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// CLASS TEACHER HUB
// ==================================================================
// Opened from a "Class teacher" card. Shows the class at a glance:
//   • today's register: taken or not, how many marked
//   • overall class-register attendance rate
//   • students
// and opens the class register (attendance with SubjectId = null).
//
// Same constructor as before, so the existing route keeps working.
// ==================================================================

class TeacherClassTeacherDetailsPage extends ConsumerStatefulWidget {
  const TeacherClassTeacherDetailsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  // Kept so any code that still reads these keeps compiling.
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  ConsumerState<TeacherClassTeacherDetailsPage> createState() =>
      _TeacherClassTeacherDetailsPageState();
}

class _TeacherClassTeacherDetailsPageState
    extends ConsumerState<TeacherClassTeacherDetailsPage> {
  late final TeacherClassAttendanceParams _todayParams;
  late final TeacherClassAttendanceParams _historyParams;

  static const _emptyGuid = '00000000-0000-0000-0000-000000000000';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayParams = TeacherClassAttendanceParams(
      classId: widget.classId,
      subjectId: '',
      date: _apiDate(DateTime(now.year, now.month, now.day)),
    );
    _historyParams = TeacherClassAttendanceParams(
      classId: widget.classId,
      subjectId: '',
      date: null,
    );
  }

  void _invalidate() {
    ref.invalidate(teacherStudentsProvider(widget.classId));
    ref.invalidate(teacherClassAttendanceProvider(_todayParams));
    ref.invalidate(teacherClassAttendanceProvider(_historyParams));
  }

  Future<void> _refresh() async {
    _invalidate();
    await Future.wait([
      sSafe(ref.read(teacherStudentsProvider(widget.classId).future)),
      sSafe(ref.read(teacherClassAttendanceProvider(_todayParams).future)),
      sSafe(ref.read(teacherClassAttendanceProvider(_historyParams).future)),
    ]);
  }

  Future<void> _openRegister() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherClassAttendancePage(
          classId: widget.classId,
          className: widget.className,
          subjectId: null,
          subjectName: 'Class attendance',
        ),
      ),
    );
    if (mounted) _invalidate();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider(widget.classId));
    final todayAsync = ref.watch(teacherClassAttendanceProvider(_todayParams));
    final historyAsync = ref.watch(
      teacherClassAttendanceProvider(_historyParams),
    );

    final students = sList(studentsAsync.valueOrNull, ['students', 'data']);
    final today = _classOnly(sList(todayAsync.valueOrNull, ['attendance', 'data']));
    final history = _classOnly(
      sList(historyAsync.valueOrNull, ['attendance', 'data']),
    );

    final markedToday = today
        .map((r) => sStr(r, ['studentId']))
        .whereType<String>()
        .toSet()
        .length;
    final todayCounts = _count(today);
    final allCounts = _count(history);

    final days = history
        .map((r) => sDay(r, ['attendanceDate', 'date']))
        .whereType<DateTime>()
        .toSet()
        .length;

    final studentsLoading = studentsAsync.isLoading && !studentsAsync.hasValue;
    final todayLoading = todayAsync.isLoading && !todayAsync.hasValue;
    final historyLoading = historyAsync.isLoading && !historyAsync.hasValue;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        widget.className,
        subtitle: 'Class teacher',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _invalidate,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          children: [
            _hero(
              students: studentsLoading ? null : students.length,
              rate: allCounts.rate,
              rateLoading: historyLoading,
              days: days,
            ),

            const SizedBox(height: 18),

            _todayCard(
              loading: todayLoading || studentsLoading,
              marked: markedToday,
              total: students.length,
              present: todayCounts.present + todayCounts.late,
              absent: todayCounts.absent,
            ),

            const SizedBox(height: 22),
            const SectionHeader('Manage class'),
            const SizedBox(height: 12),

            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _row(
                    icon: Icons.fact_check_rounded,
                    title: 'Class register',
                    subtitle: 'Mark daily attendance',
                    color: const Color(0xFF16A34A),
                    onTap: _openRegister,
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _row(
                    icon: Icons.insights_rounded,
                    title: 'Register history',
                    subtitle: days == 0
                        ? 'No days recorded yet'
                        : '$days day${days == 1 ? '' : 's'} · by date and by student',
                    color: const Color(0xFF0D9488),
                    onTap: _openRegister,
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _row(
                    icon: Icons.groups_rounded,
                    title: 'Students',
                    subtitle: 'Profiles, results across all subjects, tasks',
                    color: const Color(0xFF7C3AED),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherStudentsPage(initialClassId: widget.classId),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (allCounts.absent > 0) ...[
              const SizedBox(height: 22),
              const SectionHeader(
                'Most absences',
                subtitle: 'Students who may need a follow-up',
              ),
              const SizedBox(height: 12),
              _absenceList(history, students),
            ],
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HERO
  // ================================================================

  Widget _hero({
    required int? students,
    required double? rate,
    required bool rateLoading,
    required int days,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ProgressRing(
            value: (rate ?? 0) / 100,
            size: 88,
            stroke: 8,
            child: rateLoading
                ? const Shimmer(
                    child: ShimmerBox(width: 30, height: 14, onDark: true),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'register',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CLASS TEACHER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.className,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    HeroStat(
                      'Students',
                      '${students ?? ''}',
                      loading: students == null,
                    ),
                    HeroStat('Days marked', '$days', loading: rateLoading),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TODAY
  // ================================================================

  Widget _todayCard({
    required bool loading,
    required int marked,
    required int total,
    required int present,
    required int absent,
  }) {
    if (loading) {
      return const Shimmer(child: ShimmerCard(height: 128));
    }

    final done = total > 0 && marked >= total;
    final started = marked > 0;
    final color = done
        ? Colors.green.shade600
        : started
        ? Colors.orange.shade700
        : StudentColors.primary;

    return SoftCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: .25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                done
                    ? Icons.task_alt_rounded
                    : started
                    ? Icons.pending_actions_rounded
                    : Icons.how_to_reg_rounded,
                color: color,
                size: 46,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s register',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done
                          ? 'Done · $present present, $absent absent'
                          : started
                          ? '$marked of $total marked'
                          : 'Not taken yet',
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (marked / total).clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _openRegister,
              style: FilledButton.styleFrom(
                backgroundColor: done ? Colors.white : color,
                foregroundColor: done ? color : Colors.white,
                side: done ? BorderSide(color: color) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                done ? Icons.edit_rounded : Icons.fact_check_rounded,
                size: 19,
              ),
              label: Text(
                done
                    ? 'Review today\'s register'
                    : started
                    ? 'Finish today\'s register'
                    : 'Take today\'s register',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ABSENCES
  // ================================================================

  Widget _absenceList(List<dynamic> history, List<dynamic> students) {
    final absences = <String, int>{};
    final names = <String, String>{};

    for (final s in students) {
      final id = sStr(s, ['studentId', 'id']);
      final name = sStr(s, ['studentName', 'fullName', 'name']);
      if (id != null && name != null) names[id] = name;
    }

    for (final r in history) {
      if (sStr(r, ['status'])?.toLowerCase() != 'absent') continue;
      final id = sStr(r, ['studentId']);
      if (id == null) continue;
      absences[id] = (absences[id] ?? 0) + 1;
      names[id] ??= sStr(r, ['studentName', 'fullName']) ?? 'Student';
    }

    final top = absences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < top.length && i < 5; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      studentInitials(names[top[i].key], fallback: '?'),
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      names[top[i].key] ?? 'Student',
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${top[i].value} absent',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // PIECES
  // ================================================================

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            IconBadge(icon, color: color, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// Class-register records only (no subject).
  List<dynamic> _classOnly(List<dynamic> records) {
    return records.where((r) {
      final s = sStr(r, ['subjectId']);
      return s == null || s == _emptyGuid;
    }).toList();
  }

  ({int present, int absent, int late, double? rate}) _count(List<dynamic> r) {
    var present = 0, absent = 0, late = 0;
    for (final x in r) {
      switch (sStr(x, ['status'])?.toLowerCase()) {
        case 'present':
          present++;
        case 'absent':
          absent++;
        case 'late':
          late++;
      }
    }
    final counted = present + absent + late;
    return (
      present: present,
      absent: absent,
      late: late,
      rate: counted == 0 ? null : (present + late) / counted * 100,
    );
  }

  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
