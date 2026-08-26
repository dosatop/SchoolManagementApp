import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _testController;
  late final TextEditingController _examController;
  late final TextEditingController _remarkController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _testController = TextEditingController(
      text: _scoreText(widget.result.testScore),
    );

    _examController = TextEditingController(
      text: _scoreText(widget.result.examScore),
    );

    _remarkController = TextEditingController(
      text: widget.result.remark.trim(),
    );
  }

  @override
  void dispose() {
    _testController.dispose();
    _examController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String _scoreText(num value) {
    if (value == 0) {
      return '0';
    }

    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatScore(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _subjectName() {
    final value = widget.result.subjectName.trim();

    return value.isEmpty ? 'Subject' : value;
  }

  String _studentName() {
    final value = widget.result.studentName.trim();

    return value.isEmpty ? 'Student' : value;
  }

  num? _parseScore(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return num.tryParse(trimmed);
  }

  // ================================================================
  // SAVE RESULT
  // ================================================================

  Future<void> _saveResult() async {
    FocusScope.of(context).unfocus();

    final testScore = _parseScore(_testController.text);
    final examScore = _parseScore(_examController.text);

    // At least one score must be supplied.
    if (testScore == null && examScore == null) {
      _showError('Enter at least a test score or an exam score.');
      return;
    }

    // Validate test score only if supplied.
    if (testScore != null) {
      if (testScore < 0 || testScore > 40) {
        _showError('Test score must be between 0 and 40.');
        return;
      }
    }

    // Validate exam score only if supplied.
    if (examScore != null) {
      if (examScore < 0 || examScore > 60) {
        _showError('Exam score must be between 0 and 60.');
        return;
      }
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      /*
       * Backend handles:
       * - total score
       * - grade
       * - result calculation
       *
       * We only send:
       * - testScore
       * - examScore
       * - remark
       *
       * Depending on your UpdateAdminResultRequest implementation,
       * null values should be omitted from JSON if the score is not
       * being supplied.
       */
      final request = UpdateAdminResultRequest(
        testScore: testScore,
        examScore: examScore,
        remark: _remarkController.text.trim(),
      );

      final updated = await ref
          .read(adminDashboardProvider.notifier)
          .updateResult(resultId: widget.resultId, request: request);

      if (!mounted) {
        return;
      }

      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        context.pop(updated);
      } else {
        _showError('Unable to update result.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Unable to update result. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ================================================================
  // ERROR
  // ================================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: _isSaving ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),
        title: const Text(
          'Edit Result',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _studentCard(),

                const SizedBox(height: 14),

                _subjectCard(),

                const SizedBox(height: 20),

                const Text(
                  'Score Details',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'You can update the test, exam, or both.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _scoreField(
                        controller: _testController,
                        label: 'Test Score',
                        hint: '0 - 40',
                        icon: Icons.edit_note_rounded,
                        maximum: 40,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _scoreField(
                        controller: _examController,
                        label: 'Exam Score',
                        hint: '0 - 60',
                        icon: Icons.assignment_outlined,
                        maximum: 60,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _totalPreview(),

                const SizedBox(height: 20),

                const Text(
                  'Teacher Remark',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _textField(
                  controller: _remarkController,
                  label: 'Remark',
                  hint: 'e.g. Excellent performance',
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveResult,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withOpacity(.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _studentCard() {
    final studentNumber = widget.result.studentNumber.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (studentNumber.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    'Student No. $studentNumber',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
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
  // SUBJECT CARD
  // ================================================================

  Widget _subjectCard() {
    final code = widget.result.subjectCode.trim();

    final session = widget.result.session.trim();
    final term = widget.result.term.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subjectName(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (code.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    code,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],

                if (session.isNotEmpty || term.isNotEmpty) ...[
                  const SizedBox(height: 7),

                  Text(
                    [
                      if (session.isNotEmpty) session,
                      if (term.isNotEmpty) term,
                    ].join(' • '),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
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
  // SCORE FIELD
  // ================================================================

  Widget _scoreField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required num maximum,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        // Empty is allowed because the backend supports
        // test-only, exam-only, or both.
        if (text.isEmpty) {
          return null;
        }

        final score = num.tryParse(text);

        if (score == null) {
          return 'Invalid';
        }

        if (score < 0 || score > maximum) {
          return '0 - $maximum';
        }

        return null;
      },
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      maxLines: maxLines,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  // ================================================================
  // TOTAL PREVIEW
  // ================================================================

  Widget _totalPreview() {
    final test = _parseScore(_testController.text) ?? 0;
    final exam = _parseScore(_examController.text) ?? 0;

    final total = test + exam;

    final hasTest = _testController.text.trim().isNotEmpty;
    final hasExam = _examController.text.trim().isNotEmpty;

    String scoreType;

    if (hasTest && hasExam) {
      scoreType = 'Test + Exam';
    } else if (hasTest) {
      scoreType = 'Test only';
    } else if (hasExam) {
      scoreType = 'Exam only';
    } else {
      scoreType = 'No score';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: primary),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Total Score',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                _formatScore(total),
                style: const TextStyle(
                  color: primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              scoreType,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
