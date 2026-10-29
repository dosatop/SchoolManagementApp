import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ATTENDANCE PAGE (subject or class)
// ==================================================================
// • Subject teacher: pass subjectId + subjectName. Records are saved
//   with that SubjectId.
// • Class teacher:   pass subjectId: null. Records are saved with
//   SubjectId = null (class attendance), and only class-level records
//   are shown.

class TeacherClassAttendancePage extends ConsumerStatefulWidget {
  /// Null or empty = class attendance (class teacher).
  final String? subjectId;
  final String subjectName;
  final String classId;
  final String className;

  const TeacherClassAttendancePage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
  });

  bool get isClassAttendance => subjectId == null || subjectId!.trim().isEmpty;

  @override
  ConsumerState<TeacherClassAttendancePage> createState() =>
      _TeacherClassAttendancePageState();
}

enum _PageView { mark, history }

class _TeacherClassAttendancePageState
    extends ConsumerState<TeacherClassAttendancePage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  static const List<String> _statusOptions = [
    'Present',
    'Absent',
    'Late',
    'Excused',
  ];

  // ================================================================
  // STATE
  // ================================================================

  _PageView _view = _PageView.mark;

  // History sub-view: true = by date, false = by student.
  bool _historyByDate = true;

  late DateTime _selectedDate;

  // Kept in state so the family provider keys are stable between builds.
  late TeacherClassAttendanceParams _attendanceParams; // selected date
  late final TeacherClassAttendanceParams _historyParams; // all dates

  // Statuses the teacher has changed on this screen (studentId -> status).
  // Anything not here falls back to what is already saved for the date.
  final Map<String, String> _changes = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _attendanceParams = _buildParams();

    _historyParams = TeacherClassAttendanceParams(
      classId: widget.classId,
      subjectId: _paramsSubjectId,
      date: null,
    );

    // Always load fresh data when the page opens.
    Future.microtask(() {
      if (!mounted) return;
      ref.invalidate(teacherStudentsProvider(widget.classId));
      ref.invalidate(teacherClassAttendanceProvider(_attendanceParams));
      ref.invalidate(teacherClassAttendanceProvider(_historyParams));
    });
  }

  TeacherClassAttendanceParams _buildParams() {
    return TeacherClassAttendanceParams(
      classId: widget.classId,
      subjectId: _paramsSubjectId,
      date: _apiDate(_selectedDate),
    );
  }

  /// '' for class attendance (the params class needs a String).
  String get _paramsSubjectId =>
      widget.isClassAttendance ? '' : widget.subjectId!.trim();

  /// Keeps the two attendance types apart:
  /// • class attendance  → only records with no subject
  /// • subject attendance → only records for this subject
  /// so a class teacher's marks never show up as a subject teacher's
  /// "saved" marks, and the other way round.
  List<dynamic> _scoped(List<dynamic> records) {
    const emptyGuid = '00000000-0000-0000-0000-000000000000';

    return records.where((r) {
      final raw = _getString(r, ['subjectId']);
      final recordSubject =
          (raw == null || raw == emptyGuid) ? null : raw.toLowerCase();

      if (widget.isClassAttendance) return recordSubject == null;

      return recordSubject == widget.subjectId!.trim().toLowerCase();
    }).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider(widget.classId));

    final attendanceAsync = ref.watch(
      teacherClassAttendanceProvider(_attendanceParams),
    );

    // Only fetch the full history when the History view is open.
    final historyAsync = _view == _PageView.history
        ? ref.watch(teacherClassAttendanceProvider(_historyParams))
        : null;

    final students = _extractList(studentsAsync.valueOrNull, 'students');

    final saved = _savedStatuses(
      _scoped(_extractList(attendanceAsync.valueOrNull, 'attendance')),
    );

    final isMark = _view == _PageView.mark;

    return PopScope(
      canPop: _changes.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final leave = await _confirmDiscard();

        if (leave && context.mounted) {
          setState(_changes.clear);
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,

          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),

          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isClassAttendance
                    ? 'Class attendance'
                    : widget.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.isClassAttendance
                    ? '${widget.className} · Class teacher'
                    : widget.className,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _saving ? null : _refresh,
            ),
          ],
        ),

        body: Column(
          children: [
            _buildViewToggle(),

            if (isMark) _buildHeader(students, saved),

            Expanded(
              child: RefreshIndicator(
                color: primary,
                onRefresh: _refresh,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_view),
                    child: isMark
                        ? _buildBody(
                            studentsAsync,
                            attendanceAsync,
                            students,
                            saved,
                          )
                        : _buildHistory(historyAsync!, students),
                  ),
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: isMark && students.isNotEmpty
            ? _buildSaveBar(students, saved)
            : null,
      ),
    );
  }

  // ================================================================
  // MARK | HISTORY TOGGLE
  // ================================================================

  Widget _buildViewToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            _toggleSegment(
              label: 'Mark',
              icon: Icons.edit_calendar_outlined,
              selected: _view == _PageView.mark,
              onTap: () => setState(() => _view = _PageView.mark),
            ),
            _toggleSegment(
              label: 'History',
              icon: Icons.insights_outlined,
              selected: _view == _PageView.history,
              onTap: () => setState(() => _view = _PageView.history),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleSegment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _saving ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? primary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MARK BODY
  // ================================================================

  Widget _buildBody(
    AsyncValue<dynamic> studentsAsync,
    AsyncValue<dynamic> attendanceAsync,
    List<dynamic> students,
    Map<String, _SavedRecord> saved,
  ) {
    final loading =
        (studentsAsync.isLoading && !studentsAsync.hasValue) ||
        (attendanceAsync.isLoading && !attendanceAsync.hasValue);

    if (loading) {
      // Shimmer of student cards with the 4 status buttons.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Shimmer(
            child: Column(
              children: [
                for (var i = 0; i < 6; i++) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            ShimmerBox(height: 40, circle: true),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(width: 140, height: 13),
                                  SizedBox(height: 7),
                                  ShimmerBox(width: 80, height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (var j = 0; j < 4; j++) ...[
                              if (j > 0) const SizedBox(width: 6),
                              const Expanded(
                                child: ShimmerBox(height: 34, radius: 10),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (studentsAsync.hasError && !studentsAsync.hasValue) {
      return _buildError(
        'Unable to load students',
        studentsAsync.error.toString(),
      );
    }

    if (students.isEmpty) {
      return _scrollableCenter(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text(
              'No students in this class',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Students added to ${widget.className} will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildStudentCard(students[index], saved);
      },
    );
  }

  // ================================================================
  // MARK HEADER: DATE + MARK ALL + SUMMARY
  // ================================================================

  Widget _buildHeader(List<dynamic> students, Map<String, _SavedRecord> saved) {
    final counts = _countStatuses(students, saved);
    final marked = counts.values.fold<int>(0, (a, b) => a + b);
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE PICKER
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _saving ? null : _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 19,
                    color: primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isToday
                          ? 'Today · ${_prettyDate(_selectedDate)}'
                          : _prettyDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          if (students.isNotEmpty) ...[
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '$marked of ${students.length} marked',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _markAll(students, 'Present'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text(
                    'Mark all present',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in _statusOptions)
                  _countPill(status, counts[status] ?? 0),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _countPill(String status, int count, {bool compact = false}) {
    final colors = _statusColors(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count $status',
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );
  }

  // ================================================================
  // MARK: STUDENT CARD
  // ================================================================

  Widget _buildStudentCard(dynamic student, Map<String, _SavedRecord> saved) {
    final id = _studentId(student);
    final name =
        _getString(student, ['fullName', 'studentName', 'name']) ??
        'Unknown Student';
    final number = _getString(student, ['studentNumber', 'admissionNumber']);

    final savedRecord = id == null ? null : saved[id];
    final current = id == null ? null : (_changes[id] ?? savedRecord?.status);
    final changed =
        id != null &&
        _changes.containsKey(id) &&
        _changes[id] != savedRecord?.status;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: changed
              ? primary.withValues(alpha: .35)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(name),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (number != null) 'No. $number',
                        if (current == null)
                          'Not marked'
                        else if (changed)
                          'Unsaved'
                        else
                          'Saved',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: changed ? primary : Colors.grey.shade600,
                        fontWeight: changed ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              for (final status in _statusOptions) ...[
                Expanded(
                  child: _statusButton(
                    status: status,
                    selected: current?.toLowerCase() == status.toLowerCase(),
                    onTap: id == null || _saving
                        ? null
                        : () => setState(() => _changes[id] = status),
                  ),
                ),
                if (status != _statusOptions.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton({
    required String status,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final colors = _statusColors(status);

    return Material(
      color: selected ? colors.foreground : colors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : colors.foreground,
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MARK: SAVE BAR
  // ================================================================

  Widget _buildSaveBar(
    List<dynamic> students,
    Map<String, _SavedRecord> saved,
  ) {
    final pending = _changes.entries
        .where((e) => saved[e.key]?.status != e.value)
        .length;

    final unmarked = students.where((s) {
      final id = _studentId(s);
      return id != null && (_changes[id] ?? saved[id]?.status) == null;
    }).length;

    final canSave = pending > 0 && !_saving;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pending == 0
                        ? 'No unsaved changes'
                        : '$pending unsaved change${pending == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  if (unmarked > 0)
                    Text(
                      '$unmarked student${unmarked == 1 ? '' : 's'} not marked',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: canSave ? () => _save(saved) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving ? 'Saving...' : 'Save',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HISTORY
  // ================================================================

  Widget _buildHistory(
    AsyncValue<dynamic> historyAsync,
    List<dynamic> students,
  ) {
    if (historyAsync.isLoading && !historyAsync.hasValue) {
      return const StudentLoadingView(layout: LoadingLayout.summary);
    }

    if (historyAsync.hasError && !historyAsync.hasValue) {
      return _buildError(
        'Unable to load attendance history',
        historyAsync.error.toString(),
      );
    }

    final records = _parseHistory(
      _scoped(_extractList(historyAsync.valueOrNull, 'attendance')),
    );

    if (records.isEmpty) {
      return _scrollableCenter(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_outlined,
                size: 36,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No attendance history yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Once you mark attendance for '
              '${widget.isClassAttendance ? widget.className : widget.subjectName}, '
              'every day and every student will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => setState(() => _view = _PageView.mark),
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Take attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        _historySummary(records),

        const SizedBox(height: 16),

        _historyModeChips(),

        const SizedBox(height: 12),

        if (_historyByDate)
          ..._historyByDateCards(records)
        else
          ..._historyByStudentRows(records, students),
      ],
    );
  }

  // ---------------- Summary banner ----------------

  Widget _historySummary(List<_HistoryRecord> records) {
    final counts = _Counts.from(records);
    final days = records.map((r) => r.day).toSet().length;
    final rate = counts.rate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                    const Text(
                      'Overall attendance',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$days day${days == 1 ? '' : 's'} recorded · '
                      '${records.length} record${records.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: (rate ?? 0) / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: .18),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Icon(
                      Icons.fact_check_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _summaryStat('Present', counts.present),
              _summaryStat('Absent', counts.absent),
              _summaryStat('Late', counts.late),
              _summaryStat('Excused', counts.excused),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, int value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: label == 'Excused' ? 0 : 8),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
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

  // ---------------- By date / By student chips ----------------

  Widget _historyModeChips() {
    return Row(
      children: [
        _modeChip(
          label: 'By date',
          icon: Icons.calendar_month_outlined,
          selected: _historyByDate,
          onTap: () => setState(() => _historyByDate = true),
        ),
        const SizedBox(width: 8),
        _modeChip(
          label: 'By student',
          icon: Icons.person_outline_rounded,
          selected: !_historyByDate,
          onTap: () => setState(() => _historyByDate = false),
        ),
      ],
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? primary : Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- By date ----------------

  List<Widget> _historyByDateCards(List<_HistoryRecord> records) {
    final byDay = <DateTime, List<_HistoryRecord>>{};

    for (final record in records) {
      byDay.putIfAbsent(record.day, () => []).add(record);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final day in days) ...[
        _dateCard(day, byDay[day]!),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _dateCard(DateTime day, List<_HistoryRecord> dayRecords) {
    final counts = _Counts.from(dayRecords);
    final rate = counts.rate;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDate(day),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _dateBadge(day),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayLabel(day),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dayRecords.length} student${dayRecords.length == 1 ? '' : 's'} marked',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rate != null)
                    Text(
                      '${rate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _rateColor(rate),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _stackedBar(counts),

              const SizedBox(height: 10),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (counts.present > 0)
                    _countPill('Present', counts.present, compact: true),
                  if (counts.absent > 0)
                    _countPill('Absent', counts.absent, compact: true),
                  if (counts.late > 0)
                    _countPill('Late', counts.late, compact: true),
                  if (counts.excused > 0)
                    _countPill('Excused', counts.excused, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBadge(DateTime day) {
    return Container(
      width: 46,
      height: 50,
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _months[day.month - 1].toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: primary,
              letterSpacing: .5,
            ),
          ),
          Text(
            '${day.day}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stackedBar(_Counts counts) {
    final segments = [
      (counts.present, Colors.green.shade500),
      (counts.late, Colors.orange.shade400),
      (counts.excused, Colors.blue.shade400),
      (counts.absent, Colors.red.shade400),
    ].where((s) => s.$1 > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 7,
        child: segments.isEmpty
            ? Container(color: Colors.grey.shade200)
            : Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      flex: segment.$1,
                      child: Container(color: segment.$2),
                    ),
                ],
              ),
      ),
    );
  }

  // ---------------- By student ----------------

  List<Widget> _historyByStudentRows(
    List<_HistoryRecord> records,
    List<dynamic> students,
  ) {
    final byStudent = <String, List<_HistoryRecord>>{};

    for (final record in records) {
      byStudent.putIfAbsent(record.studentId, () => []).add(record);
    }

    // Every student in the class, plus anyone with records who has
    // since left the class.
    final rows = <_StudentRow>[];
    final seen = <String>{};

    for (final student in students) {
      final id = _studentId(student);
      if (id == null || !seen.add(id)) continue;

      rows.add(
        _StudentRow(
          id: id,
          name:
              _getString(student, ['fullName', 'studentName', 'name']) ??
              'Unknown Student',
          number: _getString(student, ['studentNumber', 'admissionNumber']),
          records: byStudent[id] ?? const [],
        ),
      );
    }

    for (final entry in byStudent.entries) {
      if (!seen.add(entry.key)) continue;

      rows.add(
        _StudentRow(
          id: entry.key,
          name: entry.value.first.studentName ?? 'Unknown Student',
          number: entry.value.first.studentNumber,
          records: entry.value,
        ),
      );
    }

    rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return [
      for (final row in rows) ...[
        _studentHistoryRow(row),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _studentHistoryRow(_StudentRow row) {
    final counts = _Counts.from(row.records);
    final rate = counts.rate;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: row.records.isEmpty ? null : () => _showStudentHistory(row),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _avatar(row.name),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (row.records.isEmpty)
                      Text(
                        'No attendance recorded yet',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      )
                    else
                      _miniCounts(counts),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _rateRing(rate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCounts(_Counts counts) {
    Widget item(String letter, int value, Color color) {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '$value $letter',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      runSpacing: 4,
      children: [
        item('P', counts.present, Colors.green.shade500),
        item('A', counts.absent, Colors.red.shade400),
        item('L', counts.late, Colors.orange.shade400),
        item('E', counts.excused, Colors.blue.shade400),
      ],
    );
  }

  Widget _rateRing(double? rate, {double size = 48}) {
    final color = rate == null ? Colors.grey.shade400 : _rateColor(rate);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (rate ?? 0) / 100,
              strokeWidth: 4.5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: size < 50 ? 11 : 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Student detail sheet ----------------

  void _showStudentHistory(_StudentRow row) {
    final records = [...row.records]..sort((a, b) => b.day.compareTo(a.day));
    final counts = _Counts.from(records);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: .62,
          minChildSize: .4,
          maxChildSize: .92,
          expand: false,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        _avatar(row.name, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  if (row.number != null) 'No. ${row.number}',
                                  '${records.length} day${records.length == 1 ? '' : 's'} recorded',
                                ].join(' · '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _rateRing(counts.rate, size: 56),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      children: [
                        _stackedBar(counts),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final status in _statusOptions) ...[
                              Expanded(
                                child: _sheetStat(status, counts.of(status)),
                              ),
                              if (status != _statusOptions.last)
                                const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: Colors.grey.shade200),

                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: records.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final record = records[index];

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openDate(record.day);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dayLabel(record.day),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textDark,
                                        ),
                                      ),
                                      if (record.remarks != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          record.remarks!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                _statusChip(record.status),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetStat(String status, int value) {
    final colors = _statusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            status,
            style: TextStyle(fontSize: 10, color: colors.foreground),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final colors = _statusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );
  }

  Widget _avatar(String name, {double radius = 20}) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: primaryLight,
      child: Text(
        initial,
        style: TextStyle(
          color: primary,
          fontSize: radius * .8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  void _markAll(List<dynamic> students, String status) {
    setState(() {
      for (final student in students) {
        final id = _studentId(student);
        if (id != null) {
          _changes[id] = status;
        }
      }
    });
  }

  /// Switch to Mark view on [day] (from History).
  Future<void> _openDate(DateTime day) async {
    final target = DateTime(day.year, day.month, day.day);

    if (!_isSameDay(target, _selectedDate) &&
        _changes.isNotEmpty &&
        !await _confirmDiscard()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      if (!_isSameDay(target, _selectedDate)) {
        _selectedDate = target;
        _attendanceParams = _buildParams();
        _changes.clear();
      }
      _view = _PageView.mark;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
          child: child!,
        );
      },
    );

    if (picked == null || _isSameDay(picked, _selectedDate)) return;

    if (_changes.isNotEmpty && !await _confirmDiscard()) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _attendanceParams = _buildParams();
      _changes.clear();
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(teacherStudentsProvider(widget.classId));
    ref.invalidate(teacherClassAttendanceProvider(_attendanceParams));
    ref.invalidate(teacherClassAttendanceProvider(_historyParams));

    await Future.wait([
      ref
          .read(teacherStudentsProvider(widget.classId).future)
          .then((_) {}, onError: (_) {}),
      _view == _PageView.mark
          ? ref
                .read(teacherClassAttendanceProvider(_attendanceParams).future)
                .then((_) {}, onError: (_) {})
          : ref
                .read(teacherClassAttendanceProvider(_historyParams).future)
                .then((_) {}, onError: (_) {}),
    ]);
  }

  Future<void> _save(Map<String, _SavedRecord> saved) async {
    final records = _changes.entries
        .where((e) => saved[e.key]?.status != e.value)
        .map(
          (e) => {
            'studentId': e.key,
            'status': e.value,
            'remarks': saved[e.key]?.remarks,
          },
        )
        .toList();

    if (records.isEmpty) return;

    final payload = {
      'classId': widget.classId,
      'subjectId': widget.isClassAttendance ? null : widget.subjectId,
      'date': _apiDateUtc(_selectedDate),
      'records': records,
    };

    setState(() => _saving = true);

    try {
      await _sendToApi(payload);

      if (!mounted) return;

      setState(_changes.clear);

      ref.invalidate(teacherClassAttendanceProvider(_attendanceParams));
      ref.invalidate(teacherClassAttendanceProvider(_historyParams));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          content: Text(
            'Attendance saved for ${records.length} student${records.length == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Could not save attendance: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ================================================================
  // SEND TO API
  // ================================================================
  // Uses teachersProvider.createBulkAttendance. With a subjectId the
  // records are subject attendance; without one they are class
  // attendance (the backend checks the teacher is the class teacher).
  // Throws on failure so the page shows the error snackbar.

  Future<void> _sendToApi(Map<String, dynamic> payload) async {
    final students = (payload['records'] as List)
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList();

    final success = await ref
        .read(teachersProvider.notifier)
        .createBulkAttendance(
          classId: widget.classId,
          // null = class attendance (SubjectId = null on the server)
          subjectId: payload['subjectId'] as String?,
          attendanceDate: payload['date'] as String, // 2026-10-26T00:00:00Z
          students: students,
        );

    if (!success) {
      throw Exception('Unable to save attendance. Please try again.');
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved attendance. If you leave now, those changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result == true;
  }

  // ================================================================
  // ERROR / EMPTY HELPERS
  // ================================================================

  Widget _scrollableCenter(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .55,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(28), child: child),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String title, String message) {
    return _scrollableCenter(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
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

  // ================================================================
  // DATA HELPERS
  // ================================================================

  List<dynamic> _extractList(dynamic data, String key) {
    if (data is List) return List<dynamic>.from(data);

    if (data is Map) {
      final direct = data[key];
      if (direct is List) return List<dynamic>.from(direct);

      final inner = data['data'];
      if (inner is List) return List<dynamic>.from(inner);

      if (inner is Map) {
        final nested = inner[key];
        if (nested is List) return List<dynamic>.from(nested);
      }
    }

    return [];
  }

  // Student objects may expose the student ID as studentId or id.
  String? _studentId(dynamic student) {
    return _getString(student, ['studentId', 'id']);
  }

  String _normaliseStatus(String status) {
    return _statusOptions.firstWhere(
      (s) => s.toLowerCase() == status.toLowerCase(),
      orElse: () => status,
    );
  }

  Map<String, _SavedRecord> _savedStatuses(List<dynamic> records) {
    final result = <String, _SavedRecord>{};

    for (final record in records) {
      final id = _getString(record, ['studentId']);
      final status = _getString(record, ['status', 'attendanceStatus']);

      if (id == null || status == null) continue;

      result[id] = _SavedRecord(
        status: _normaliseStatus(status),
        remarks: _getString(record, ['remarks']),
      );
    }

    return result;
  }

  List<_HistoryRecord> _parseHistory(List<dynamic> records) {
    final result = <_HistoryRecord>[];

    for (final record in records) {
      final id = _getString(record, ['studentId']);
      final status = _getString(record, ['status', 'attendanceStatus']);
      final rawDate = _getString(record, ['attendanceDate', 'date']);

      if (id == null || status == null || rawDate == null) continue;

      final parsed = DateTime.tryParse(rawDate);
      if (parsed == null) continue;

      // Attendance dates are UTC midnight: use the UTC calendar day so
      // UTC+1 never shifts it.
      final utc = parsed.isUtc ? parsed : parsed.toUtc();

      result.add(
        _HistoryRecord(
          studentId: id,
          studentName: _getString(record, ['studentName', 'fullName']),
          studentNumber: _getString(record, ['studentNumber']),
          status: _normaliseStatus(status),
          remarks: _getString(record, ['remarks']),
          day: DateTime(utc.year, utc.month, utc.day),
        ),
      );
    }

    return result;
  }

  Map<String, int> _countStatuses(
    List<dynamic> students,
    Map<String, _SavedRecord> saved,
  ) {
    final counts = <String, int>{};

    for (final student in students) {
      final id = _studentId(student);
      if (id == null) continue;

      final status = _changes[id] ?? saved[id]?.status;
      if (status == null) continue;

      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  _StatusColors _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return _StatusColors(Colors.green.shade50, Colors.green.shade700);
      case 'absent':
        return _StatusColors(Colors.red.shade50, Colors.red.shade700);
      case 'late':
        return _StatusColors(Colors.orange.shade50, Colors.orange.shade800);
      case 'excused':
        return _StatusColors(Colors.blue.shade50, Colors.blue.shade700);
      default:
        return _StatusColors(Colors.grey.shade100, Colors.grey.shade700);
    }
  }

  Color _rateColor(double rate) {
    if (rate >= 90) return Colors.green.shade600;
    if (rate >= 75) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  String? _getString(dynamic object, List<String> keys) {
    if (object is! Map) return null;

    for (final key in keys) {
      final value = object[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  // ================================================================
  // DATE HELPERS
  // ================================================================

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

  /// 2026-10-26 — used for the GET filter.
  String _apiDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// 2026-10-26T00:00:00Z — used when saving.
  String _apiDateUtc(DateTime d) => '${_apiDate(d)}T00:00:00Z';

  /// Mon, 26 Oct 2026
  String _prettyDate(DateTime d) {
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// Today / Yesterday / Mon, 26 Oct 2026
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return _prettyDate(d);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ==================================================================
// SMALL MODELS
// ==================================================================

class _SavedRecord {
  final String status;
  final String? remarks;

  const _SavedRecord({required this.status, this.remarks});
}

class _HistoryRecord {
  final String studentId;
  final String? studentName;
  final String? studentNumber;
  final String status;
  final String? remarks;
  final DateTime day;

  const _HistoryRecord({
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.status,
    required this.remarks,
    required this.day,
  });
}

class _StudentRow {
  final String id;
  final String name;
  final String? number;
  final List<_HistoryRecord> records;

  const _StudentRow({
    required this.id,
    required this.name,
    required this.number,
    required this.records,
  });
}

class _Counts {
  final int present;
  final int absent;
  final int late;
  final int excused;

  const _Counts({
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  factory _Counts.from(List<_HistoryRecord> records) {
    var present = 0, absent = 0, late = 0, excused = 0;

    for (final r in records) {
      switch (r.status.toLowerCase()) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'excused':
          excused++;
          break;
      }
    }

    return _Counts(
      present: present,
      absent: absent,
      late: late,
      excused: excused,
    );
  }

  int of(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return present;
      case 'absent':
        return absent;
      case 'late':
        return late;
      case 'excused':
        return excused;
      default:
        return 0;
    }
  }

  /// Attendance rate: (Present + Late) / (all except Excused).
  /// Excused days don't count for or against the student.
  double? get rate {
    final counted = present + absent + late;
    if (counted == 0) return null;
    return ((present + late) / counted) * 100;
  }
}

class _StatusColors {
  final Color background;
  final Color foreground;

  const _StatusColors(this.background, this.foreground);
}