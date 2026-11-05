import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ADMIN: CREATE RESULT
// ==================================================================
// 1. Class → 2. Student → 3. Subject → 4. Scores → 5. Remark
//
// The result is saved to the CURRENT session/term (the server decides).
// If the student already has a result for that subject this term,
// the server updates it instead of creating a duplicate.
// ==================================================================

class AdminCreateResultPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateResultPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminCreateResultPage> createState() =>
      _AdminCreateResultPageState();
}

class _AdminCreateResultPageState extends ConsumerState<AdminCreateResultPage> {
  static const Color primary = StudentColors.primary;
  static const Color textDark = StudentColors.textDark;

  static const _remarks = [
    'Excellent',
    'Very good',
    'Good',
    'Fair',
    'Needs improvement',
  ];

  final _test = TextEditingController();
  final _exam = TextEditingController();
  final _remark = TextEditingController();

  String? _classId;
  String? _studentId;
  String? _subjectId;
  bool _showAllSubjects = false;

  bool _saving = false;
  String? _error;
  int _savedCount = 0;

  @override
  void dispose() {
    _test.dispose();
    _exam.dispose();
    _remark.dispose();
    super.dispose();
  }

  // ================================================================
  // SAFE ACCESS (class & subject models are read dynamically)
  // ================================================================

  static String? _get(dynamic o, String Function(dynamic) read) {
    try {
      final v = read(o)?.toString().trim();
      return v == null || v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  static String _classIdOf(dynamic c) => _get(c, (x) => x.classId) ?? '';
  static String _classNameOf(dynamic c) =>
      _get(c, (x) => x.className) ?? _get(c, (x) => x.name) ?? 'Class';

  static String _subjectIdOf(dynamic s) => _get(s, (x) => x.subjectId) ?? '';
  static String _subjectNameOf(dynamic s) =>
      _get(s, (x) => x.subjectName) ?? _get(s, (x) => x.name) ?? 'Subject';
  static String? _subjectCodeOf(dynamic s) => _get(s, (x) => x.code);

  /// Can this student take this subject? (general, their department,
  /// or their trade). Unknown → allowed.
  static bool _eligible(dynamic subject, AdminStudentModel? student) {
    if (student == null) return true;

    final dept = _get(subject, (x) => x.departmentId);
    final trade = _get(subject, (x) => x.tradeId);
    final tradeName = _get(subject, (x) => x.tradeName);

    if (dept == null && trade == null && tradeName == null) return true;

    if (dept != null && dept == _get(student, (x) => x.departmentId)) {
      return true;
    }

    final studentTradeId = _get(student, (x) => x.tradeId);
    if (trade != null && studentTradeId != null && trade == studentTradeId) {
      return true;
    }

    final studentTrade = _get(student, (x) => x.tradeName);
    if (tradeName != null &&
        studentTrade != null &&
        tradeName.toLowerCase() == studentTrade.toLowerCase()) {
      return true;
    }

    return false;
  }

  static double? _parse(String text) {
    final t = text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  void _snack(String text, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          content: Text(text),
        ),
      );
  }

  // ================================================================
  // SAVE
  // ================================================================

  String? _validate() {
    if (_classId == null) return 'Pick a class.';
    if (_studentId == null) return 'Pick a student.';
    if (_subjectId == null) return 'Pick a subject.';

    final testText = _test.text.trim();
    final examText = _exam.text.trim();
    if (testText.isEmpty && examText.isEmpty) {
      return 'Enter a test score, an exam score, or both.';
    }

    final test = _parse(testText);
    final exam = _parse(examText);
    if (testText.isNotEmpty && (test == null || test < 0 || test > 40)) {
      return 'Test score must be between 0 and 40.';
    }
    if (examText.isNotEmpty && (exam == null || exam < 0 || exam > 60)) {
      return 'Exam score must be between 0 and 60.';
    }
    return null;
  }

  Future<void> _save({required bool addAnother}) async {
    FocusScope.of(context).unfocus();

    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(adminDashboardProvider.notifier)
          .createResult(
            schoolId: widget.schoolId,
            request: CreateAdminResultRequest(
              studentId: _studentId!,
              classId: _classId!,
              subjectId: _subjectId!,
              testScore: _parse(_test.text),
              examScore: _parse(_exam.text),
              remark: _remark.text.trim(),
            ),
          );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _saving = false;
          _error =
              'Unable to save the result. Check that a current session '
              'and term are set, then try again.';
        });
        return;
      }

      _savedCount++;

      if (addAnother) {
        // Keep class + student, clear the rest for the next subject.
        _test.clear();
        _exam.clear();
        _remark.clear();
        setState(() {
          _saving = false;
          _subjectId = null;
        });
        _snack(
          'Saved. Pick the next subject for this student.',
          color: Colors.green.shade700,
        );
      } else {
        _snack('Result saved', color: Colors.green.shade700);
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e
            .toString()
            .replaceFirst(RegExp(r'^[A-Za-z]*Exception:\s*'), '')
            .trim();
      });
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(adminDashboardProvider);
    final session = ref.watch(currentAcademicSessionProvider(widget.schoolId));

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: StudentColors.background,
        appBar: studentAppBar('Add result'),
        body: () {
          if (dashboard.isLoading && !dashboard.hasValue) {
            return const StudentLoadingView(layout: LoadingLayout.detail);
          }
          if (dashboard.hasError && !dashboard.hasValue) {
            return StudentErrorView(
              error: dashboard.error!,
              onRetry: () => ref.invalidate(adminDashboardProvider),
              title: 'Unable to load school data',
            );
          }

          final data = dashboard.value!;
          final List<dynamic> classes = [...data.classes]
            ..sort(
              (a, b) => _classNameOf(
                a,
              ).toLowerCase().compareTo(_classNameOf(b).toLowerCase()),
            );

          final students =
              data.students.where((s) => s.classId == _classId).toList()
                ..sort(
                  (a, b) => a.studentName.toLowerCase().compareTo(
                    b.studentName.toLowerCase(),
                  ),
                );

          final student = students
              .where((s) => s.studentId == _studentId)
              .firstOrNull;

          final List<dynamic> allSubjects = [...data.subjects]
            ..sort(
              (a, b) => _subjectNameOf(
                a,
              ).toLowerCase().compareTo(_subjectNameOf(b).toLowerCase()),
            );
          final eligible = allSubjects
              .where((s) => _eligible(s, student))
              .toList();
          final subjects = _showAllSubjects ? allSubjects : eligible;

          final currentSession = _get(session.valueOrNull, (x) => x.session);
          String? currentTerm;
          try {
            final json = (session.valueOrNull as dynamic)?.toJson();
            currentTerm = json is Map
                ? (json['term'] ?? json['currentTerm'])?.toString()
                : null;
          } catch (_) {}

          return ListView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            children: [
              _header(currentSession, currentTerm, session.hasError),
              const SizedBox(height: 14),

              // 1. CLASS
              _step(
                number: 1,
                title: 'Class',
                done: _classId != null,
                child: classes.isEmpty
                    ? _hint('No classes yet. Create a class first.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in classes)
                            _choice(
                              label: _classNameOf(c),
                              selected: _classIdOf(c) == _classId,
                              onTap: () => setState(() {
                                if (_classId == _classIdOf(c)) return;
                                _classId = _classIdOf(c);
                                _studentId = null;
                                _subjectId = null;
                                _error = null;
                              }),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),

              // 2. STUDENT
              _step(
                number: 2,
                title: 'Student',
                done: _studentId != null,
                enabled: _classId != null,
                child: _classId == null
                    ? _hint('Pick a class first.')
                    : students.isEmpty
                    ? _hint('No students in this class yet.')
                    : _pickerButton(
                        icon: Icons.person_outline_rounded,
                        placeholder: 'Choose from ${students.length} students',
                        value: student?.studentName,
                        caption: student == null
                            ? null
                            : [
                                if (student.studentNumber.trim().isNotEmpty)
                                  'No. ${student.studentNumber.trim()}',
                                if ((student.departmentName ?? '').isNotEmpty)
                                  student.departmentName!,
                                if ((student.tradeName ?? '').isNotEmpty)
                                  student.tradeName!,
                              ].join(' · '),
                        onTap: () => _pickStudent(students),
                      ),
              ),
              const SizedBox(height: 10),

              // 3. SUBJECT
              _step(
                number: 3,
                title: 'Subject',
                done: _subjectId != null,
                enabled: _studentId != null,
                trailing: _studentId != null &&
                        eligible.length != allSubjects.length
                    ? TextButton(
                        onPressed: () => setState(() {
                          _showAllSubjects = !_showAllSubjects;
                          if (!_showAllSubjects &&
                              !eligible.any(
                                (s) => _subjectIdOf(s) == _subjectId,
                              )) {
                            _subjectId = null;
                          }
                        }),
                        child: Text(
                          _showAllSubjects ? 'Show eligible' : 'Show all',
                        ),
                      )
                    : null,
                child: _studentId == null
                    ? _hint('Pick a student first.')
                    : subjects.isEmpty
                    ? _hint('No subjects found for this student.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in subjects)
                            _choice(
                              label: _subjectNameOf(s),
                              caption: _subjectCodeOf(s),
                              selected: _subjectIdOf(s) == _subjectId,
                              muted: !_eligible(s, student),
                              onTap: () => setState(() {
                                _subjectId = _subjectIdOf(s);
                                _error = null;
                              }),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),

              // 4. SCORES
              _step(
                number: 4,
                title: 'Scores',
                done:
                    _test.text.trim().isNotEmpty ||
                    _exam.text.trim().isNotEmpty,
                enabled: _subjectId != null,
                child: _scores(),
              ),
              const SizedBox(height: 10),

              // 5. REMARK
              _step(
                number: 5,
                title: 'Remark (optional)',
                done: _remark.text.trim().isNotEmpty,
                enabled: _subjectId != null,
                child: _remarkInput(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _save(addAnother: false),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withValues(alpha: .45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving ? 'Saving…' : 'Save result',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _save(addAnother: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: .35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text(
                    'Save & add another subject',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header(String? session, String? term, bool failed) {
    final t = term?.trim();
    final termLabel = t == null || t.isEmpty
        ? null
        : t.toLowerCase().contains('term')
        ? t
        : '$t term';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.add_chart_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New result',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session == null
                      ? failed
                            ? 'Current session could not be loaded.'
                            : 'Saved to the current session and term.'
                      : 'Saving to $session${termLabel == null ? '' : ' · $termLabel'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 12.5,
                  ),
                ),
                if (_savedCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_savedCount saved this visit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STEP CARD
  // ================================================================

  Widget _step({
    required int number,
    required String title,
    required bool done,
    required Widget child,
    bool enabled = true,
    Widget? trailing,
  }) {
    final color = done ? Colors.green.shade600 : primary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : .55,
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? color : color.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : Text(
                          '$number',
                          style: TextStyle(
                            color: color,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            IgnorePointer(ignoring: !enabled || _saving, child: child),
          ],
        ),
      ),
    );
  }

  Widget _hint(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? caption,
    bool muted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE3E6EF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (caption != null) ...[
              Text(
                caption,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: .8)
                      : primary.withValues(alpha: muted ? .4 : 1),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : muted
                    ? Colors.grey.shade500
                    : textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String placeholder,
    required String? value,
    required String? caption,
    required VoidCallback onTap,
  }) {
    final has = value != null;

    return Material(
      color: has ? StudentColors.primaryLight : StudentColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE3E6EF)),
                ),
                child: has
                    ? Text(
                        studentInitials(value, fallback: 'S'),
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: has ? textDark : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: has ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (caption != null && caption.isNotEmpty)
                      Text(
                        caption,
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
              Icon(
                has ? Icons.swap_horiz_rounded : Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STUDENT PICKER
  // ================================================================

  Future<void> _pickStudent(List<AdminStudentModel> students) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentPicker(students: students, selected: _studentId),
    );

    if (picked == null || !mounted) return;
    setState(() {
      if (picked != _studentId) {
        _subjectId = null;
        _showAllSubjects = false;
      }
      _studentId = picked;
      _error = null;
    });
  }

  // ================================================================
  // SCORES
  // ================================================================

  Widget _scores() {
    final test = _parse(_test.text);
    final exam = _parse(_exam.text);
    final hasExam = exam != null;
    final total = (test ?? 0) + (exam ?? 0);
    final grade = hasExam ? studentGradeFor(total) : null;
    final color = hasExam ? studentGradeColor(grade) : Colors.blueGrey;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _scoreField(_test, 'Test', 40, Colors.blue.shade500),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _scoreField(_exam, 'Exam', 60, Colors.purple.shade500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ProgressRing(
                value: hasExam ? total / 100 : (test ?? 0) / 40,
                size: 50,
                stroke: 6,
                color: color,
                trackColor: Colors.grey.shade200,
                child: Text(
                  grade ?? '…',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  test == null && exam == null
                      ? 'Enter test, exam, or both.'
                      : hasExam
                      ? 'Total ${studentFmt(total)} / 100'
                      : 'Test ${studentFmt(test ?? 0)} / 40 — exam can be added later',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scoreField(
    TextEditingController controller,
    String label,
    int max,
    Color color,
  ) {
    final value = _parse(controller.text);
    final over = value != null && (value < 0 || value > max);
    final fraction = value == null ? 0.0 : (value / max).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?')),
          ],
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: label,
            suffixText: '/ $max',
            errorText: over ? '0 – $max only' : null,
            filled: true,
            fillColor: StudentColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            color: over ? Colors.red : color,
            backgroundColor: color.withValues(alpha: .12),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // REMARK
  // ================================================================

  Widget _remarkInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final r in _remarks)
              ChoiceChip(
                label: Text(r),
                selected: _remark.text.trim() == r,
                onSelected: (_) => setState(() => _remark.text = r),
                selectedColor: StudentColors.primaryLight,
                labelStyle: TextStyle(
                  color: _remark.text.trim() == r ? primary : textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                side: BorderSide(color: Colors.grey.shade200),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _remark,
          enabled: !_saving,
          maxLines: 2,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Or write your own',
            filled: true,
            fillColor: StudentColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// STUDENT PICKER SHEET (searchable)
// ==================================================================

class _StudentPicker extends StatefulWidget {
  const _StudentPicker({required this.students, required this.selected});

  final List<AdminStudentModel> students;
  final String? selected;

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _query.isEmpty
        ? widget.students
        : widget.students
              .where(
                (s) => '${s.studentName} ${s.studentNumber}'
                    .toLowerCase()
                    .contains(_query),
              )
              .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const SheetHandle(),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StudentSearchField(
                  controller: _search,
                  hint: 'Search name or number',
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          'No student matches "$_query"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final s = list[i];
                          final selected = s.studentId == widget.selected;
                          final color =
                              StudentColors.accents[i %
                                  StudentColors.accents.length];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            tileColor: selected
                                ? StudentColors.primaryLight
                                : null,
                            onTap: () => Navigator.pop(context, s.studentId),
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: .12),
                              child: Text(
                                studentInitials(s.studentName, fallback: 'S'),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              s.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: s.studentNumber.trim().isEmpty
                                ? null
                                : Text('No. ${s.studentNumber.trim()}'),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: StudentColors.primary,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}