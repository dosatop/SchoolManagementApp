import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// TEACHER: STUDENT DETAILS
// ==================================================================
// GET /teacher/students/{id} →
// {
//   student: { studentId, studentName, studentNumber, email,
//              phoneNumber, classId, className },
//   isClassTeacher,
//   teacherSubjects: [{ subjectId, subjectName }],
//   results: [{ subjectName, session, term, score, testScore,
//               examScore, grade, gradeRemark, remark, createdAt }],
//   attendance: { summary, classAttendance, subjectAttendance,
//                 records: [{ type, subjectName, attendanceDate,
//                             status, remarks }] },
//   assignments: [{ title, subjectName, dueDate, isPublished,
//                   submission: { submittedAt, score, isGraded } | null }]
// }
//
// Tabs: Overview · Results · Attendance · Tasks
//
// `student` is the list item you tapped (shown instantly while the
// details load). `isClassTeacher` is only a fallback — the server's
// value wins.

class TeacherStudentDetailsPage extends ConsumerStatefulWidget {
  const TeacherStudentDetailsPage({
    super.key,
    required this.student,
    required this.isClassTeacher,
  });

  final dynamic student;
  final bool isClassTeacher;

  @override
  ConsumerState<TeacherStudentDetailsPage> createState() =>
      _TeacherStudentDetailsPageState();
}

enum _AttendanceFilter { all, classOnly, subjectOnly }

class _TeacherStudentDetailsPageState
    extends ConsumerState<TeacherStudentDetailsPage> {
  _AttendanceFilter _attendanceFilter = _AttendanceFilter.all;

  /// The tapped student, whatever shape the router passed:
  ///   • the student map itself      { studentId, studentName, ... }
  ///   • a wrapper                    { student: {...}, isClassTeacher }
  ///   • just the ID                  "f543089b-..."
  dynamic get _student {
    final s = widget.student;
    if (s is Map && s['student'] is Map) return s['student'];
    if (s is Map && s['data'] is Map) return s['data'];
    return s;
  }

  String? get _studentId {
    final raw = widget.student;
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();

    return sStr(_student, ['studentId', 'id', 'studentProfileId']);
  }

  /// Fallback class-teacher flag (the server's value still wins).
  bool get _fallbackIsClassTeacher {
    final s = widget.student;
    if (s is Map && s['isClassTeacher'] is bool) {
      return s['isClassTeacher'] as bool;
    }
    return widget.isClassTeacher;
  }

  Future<void> _refresh() async {
    final id = _studentId;
    if (id == null) return;
    ref.invalidate(teacherStudentDetailsProvider(id));
    await sSafe(ref.read(teacherStudentDetailsProvider(id).future));
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final id = _studentId;
    final async = id == null
        ? null
        : ref.watch(teacherStudentDetailsProvider(id));

    final data = _unwrap(async?.valueOrNull);
    final student = data['student'] is Map ? data['student'] : _student;

    final name =
        sStr(student, ['studentName', 'fullName', 'name']) ??
        sStr(_student, ['studentName', 'fullName', 'name']) ??
        'Student';

    final isClassTeacher = data['isClassTeacher'] is bool
        ? data['isClassTeacher'] as bool
        : _fallbackIsClassTeacher;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: StudentColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: StudentColors.textDark,
          elevation: 0,
          titleSpacing: 4,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Student details',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: id == null ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: StudentColors.primary,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: StudentColors.primary,
            indicatorWeight: 3,
            dividerColor: Colors.grey.shade200,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Results'),
              Tab(text: 'Attendance'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        body: () {
          if (id == null) {
            return StudentEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Student not found',
              message: widget.student == null
                  ? 'The student was lost when the app restarted. '
                        'Go back and open the student again.'
                  : 'This student has no ID, so their details can\'t load.',
            );
          }

          if (async!.isLoading && !async.hasValue) {
            return const StudentLoadingView();
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: _refresh,
              title: 'Unable to load student details',
            );
          }

          final results = sList(data['results']);
          final attendance = data['attendance'];
          final assignments = sList(data['assignments']);
          final subjects = sList(data['teacherSubjects']);

          return TabBarView(
            children: [
              _tab(
                _overview(
                  student: student,
                  name: name,
                  isClassTeacher: isClassTeacher,
                  subjects: subjects,
                  results: results,
                  attendance: attendance,
                  assignments: assignments,
                ),
              ),
              _tab(_resultsTab(results, isClassTeacher)),
              _tab(_attendanceTab(attendance, isClassTeacher, subjects)),
              _tab(_assignmentsTab(assignments, isClassTeacher)),
            ],
          );
        }(),
      ),
    );
  }

  Widget _tab(List<Widget> children) {
    return RefreshIndicator(
      color: StudentColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: children,
      ),
    );
  }

  // ================================================================
  // OVERVIEW
  // ================================================================

  List<Widget> _overview({
    required dynamic student,
    required String name,
    required bool isClassTeacher,
    required List<dynamic> subjects,
    required List<dynamic> results,
    required dynamic attendance,
    required List<dynamic> assignments,
  }) {
    final className = sStr(student, ['className', 'class']);
    final number = sStr(student, ['studentNumber', 'admissionNumber']);
    final email = sStr(student, ['email']);
    final phone = sStr(student, ['phoneNumber', 'phone']);

    final summary = attendance is Map ? attendance['summary'] : null;
    final rate = sNum(summary, ['percentage', 'attendancePercentage']);

    final latest = _termGroups(results).firstOrNull;
    final average = latest?.average;

    final submitted = assignments.where(_isSubmitted).length;

    return [
      // ---------------- HEADER ----------------
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [StudentColors.primary, Color(0xFF2437C5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
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
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: StudentColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (className != null) _pill(Icons.groups_outlined, className),
                if (number != null) _pill(Icons.badge_outlined, 'No. $number'),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _headerStat(
                  'Attendance',
                  rate == null ? '—' : '${_fmt(rate)}%',
                ),
                _headerStat(
                  latest == null ? 'Average' : 'Avg · ${latest.shortLabel}',
                  average == null ? '—' : '${_fmt(average)}%',
                ),
                _headerStat(
                  'Tasks done',
                  assignments.isEmpty
                      ? '—'
                      : '$submitted/${assignments.length}',
                ),
              ],
            ),
          ],
        ),
      ),

      // ---------------- YOUR ROLE ----------------
      const SizedBox(height: 22),
      _title('Your role'),
      const SizedBox(height: 10),
      _card(
        Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isClassTeacher)
                _roleChip(Icons.star_rounded, 'Class teacher', Colors.green),
              for (final s in subjects)
                _roleChip(
                  Icons.menu_book_outlined,
                  sStr(s, ['subjectName', 'name']) ?? 'Subject',
                  StudentColors.primary,
                ),
              if (!isClassTeacher && subjects.isEmpty)
                Text(
                  'No role found for this class.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
            ],
          ),
        ),
      ),

      // ---------------- CONTACT ----------------
      if (email != null || phone != null) ...[
        const SizedBox(height: 22),
        _title('Contact'),
        const SizedBox(height: 10),
        _card(
          Column(
            children: [
              if (email != null)
                _contactRow(Icons.email_outlined, 'Email', email),
              if (email != null && phone != null)
                Divider(height: 1, color: Colors.grey.shade200),
              if (phone != null)
                _contactRow(Icons.phone_outlined, 'Phone', phone),
            ],
          ),
        ),
      ],

      // ---------------- LATEST TERM ----------------
      if (latest != null) ...[
        const SizedBox(height: 22),
        _title('Latest results · ${latest.label}'),
        const SizedBox(height: 10),
        _card(
          Column(
            children: [
              for (var i = 0; i < latest.results.length; i++) ...[
                if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                _compactResultRow(latest.results[i]),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: _iconBox(icon, StudentColors.primary),
      title: Text(
        label,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: StudentColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: IconButton(
        tooltip: 'Copy',
        icon: Icon(Icons.copy_rounded, size: 18, color: Colors.grey.shade400),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                content: Text('$label copied'),
              ),
            );
        },
      ),
    );
  }

  Widget _compactResultRow(dynamic r) {
    final subject = sStr(r, ['subjectName', 'subject']) ?? 'Subject';
    final score = sNum(r, ['score', 'totalScore']);
    final grade = sStr(r, ['grade']);
    final color = _gradeColor(grade);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              subject,
              style: const TextStyle(
                color: StudentColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            score == null ? '—' : _fmt(score),
            style: const TextStyle(
              color: StudentColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          _gradeBadge(grade, color, size: 30),
        ],
      ),
    );
  }

  // ================================================================
  // RESULTS
  // ================================================================

  List<Widget> _resultsTab(List<dynamic> results, bool isClassTeacher) {
    if (results.isEmpty) {
      return [
        _emptyBox(
          Icons.bar_chart_rounded,
          'No results yet',
          isClassTeacher
              ? 'Results for every subject will show here once uploaded.'
              : 'Results for your subjects will show here once uploaded.',
        ),
      ];
    }

    final groups = _termGroups(results);

    return [
      _hint(
        isClassTeacher
            ? 'As class teacher you see results for every subject.'
            : 'You see results for the subjects you teach.',
      ),
      const SizedBox(height: 14),
      for (final group in groups) ...[
        Row(
          children: [
            Expanded(child: _title(group.label)),
            if (group.average != null)
              Text(
                'Avg ${_fmt(group.average!)}%',
                style: const TextStyle(
                  color: StudentColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final r in group.results) ...[
          _resultCard(r),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _resultCard(dynamic r) {
    final subject = sStr(r, ['subjectName', 'subject']) ?? 'Subject';
    final test = sNum(r, ['testScore']);
    final exam = sNum(r, ['examScore']);
    final score =
        sNum(r, ['score', 'totalScore']) ??
        (test != null && exam != null ? test + exam : null);
    final grade = sStr(r, ['grade']);
    final remark = sStr(r, ['remark', 'gradeRemark']);
    final color = _gradeColor(grade);

    return _card(
      Padding(
        padding: const EdgeInsets.all(14),
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
                        subject,
                        style: const TextStyle(
                          color: StudentColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        score == null ? 'Not complete' : '${_fmt(score)} / 100',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _gradeBadge(grade, color),
              ],
            ),
            if (score != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (score / 100).clamp(0, 1).toDouble(),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
            if (test != null || exam != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _scorePill('Test', test),
                  const SizedBox(width: 8),
                  _scorePill('Exam', exam),
                ],
              ),
            ],
            if (remark != null) ...[
              const SizedBox(height: 8),
              Text(
                remark,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scorePill(String label, num? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudentColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label  ${value == null ? '—' : _fmt(value)}',
        style: const TextStyle(
          color: StudentColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _gradeBadge(String? grade, Color color, {double size = 42}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        shape: BoxShape.circle,
      ),
      child: Text(
        grade ?? '—',
        style: TextStyle(
          color: color,
          fontSize: size * .36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ================================================================
  // ATTENDANCE
  // ================================================================

  List<Widget> _attendanceTab(
    dynamic attendance,
    bool isClassTeacher,
    List<dynamic> subjects,
  ) {
    final map = attendance is Map ? attendance : const {};
    final classSummary = map['classAttendance'];
    final subjectSummary = map['subjectAttendance'];
    final records = sList(map['records']);

    final hasClass = classSummary is Map;
    final hasSubject = subjectSummary is Map;

    if (records.isEmpty && !hasClass && !hasSubject) {
      return [
        _emptyBox(
          Icons.fact_check_outlined,
          'No attendance yet',
          'Attendance will show here once it is marked.',
        ),
      ];
    }

    final filtered = records.where((r) {
      final isClass = _isClassRecord(r);
      return switch (_attendanceFilter) {
        _AttendanceFilter.all => true,
        _AttendanceFilter.classOnly => isClass,
        _AttendanceFilter.subjectOnly => !isClass,
      };
    }).toList();

    return [
      if (hasClass)
        _attendanceSummaryCard(
          title: 'Class register',
          subtitle: 'Daily attendance you mark as class teacher',
          icon: Icons.groups_outlined,
          color: Colors.green,
          summary: classSummary,
        ),
      if (hasClass && hasSubject) const SizedBox(height: 12),
      if (hasSubject)
        _attendanceSummaryCard(
          title: 'Your subjects',
          subtitle: subjects.isEmpty
              ? 'Attendance in your lessons'
              : subjects
                    .map((s) => sStr(s, ['subjectName', 'name']))
                    .whereType<String>()
                    .join(', '),
          icon: Icons.menu_book_outlined,
          color: Colors.blue,
          summary: subjectSummary,
        ),

      const SizedBox(height: 22),

      Row(
        children: [
          Expanded(child: _title('History')),
          Text(
            '${filtered.length} record${filtered.length == 1 ? '' : 's'}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),

      if (hasClass && hasSubject) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _filterChip('All', _AttendanceFilter.all),
            _filterChip('Class', _AttendanceFilter.classOnly),
            _filterChip('Subjects', _AttendanceFilter.subjectOnly),
          ],
        ),
      ],

      const SizedBox(height: 12),

      if (filtered.isEmpty)
        _card(
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'No records for this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        )
      else
        for (final r in filtered) ...[
          _attendanceRecord(r),
          const SizedBox(height: 8),
        ],
    ];
  }

  Widget _attendanceSummaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required dynamic summary,
  }) {
    final rate = sNum(summary, ['percentage', 'attendancePercentage']);
    final present = sNum(summary, ['present'])?.toInt() ?? 0;
    final absent = sNum(summary, ['absent'])?.toInt() ?? 0;
    final late = sNum(summary, ['late'])?.toInt() ?? 0;
    final excused = sNum(summary, ['excused'])?.toInt() ?? 0;

    return _card(
      Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                _iconBox(icon, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: StudentColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _rateRing(rate?.toDouble()),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniStat('Present', present, Colors.green),
                _miniStat('Absent', absent, Colors.red),
                _miniStat('Late', late, Colors.orange),
                _miniStat('Excused', excused, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateRing(double? rate) {
    final color = rate == null
        ? Colors.grey.shade400
        : rate >= 90
        ? Colors.green.shade600
        : rate >= 75
        ? Colors.orange.shade700
        : Colors.red.shade600;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: (rate ?? 0) / 100,
              strokeWidth: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _AttendanceFilter value) {
    final selected = _attendanceFilter == value;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _attendanceFilter = value),
      showCheckmark: false,
      selectedColor: StudentColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? StudentColors.primary : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _attendanceRecord(dynamic r) {
    final day = sDay(r, ['attendanceDate', 'date']);
    final status = _titleCase(sStr(r, ['status']) ?? 'Unknown');
    final isClass = _isClassRecord(r);
    final label = isClass
        ? 'Class register'
        : (sStr(r, ['subjectName']) ?? 'Subject');
    final remarks = sStr(r, ['remarks']);

    return _card(
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 48,
              decoration: BoxDecoration(
                color: StudentColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: day == null
                  ? const Icon(Icons.event, color: StudentColors.primary)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          sMonths[day.month - 1].toUpperCase(),
                          style: const TextStyle(
                            color: StudentColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: StudentColors.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day == null ? 'Unknown date' : sDayLabel(day),
                    style: const TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isClass
                            ? Icons.groups_outlined
                            : Icons.menu_book_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (remarks != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      remarks,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusChip(status),
          ],
        ),
      ),
    );
  }

  bool _isClassRecord(dynamic r) {
    final type = sStr(r, ['type'])?.toLowerCase();
    if (type != null) return type == 'class';
    return sStr(r, ['subjectId']) == null;
  }

  // ================================================================
  // ASSIGNMENTS
  // ================================================================

  List<Widget> _assignmentsTab(List<dynamic> assignments, bool isClassTeacher) {
    if (assignments.isEmpty) {
      return [
        _emptyBox(
          Icons.assignment_outlined,
          'No assignments',
          isClassTeacher
              ? 'Assignments given to this class will show here.'
              : 'Assignments for your subjects will show here.',
        ),
      ];
    }

    final sorted = [...assignments]
      ..sort((a, b) {
        final da = sLocal(a, ['dueDate']);
        final db = sLocal(b, ['dueDate']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    final submitted = assignments.where(_isSubmitted).length;
    final missing = assignments.where(_isMissing).length;
    final pending = assignments.length - submitted - missing;

    return [
      _card(
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _miniStat('Submitted', submitted, Colors.green),
              _miniStat('Pending', pending, Colors.orange),
              _miniStat('Missed', missing, Colors.red),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      for (final a in sorted) ...[
        _assignmentCard(a),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _assignmentCard(dynamic a) {
    final title = sStr(a, ['title', 'name']) ?? 'Assignment';
    final subject = sStr(a, ['subjectName', 'subject']);
    final description = sStr(a, ['description']);
    final due = sLocal(a, ['dueDate']);
    final sub = a is Map ? a['submission'] : null;
    final submittedAt = sLocal(sub, ['submittedAt']);
    final score = sNum(sub, ['score']);
    final isGraded = sub is Map && sub['isGraded'] == true;
    final isDraft = a is Map && a['isPublished'] == false;

    final status = sub is Map
        ? (isGraded ? 'Graded' : 'Submitted')
        : _isMissing(a)
        ? 'Overdue'
        : 'Pending';

    return _card(
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status),
              ],
            ),
            if (subject != null || isDraft) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  if (subject != null)
                    Text(
                      subject,
                      style: const TextStyle(
                        color: StudentColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (isDraft) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Draft',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _metaItem(
                  Icons.event_outlined,
                  due == null ? 'No due date' : 'Due ${sPrettyDate(due)}',
                ),
                if (submittedAt != null)
                  _metaItem(
                    Icons.check_circle_outline,
                    'Submitted ${sShortDate(submittedAt)}',
                  ),
                if (score != null)
                  _metaItem(Icons.grade_outlined, 'Score ${_fmt(score)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }

  bool _isSubmitted(dynamic a) => a is Map && a['submission'] is Map;

  bool _isMissing(dynamic a) {
    if (_isSubmitted(a)) return false;
    final due = sLocal(a, ['dueDate']);
    return due != null && due.isBefore(DateTime.now());
  }

  // ================================================================
  // SHARED BITS
  // ================================================================

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      color: StudentColors.textDark,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 21),
  );

  Widget _hint(String text) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _emptyBox(IconData icon, String title, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: StudentColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: StudentColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
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

  // ================================================================
  // DATA HELPERS
  // ================================================================

  /// Returns `data` from `{ success, data }`, or the body itself.
  Map<dynamic, dynamic> _unwrap(dynamic body) {
    if (body is Map && body['data'] is Map) return body['data'] as Map;
    if (body is Map) return body;
    return const {};
  }

  /// Results grouped by "term · session", newest first.
  List<_TermGroup> _termGroups(List<dynamic> results) {
    final groups = <String, _TermGroup>{};

    for (final r in results) {
      final term = sStr(r, ['term']);
      final session = sStr(r, ['session']);
      final key = '${term ?? ''}|${session ?? ''}';

      groups
          .putIfAbsent(key, () => _TermGroup(term: term, session: session))
          .add(r, sLocal(r, ['createdAt']));
    }

    final list = groups.values.toList()
      ..sort((a, b) {
        final la = a.latest;
        final lb = b.latest;
        if (la == null && lb == null) return 0;
        if (la == null) return 1;
        if (lb == null) return -1;
        return lb.compareTo(la);
      });

    for (final g in list) {
      g.results.sort(
        (a, b) => (sStr(a, ['subjectName']) ?? '').compareTo(
          sStr(b, ['subjectName']) ?? '',
        ),
      );
    }

    return list;
  }

  Color _gradeColor(String? grade) {
    final g = (grade == null || grade.isEmpty) ? '' : grade[0].toUpperCase();
    switch (g) {
      case 'A':
        return Colors.green.shade600;
      case 'B':
        return Colors.blue.shade600;
      case 'C':
        return Colors.teal.shade600;
      case 'D':
      case 'E':
        return Colors.orange.shade700;
      case 'F':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _fmt(num n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

// ==================================================================
// TERM GROUP
// ==================================================================

class _TermGroup {
  _TermGroup({this.term, this.session});

  final String? term;
  final String? session;
  final List<dynamic> results = [];
  DateTime? latest;

  void add(dynamic result, DateTime? createdAt) {
    results.add(result);
    if (createdAt != null && (latest == null || createdAt.isAfter(latest!))) {
      latest = createdAt;
    }
  }

  String get label =>
      [term, session].whereType<String>().join(' · ').ifEmpty('Results');

  String get shortLabel => term ?? 'Latest';

  double? get average {
    final scores = [
      for (final r in results)
        if (sNum(r, ['score', 'totalScore']) != null)
          sNum(r, ['score', 'totalScore'])!.toDouble(),
    ];
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
