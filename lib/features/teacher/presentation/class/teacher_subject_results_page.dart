import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// SUBJECT TEACHER: ENTER RESULTS FOR A CLASS
// ==================================================================
// One subject, one class, current term.
//
// • Every student in the class is listed (from teacherStudentsProvider),
//   with their saved Test / Exam scores pre-filled
//   (from teacherResultsProvider).
// • Test is out of 40, Exam out of 60 (the server rejects anything else).
// • Total and a grade preview update as you type.
// • Leave a box empty = "not entered yet". You can save tests now and
//   exams later — the server keeps whatever is already saved.
// • Save sends only the students you changed.

class TeacherSubjectResultsPage extends ConsumerStatefulWidget {
  const TeacherSubjectResultsPage({
    super.key,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
  });

  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;

  @override
  ConsumerState<TeacherSubjectResultsPage> createState() =>
      _TeacherSubjectResultsPageState();
}

class _TeacherSubjectResultsPageState
    extends ConsumerState<TeacherSubjectResultsPage> {
  static const double maxTest = 40;
  static const double maxExam = 60;

  late final TeacherResultsFilter _filter = TeacherResultsFilter(
    classId: widget.classId,
    subjectId: widget.subjectId,
  );

  final Map<String, _Row> _rows = {};
  final _searchController = TextEditingController();

  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    for (final row in _rows.values) {
      row.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(teacherStudentsProvider(widget.classId));
    ref.invalidate(teacherResultsProvider(_filter));

    await Future.wait([
      sSafe(ref.read(teacherStudentsProvider(widget.classId).future)),
      sSafe(ref.read(teacherResultsProvider(_filter).future)),
    ]);
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider(widget.classId));
    final resultsAsync = ref.watch(teacherResultsProvider(_filter));

    final students = sList(studentsAsync.valueOrNull, ['students']);
    final results = sList(resultsAsync.valueOrNull, ['results']);
    final term = sStr(resultsAsync.valueOrNull, ['term']) ??
        sStr(results.firstOrNull, ['term']);
    final session = sStr(resultsAsync.valueOrNull, ['session']) ??
        sStr(results.firstOrNull, ['session']);

    // While refreshing, keep showing what's on screen (don't apply
    // stale saved values over just-saved ones).
    _sync(students, results, applySaved: !resultsAsync.isLoading);

    final rows = _orderedRows(students);
    final visible = _query.isEmpty
        ? rows
        : rows.where((r) => r.searchText.contains(_query)).toList();

    final changed = rows.where((r) => r.isChanged).toList();
    final invalid = rows.where((r) => !r.isValid(maxTest, maxExam)).length;

    final loading =
        (studentsAsync.isLoading && !studentsAsync.hasValue) ||
        (resultsAsync.isLoading && !resultsAsync.hasValue);

    return PopScope(
      canPop: changed.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          for (final r in _rows.values) {
            r.reset();
          }
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: StudentColors.background,
        appBar: studentAppBar(
          widget.subjectName,
          subtitle: [
            widget.className,
            if (term != null) term,
            if (session != null) session,
          ].join(' · '),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _saving ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            if (!loading && rows.isNotEmpty) _header(rows),
            Expanded(
              child: RefreshIndicator(
                color: StudentColors.primary,
                onRefresh: _refresh,
                child: () {
                  if (loading) return const StudentLoadingView(itemCount: 7);

                  if (studentsAsync.hasError && !studentsAsync.hasValue) {
                    return StudentErrorView(
                      error: studentsAsync.error!,
                      onRetry: _refresh,
                      title: 'Unable to load students',
                    );
                  }

                  if (rows.isEmpty) {
                    return StudentEmptyView(
                      icon: Icons.groups_outlined,
                      title: 'No students',
                      message: 'There are no students in ${widget.className}.',
                    );
                  }

                  if (visible.isEmpty) {
                    return StudentEmptyView(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      message: 'No student matches "$_query".',
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _rowCard(visible[i], rows.indexOf(visible[i])),
                  );
                }(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: rows.isEmpty
            ? null
            : _saveBar(changed: changed.length, invalid: invalid),
      ),
    );
  }

  // ================================================================
  // DATA SYNC
  // ================================================================

  /// Creates a row per student and fills in saved scores. Rows the
  /// teacher is editing are never overwritten.
  void _sync(
    List<dynamic> students,
    List<dynamic> results, {
    required bool applySaved,
  }) {
    final byStudent = <String, dynamic>{
      for (final r in results)
        if (sStr(r, ['studentId']) != null) sStr(r, ['studentId'])!: r,
    };

    for (final s in students) {
      final id = sStr(s, ['studentId', 'id']);
      if (id == null) continue;

      final row = _rows.putIfAbsent(
        id,
        () => _Row(
          studentId: id,
          name: sStr(s, ['studentName', 'fullName', 'name']) ?? 'Student',
          number: sStr(s, ['studentNumber', 'admissionNumber']),
          onChanged: () => setState(() {}),
        ),
      );

      if (!applySaved) continue;

      final saved = byStudent[id];
      row.applySaved(
        test: sNum(saved, ['testScore'])?.toDouble(),
        exam: sNum(saved, ['examScore'])?.toDouble(),
        remark: sStr(saved, ['remark']),
        grade: sStr(saved, ['grade']),
        hasResult: saved != null,
      );
    }
  }

  List<_Row> _orderedRows(List<dynamic> students) {
    final ids = [
      for (final s in students)
        if (sStr(s, ['studentId', 'id']) != null) sStr(s, ['studentId', 'id'])!,
    ];

    final rows = ids.map((id) => _rows[id]).whereType<_Row>().toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return rows;
  }

  // ================================================================
  // HEADER: SUMMARY + SEARCH
  // ================================================================

  Widget _header(List<_Row> rows) {
    final totals = rows.map((r) => r.total).whereType<double>().toList();
    final complete = rows.where((r) => r.test != null && r.exam != null).length;
    final average = totals.isEmpty
        ? null
        : totals.reduce((a, b) => a + b) / totals.length;
    final highest = totals.isEmpty ? null : totals.reduce((a, b) => a > b ? a : b);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _pill('Complete', '$complete/${rows.length}', Colors.green),
              const SizedBox(width: 8),
              _pill('Average', average == null ? '—' : _fmt(average), StudentColors.primary),
              const SizedBox(width: 8),
              _pill('Highest', highest == null ? '—' : _fmt(highest), Colors.orange),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search student',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: StudentColors.background,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
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

  // ================================================================
  // STUDENT ROW
  // ================================================================

  Widget _rowCard(_Row row, int index) {
    final total = row.total;
    final grade = row.isChanged || row.savedGrade == null
        ? (total == null ? null : _gradeFor(total))
        : row.savedGrade;
    final color = _gradeColor(grade);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: row.isChanged
              ? StudentColors.primary.withValues(alpha: .4)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: StudentColors.primaryLight,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: StudentColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        if (row.number != null) 'No. ${row.number}',
                        row.isChanged
                            ? 'Unsaved'
                            : row.hasResult
                            ? 'Saved'
                            : 'Not entered',
                      ].join(' · '),
                      style: TextStyle(
                        color: row.isChanged
                            ? StudentColors.primary
                            : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: row.isChanged ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Total + grade
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total == null ? '—' : _fmt(total),
                    style: const TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  grade ?? '—',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _scoreField(
                  controller: row.testController,
                  label: 'Test',
                  max: maxTest,
                  value: row.test,
                  hasText: row.testController.text.trim().isNotEmpty,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _scoreField(
                  controller: row.examController,
                  label: 'Exam',
                  max: maxExam,
                  value: row.exam,
                  hasText: row.examController.text.trim().isNotEmpty,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: row.remark == null ? 'Add remark' : 'Edit remark',
                onPressed: _saving ? null : () => _editRemark(row),
                style: IconButton.styleFrom(
                  backgroundColor: row.remark == null
                      ? StudentColors.background
                      : StudentColors.primaryLight,
                ),
                icon: Icon(
                  row.remark == null
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.chat_bubble_rounded,
                  size: 18,
                  color: StudentColors.primary,
                ),
              ),
            ],
          ),
          if (row.remark != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                row.remark!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreField({
    required TextEditingController controller,
    required String label,
    required double max,
    required double? value,
    required bool hasText,
  }) {
    final bad = hasText && (value == null || value < 0 || value > max);

    return TextField(
      controller: controller,
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?')),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: '$label / ${max.toInt()}',
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        filled: true,
        fillColor: bad ? Colors.red.shade50 : StudentColors.background,
        errorText: bad ? '0 – ${max.toInt()}' : null,
        errorStyle: const TextStyle(fontSize: 10),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: StudentColors.primary),
        ),
      ),
    );
  }

  // ================================================================
  // SAVE BAR
  // ================================================================

  Widget _saveBar({required int changed, required int invalid}) {
    final canSave = changed > 0 && invalid == 0 && !_saving;

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
                    changed == 0
                        ? 'No unsaved changes'
                        : '$changed student${changed == 1 ? '' : 's'} changed',
                    style: const TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (invalid > 0)
                    Text(
                      'Fix $invalid score${invalid == 1 ? '' : 's'} out of range',
                      style: TextStyle(color: Colors.red.shade600, fontSize: 11),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StudentColors.primary,
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
                  _saving ? 'Saving…' : 'Save',
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
  // ACTIONS
  // ================================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final both = <Map<String, dynamic>>[];
    final tests = <Map<String, dynamic>>[];
    final exams = <Map<String, dynamic>>[];
    var skipped = 0;

    for (final row in _rows.values.where((r) => r.isChanged)) {
      final t = row.test;
      final e = row.exam;

      // The server overwrites the remark, so always send the current one.
      final base = {'studentId': row.studentId, 'remark': row.remark};

      if (t != null && e != null) {
        both.add({...base, 'testScore': t, 'examScore': e});
      } else if (t != null) {
        tests.add({...base, 'testScore': t});
      } else if (e != null) {
        exams.add({...base, 'examScore': e});
      } else {
        // Boxes cleared: the API can't delete scores from here.
        skipped++;
      }
    }

    if (both.isEmpty && tests.isEmpty && exams.isEmpty) {
      _snack(
        'Nothing to save. Clearing a saved score isn\'t supported here.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final count = await ref
          .read(teachersProvider.notifier)
          .saveClassResults(
            classId: widget.classId,
            subjectId: widget.subjectId,
            both: both,
            tests: tests,
            exams: exams,
          );

      if (!mounted) return;

      // Mark rows as saved so fresh server data fills them in.
      for (final r in _rows.values) {
        r.markClean();
      }

      _snack(
        'Saved results for $count student${count == 1 ? '' : 's'}.'
        '${skipped > 0 ? ' $skipped cleared row${skipped == 1 ? ' was' : 's were'} skipped.' : ''}',
      );
    } catch (e) {
      if (!mounted) return;
      _snack(
        'Could not save: ${e.toString().replaceFirst('Exception: ', '')}',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editRemark(_Row row) async {
    final controller = TextEditingController(text: row.remark ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remark · ${row.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Very good, keep it up',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (row.remark != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, ''),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          // Done is only active once there's an actual remark that
          // differs from the saved one (spaces alone don't count).
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final text = value.text.trim();
              final canSubmit = text.isNotEmpty && text != (row.remark ?? '');

              return ElevatedButton(
                onPressed: canSubmit
                    ? () => Navigator.pop(dialogContext, text)
                    : null,
                child: const Text('Done'),
              );
            },
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null || !mounted) return;

    setState(() => row.setRemark(result.trim().isEmpty ? null : result.trim()));
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved scores. If you leave now, they will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
          content: Text(message),
        ),
      );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// Preview only — the saved grade comes from the server. Match this
  /// to your backend's CalculateGrade if your scale is different.
  String _gradeFor(double score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
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
        return Colors.grey.shade500;
    }
  }

  String _fmt(num n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
}

// ==================================================================
// ROW STATE (one student)
// ==================================================================

class _Row {
  _Row({
    required this.studentId,
    required this.name,
    required this.number,
    required VoidCallback onChanged,
  }) {
    // Typing rebuilds the page; filling boxes from data does not.
    void listener() {
      if (!_silent) onChanged();
    }

    testController.addListener(listener);
    examController.addListener(listener);
  }

  bool _silent = false;

  final String studentId;
  final String name;
  final String? number;

  final testController = TextEditingController();
  final examController = TextEditingController();

  // Saved on the server.
  double? _savedTest;
  double? _savedExam;
  String? _savedRemark;
  String? savedGrade;
  bool hasResult = false;

  String? _remark;
  bool _remarkEdited = false;

  String get searchText => '$name ${number ?? ''}'.toLowerCase();

  double? get test => _parse(testController.text);
  double? get exam => _parse(examController.text);

  String? get remark => _remarkEdited ? _remark : _savedRemark;

  double? get total =>
      (test == null && exam == null) ? null : (test ?? 0) + (exam ?? 0);

  bool get isChanged =>
      test != _savedTest || exam != _savedExam || remark != _savedRemark;

  bool isValid(double maxTest, double maxExam) {
    bool ok(TextEditingController c, double max) {
      final text = c.text.trim();
      if (text.isEmpty) return true;
      final v = double.tryParse(text);
      return v != null && v >= 0 && v <= max;
    }

    return ok(testController, maxTest) && ok(examController, maxExam);
  }

  void applySaved({
    required double? test,
    required double? exam,
    required String? remark,
    required String? grade,
    required bool hasResult,
  }) {
    final wasClean = !isChanged;

    _savedTest = test;
    _savedExam = exam;
    _savedRemark = remark;
    savedGrade = grade;
    this.hasResult = hasResult;

    // Only fill the boxes when the teacher isn't mid-edit.
    if (wasClean) {
      _setText(testController, test);
      _setText(examController, exam);
      _remarkEdited = false;
      _remark = null;
    }
  }

  void setRemark(String? value) {
    _remark = value;
    _remarkEdited = true;
  }

  /// After a successful save: what's on screen is now the saved value.
  void markClean() {
    if (!isChanged) return;
    final t = test, e = exam, rm = remark;
    _savedTest = t;
    _savedExam = e;
    _savedRemark = rm;
    _remarkEdited = false;
    _remark = null;
    savedGrade = null; // recomputed by the server on refresh
    if (t != null || e != null) hasResult = true;
  }

  void reset() {
    _setText(testController, _savedTest);
    _setText(examController, _savedExam);
    _remarkEdited = false;
    _remark = null;
  }

  void dispose() {
    testController.dispose();
    examController.dispose();
  }

  void _setText(TextEditingController c, double? v) {
    final text = v == null ? '' : (v % 1 == 0 ? v.toInt().toString() : '$v');
    if (c.text == text) return;
    _silent = true;
    c.text = text;
    _silent = false;
  }

  static double? _parse(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
}