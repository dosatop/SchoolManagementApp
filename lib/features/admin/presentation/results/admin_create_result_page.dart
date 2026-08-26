import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCreateResultPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateResultPage({
    super.key,
    required this.schoolId,
  });

  @override
  ConsumerState<AdminCreateResultPage> createState() =>
      _AdminCreateResultPageState();
}

class _AdminCreateResultPageState
    extends ConsumerState<AdminCreateResultPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  final _testController = TextEditingController();
  final _examController = TextEditingController();
  final _remarkController = TextEditingController();

  String? _selectedClassId;
  String? _selectedStudentId;
  String? _selectedSubjectId;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _testController.dispose();
    _examController.dispose();
    _remarkController.dispose();

    super.dispose();
  }

  // ================================================================
  // DASHBOARD DATA
  // ================================================================

  List<dynamic> get _classes {
    return ref.watch(adminDashboardProvider).value?.classes ?? [];
  }

  List<dynamic> get _allStudents {
    return ref.watch(adminDashboardProvider).value?.students ?? [];
  }

  List<dynamic> get _subjects {
    return ref.watch(adminDashboardProvider).value?.subjects ?? [];
  }

  // ================================================================
  // STUDENTS FOR SELECTED CLASS
  // ================================================================

  List<AdminStudentModel> get _classStudents {
    if (_selectedClassId == null) {
      return [];
    }

    return _allStudents
        .whereType<AdminStudentModel>()
        .where((student) {
          return _studentBelongsToClass(
            student,
            _selectedClassId!,
          );
        })
        .toList();
  }

  bool _studentBelongsToClass(
    AdminStudentModel student,
    String classId,
  ) {
    /*
     * IMPORTANT:
     *
     * Adjust this helper only if your AdminStudentModel uses
     * a different property for the student's class.
     *
     * Common possibilities are:
     *   student.classId
     *   student.currentClassId
     *
     * The code below expects classId on AdminStudentModel.
     */

    return student.classId == classId;
  }

  // ================================================================
  // SELECTED ITEMS
  // ================================================================

  dynamic get _selectedClass {
    if (_selectedClassId == null) {
      return null;
    }

    for (final schoolClass in _classes) {
      if (schoolClass.classId == _selectedClassId) {
        return schoolClass;
      }
    }

    return null;
  }

  AdminStudentModel? get _selectedStudent {
    if (_selectedStudentId == null) {
      return null;
    }

    for (final student in _classStudents) {
      if (student.studentId == _selectedStudentId) {
        return student;
      }
    }

    return null;
  }

  dynamic get _selectedSubject {
    if (_selectedSubjectId == null) {
      return null;
    }

    for (final subject in _subjects) {
      if (subject.subjectId == _selectedSubjectId) {
        return subject;
      }
    }

    return null;
  }

  // ================================================================
  // CREATE RESULT
  // ================================================================

  Future<void> _createResult() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassId == null) {
      _showError('Please select a class.');
      return;
    }

    if (_selectedStudentId == null) {
      _showError('Please select a student.');
      return;
    }

    if (_selectedSubjectId == null) {
      _showError('Please select a subject.');
      return;
    }

    final testText = _testController.text.trim();
    final examText = _examController.text.trim();

    final hasTest = testText.isNotEmpty;
    final hasExam = examText.isNotEmpty;

    // At least one score must be supplied.
    if (!hasTest && !hasExam) {
      _showError('Enter either a test score, exam score, or both.');
      return;
    }

    num? testScore;
    num? examScore;

    if (hasTest) {
      testScore = num.tryParse(testText);

      if (testScore == null) {
        _showError('Enter a valid test score.');
        return;
      }

      if (testScore < 0 || testScore > 40) {
        _showError('Test score must be between 0 and 40.');
        return;
      }
    }

    if (hasExam) {
      examScore = num.tryParse(examText);

      if (examScore == null) {
        _showError('Enter a valid exam score.');
        return;
      }

      if (examScore < 0 || examScore > 60) {
        _showError('Exam score must be between 0 and 60.');
        return;
      }
    }

    final student = _selectedStudent;

    if (student == null) {
      _showError('Selected student could not be found.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      /*
       * The request now allows either score to be null.
       *
       * Examples:
       *
       * TEST ONLY:
       * testScore: 25
       * examScore: null
       *
       * EXAM ONLY:
       * testScore: null
       * examScore: 55
       *
       * BOTH:
       * testScore: 25
       * examScore: 55
       */

      final request = CreateAdminResultRequest(
        studentId: student.studentId,
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        testScore: testScore,
        examScore: examScore,
        remark: _remarkController.text.trim(),
      );

      /*
       * The notifier should decide which API endpoint to use:
       *
       * exam only -> /admin/results/exam
       * test only -> /admin/results/test
       * both      -> create both appropriately
       */

      final AdminResultModel? result = await ref
          .read(adminDashboardProvider.notifier)
          .createResult(
            schoolId: widget.schoolId,
            request: request,
          );

      if (!mounted) {
        return;
      }

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result created successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        context.pop(true);
      } else {
        _showError('Unable to create result.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to create result. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ================================================================
  // SCORE VALIDATOR
  // ================================================================

  String? _scoreValidator(
    String? value, {
    required num maximum,
    required String fieldName,
  }) {
    /*
     * Scores are OPTIONAL individually because the admin can
     * submit test only, exam only, or both.
     */

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final score = num.tryParse(value.trim());

    if (score == null) {
      return 'Enter a valid score';
    }

    if (score < 0 || score > maximum) {
      return '$fieldName must be 0 - $maximum';
    }

    return null;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: _isSubmitting
              ? null
              : () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textDark,
          ),
        ),
        title: const Text(
          'Create Result',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: dashboard.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(
              color: primary,
            ),
          );
        },
        error: (error, stackTrace) {
          return _errorState();
        },
        data: (_) {
          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  35,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),

                    const SizedBox(height: 18),

                    _academicSection(),

                    const SizedBox(height: 14),

                    _studentSection(),

                    const SizedBox(height: 14),

                    _scoreSection(),

                    const SizedBox(height: 14),

                    _remarkSection(),

                    const SizedBox(height: 24),

                    _createButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.assessment_rounded,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Student Result',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a class first, then choose the student and enter assessment details.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACADEMIC SECTION
  // ================================================================

  Widget _academicSection() {
    return _sectionCard(
      title: 'Academic Information',
      icon: Icons.school_outlined,
      children: [
        // ------------------------------------------------------------
        // CLASS
        // ------------------------------------------------------------

        _fieldLabel('Class'),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: _selectedClassId,
          isExpanded: true,
          decoration: _inputDecoration(
            hint: 'Select class first',
            icon: Icons.class_outlined,
          ),
          items: _classes.map<DropdownMenuItem<String>>(
            (schoolClass) {
              return DropdownMenuItem<String>(
                value: schoolClass.classId,
                child: Text(
                  _classLabel(schoolClass),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: _isSubmitting
              ? null
              : (value) {
                  setState(() {
                    _selectedClassId = value;

                    // Changing class MUST reset the student.
                    _selectedStudentId = null;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a class';
            }

            return null;
          },
        ),

        const SizedBox(height: 15),

        // ------------------------------------------------------------
        // SUBJECT
        // ------------------------------------------------------------

        _fieldLabel('Subject'),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: _selectedSubjectId,
          isExpanded: true,
          decoration: _inputDecoration(
            hint: 'Select subject',
            icon: Icons.menu_book_outlined,
          ),
          items: _subjects.map<DropdownMenuItem<String>>(
            (subject) {
              return DropdownMenuItem<String>(
                value: subject.subjectId,
                child: Text(
                  _subjectLabel(subject),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: _isSubmitting
              ? null
              : (value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a subject';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ================================================================
  // STUDENT SECTION
  // ================================================================

  Widget _studentSection() {
    final hasClass = _selectedClassId != null;
    final students = _classStudents;

    return _sectionCard(
      title: 'Student Information',
      icon: Icons.person_outline_rounded,
      children: [
        _fieldLabel('Student'),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: _selectedStudentId,
          isExpanded: true,
          decoration: _inputDecoration(
            hint: hasClass
                ? students.isEmpty
                    ? 'No students in this class'
                    : 'Select student'
                : 'Select class first',
            icon: Icons.person_outline_rounded,
          ),
          items: students.map<DropdownMenuItem<String>>(
            (student) {
              return DropdownMenuItem<String>(
                value: student.studentId,
                child: Text(
                  _studentLabel(student),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: _isSubmitting || !hasClass || students.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedStudentId = value;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              if (!hasClass) {
                return 'Please select a class first';
              }

              if (students.isEmpty) {
                return 'No students found in this class';
              }

              return 'Please select a student';
            }

            return null;
          },
        ),

        if (hasClass && students.isEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'There are no students assigned to this class.',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (!hasClass) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 15,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Select a class above to populate students.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ================================================================
  // STUDENT LABEL
  // ================================================================

  String _studentLabel(AdminStudentModel student) {
    final name = student.studentName.trim();

    if (name.isEmpty) {
      return student.studentId;
    }

    return name;
  }

  // ================================================================
  // CLASS LABEL
  // ================================================================

  String _classLabel(dynamic schoolClass) {
    final name = (
      schoolClass.className ??
      schoolClass.name ??
      ''
    ).toString().trim();

    return name.isEmpty ? 'Class' : name;
  }

  // ================================================================
  // SUBJECT LABEL
  // ================================================================

  String _subjectLabel(dynamic subject) {
    final name = (
      subject.subjectName ??
      subject.name ??
      ''
    ).toString().trim();

    final code = (
      subject.code ??
      ''
    ).toString().trim();

    if (name.isEmpty) {
      return code.isEmpty ? 'Subject' : code;
    }

    if (code.isEmpty) {
      return name;
    }

    return '$name ($code)';
  }

  // ================================================================
  // SCORE SECTION
  // ================================================================

  Widget _scoreSection() {
    return _sectionCard(
      title: 'Assessment Scores',
      icon: Icons.analytics_outlined,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can enter Test, Exam, or both scores.',
                  style: TextStyle(
                    color: primary.withOpacity(.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------------
            // TEST
            // --------------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Test Score'),

                  const SizedBox(height: 7),

                  TextFormField(
                    controller: _testController,
                    enabled: !_isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: _inputDecoration(
                      hint: 'Optional • 0 - 40',
                      icon: Icons.edit_note_rounded,
                    ),
                    validator: (value) {
                      return _scoreValidator(
                        value,
                        maximum: 40,
                        fieldName: 'Test score',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // --------------------------------------------------------
            // EXAM
            // --------------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Exam Score'),

                  const SizedBox(height: 7),

                  TextFormField(
                    controller: _examController,
                    enabled: !_isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: _inputDecoration(
                      hint: 'Optional • 0 - 60',
                      icon: Icons.assignment_outlined,
                    ),
                    validator: (value) {
                      return _scoreValidator(
                        value,
                        maximum: 60,
                        fieldName: 'Exam score',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        _totalPreview(),
      ],
    );
  }

  // ================================================================
  // TOTAL PREVIEW
  // ================================================================

  Widget _totalPreview() {
    final testText = _testController.text.trim();
    final examText = _examController.text.trim();

    final test = num.tryParse(testText) ?? 0;
    final exam = num.tryParse(examText) ?? 0;

    final hasTest = testText.isNotEmpty;
    final hasExam = examText.isNotEmpty;

    final total = test + exam;

    String label;

    if (hasTest && hasExam) {
      label = 'Total Score';
    } else if (hasTest) {
      label = 'Test Score';
    } else if (hasExam) {
      label = 'Exam Score';
    } else {
      label = 'Score';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_outlined,
            color: primary,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasTest && hasExam)
            const Text(
              ' / 100',
              style: TextStyle(
                color: primary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  String _formatScore(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  // ================================================================
  // REMARK
  // ================================================================

  Widget _remarkSection() {
    return _sectionCard(
      title: 'Teacher Remark',
      icon: Icons.comment_outlined,
      children: [
        _fieldLabel('Remark'),

        const SizedBox(height: 7),

        TextFormField(
          controller: _remarkController,
          enabled: !_isSubmitting,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            hint: 'Enter remark...',
            icon: Icons.comment_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a remark';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ================================================================
  // CREATE BUTTON
  // ================================================================

  Widget _createButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isSubmitting
            ? null
            : _createResult,
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          disabledBackgroundColor: primary.withOpacity(.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 21,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Create Result',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ================================================================
  // SECTION CARD
  // ================================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          ...children,
        ],
      ),
    );
  }

  // ================================================================
  // FIELD LABEL
  // ================================================================

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: textDark,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 11,
      ),
      prefixIcon: Icon(
        icon,
        color: primary,
        size: 19,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primary,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.4,
        ),
      ),
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEAEA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to Load Data',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Please try again.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton(
              onPressed: () {
                ref.invalidate(adminDashboardProvider);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(
                  color: primary,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
