import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ADMIN: EDIT RESULT
// ==================================================================

class AdminEditResultPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String resultId;
  final AdminResultModel result;

  const AdminEditResultPage({
    super.key,
    required this.schoolId,
    required this.resultId,
    required this.result,
  });

  @override
  ConsumerState<AdminEditResultPage> createState() =>
      _AdminEditResultPageState();
}

class _AdminEditResultPageState extends ConsumerState<AdminEditResultPage> {
  static const Color primary = StudentColors.primary;
  static const Color textDark = StudentColors.textDark;

  static const _remarks = [
    'Excellent',
    'Very good',
    'Good',
    'Fair',
    'Needs improvement',
  ];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _test;
  late final TextEditingController _exam;
  late final TextEditingController _remark;

  late final String _initialTest;
  late final String _initialExam;
  late final String _initialRemark;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final test = _n(widget.result.testScore);
    final exam = _n(widget.result.examScore);

    // An exam of 0 means "not entered yet" — show it empty.
    _initialTest = studentFmt(test);
    _initialExam = exam > 0 ? studentFmt(exam) : '';
    _initialRemark = widget.result.remark.trim();

    _test = TextEditingController(text: _initialTest);
    _exam = TextEditingController(text: _initialExam);
    _remark = TextEditingController(text: _initialRemark);
  }

  @override
  void dispose() {
    _test.dispose();
    _exam.dispose();
    _remark.dispose();
    super.dispose();
  }

  // ================================================================
  // HELPERS
  // ================================================================

  static double _n(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  static double? _parse(String text) {
    final t = text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  bool get _changed =>
      _test.text.trim() != _initialTest ||
      _exam.text.trim() != _initialExam ||
      _remark.text.trim() != _initialRemark;

  String get _subject {
    final s = widget.result.subjectName.trim();
    return s.isEmpty ? 'Subject' : s;
  }

  String get _student {
    final s = widget.result.studentName.trim();
    return s.isEmpty ? 'Student' : s;
  }

  // ================================================================
  // SAVE
  // ================================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    final test = _parse(_test.text);
    final exam = _parse(_exam.text);

    if (test == null && exam == null) {
      setState(() => _error = 'Enter a test score, an exam score, or both.');
      return;
    }

    if (!_changed) {
      context.pop();
      return;
    }

    setState(() => _saving = true);

    try {
      final updated = await ref
          .read(adminDashboardProvider.notifier)
          .updateResult(
            resultId: widget.resultId,
            request: UpdateAdminResultRequest(
              testScore: test,
              examScore: exam,
              remark: _remark.text.trim(),
            ),
          );

      if (!mounted) return;

      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
            content: Text('$_subject result updated'),
          ),
        );
        context.pop(updated);
      } else {
        setState(() {
          _saving = false;
          _error = 'Unable to update the result. Please try again.';
        });
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

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Discard changes?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Your edits to this result will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving && !_changed,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _saving) return;
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: StudentColors.background,
        appBar: studentAppBar('Edit result', subtitle: _student),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            children: [
              _header(),
              const SizedBox(height: 14),
              _scoresCard(),
              const SizedBox(height: 12),
              _remarkCard(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBox(_error!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
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
                    _saving ? 'Saving…' : 'Save changes',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header() {
    final r = widget.result;
    final number = r.studentNumber.trim();
    final code = r.subjectCode.trim();
    final term = r.term.trim();
    final period = [
      r.session.trim(),
      if (term.isNotEmpty)
        term.toLowerCase().contains('term') ? term : '$term term',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (code.isNotEmpty)
                      Text(
                        code,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .75),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(Icons.person_outline_rounded, _student),
              if (number.isNotEmpty) _chip(Icons.badge_outlined, 'No. $number'),
              if (r.className.trim().isNotEmpty)
                _chip(Icons.class_outlined, r.className.trim()),
              if (period.isNotEmpty)
                _chip(Icons.calendar_month_rounded, period),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SCORES
  // ================================================================

  Widget _scoresCard() {
    final test = _parse(_test.text);
    final exam = _parse(_exam.text);
    final hasExam = exam != null;
    final total = (test ?? 0) + (exam ?? 0);
    final grade = hasExam ? studentGradeFor(total) : null;
    final color = hasExam ? studentGradeColor(grade) : Colors.blueGrey;

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scores',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Leave the exam empty if it hasn\'t been written yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _scoreField(
                  controller: _test,
                  label: 'Test',
                  max: 40,
                  color: Colors.blue.shade500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _scoreField(
                  controller: _exam,
                  label: 'Exam',
                  max: 60,
                  color: Colors.purple.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ProgressRing(
                  value: hasExam ? total / 100 : (test ?? 0) / 40,
                  size: 56,
                  stroke: 6,
                  color: color,
                  trackColor: Colors.grey.shade200,
                  child: Text(
                    grade ?? '…',
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasExam ? 'New total' : 'Test only',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: studentFmt(total),
                              style: TextStyle(
                                color: color,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: hasExam ? ' / 100' : ' / 40',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        hasExam
                            ? 'Grade is worked out by the server when you save.'
                            : 'Grade appears once an exam score is entered.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
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

  Widget _scoreField({
    required TextEditingController controller,
    required String label,
    required int max,
    required Color color,
  }) {
    final value = _parse(controller.text);
    final fraction = value == null ? 0.0 : (value / max).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?')),
          ],
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            suffixText: '/ $max',
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
          validator: (v) {
            final text = v?.trim() ?? '';
            if (text.isEmpty) return null;
            final n = double.tryParse(text);
            if (n == null) return 'Invalid';
            if (n < 0 || n > max) return '0 – $max only';
            return null;
          },
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            color: color,
            backgroundColor: color.withValues(alpha: .12),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // REMARK
  // ================================================================

  Widget _remarkCard() {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remark',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in _remarks)
                ChoiceChip(
                  label: Text(r),
                  selected: _remark.text.trim() == r,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _remark.text = r),
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
          TextFormField(
            controller: _remark,
            enabled: !_saving,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Optional comment for this result',
              filled: true,
              fillColor: StudentColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
