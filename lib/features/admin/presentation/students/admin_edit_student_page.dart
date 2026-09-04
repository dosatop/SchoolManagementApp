import 'package:app/features/admin/models/classes/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_edit_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminEditStudentPage extends ConsumerStatefulWidget {
  final String schoolId;
  final AdminStudentModel student;

  const AdminEditStudentPage({
    super.key,
    required this.schoolId,
    required this.student,
  });

  @override
  ConsumerState<AdminEditStudentPage> createState() =>
      _AdminEditStudentPageState();
}

class _AdminEditStudentPageState extends ConsumerState<AdminEditStudentPage> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  // ================================================================
  // FORM
  // ================================================================

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _studentNumberController;

  // ================================================================
  // ACADEMIC SELECTIONS
  // ================================================================

  String? _selectedClassId;
  String? _selectedDepartmentId;
  String? _selectedTradeId;
  String? _selectedTradeSubjectId;

  bool _isSaving = false;
  bool _isLoadingStudent = true;

  // ================================================================
  // INIT
  // ================================================================

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.student.studentName);

    _emailController = TextEditingController(text: widget.student.email ?? '');

    _phoneController = TextEditingController(
      text: widget.student.phoneNumber ?? '',
    );

    _studentNumberController = TextEditingController(
      text: widget.student.studentNumber,
    );

    _selectedClassId = widget.student.classId;
    _selectedDepartmentId = widget.student.departmentId;
    _selectedTradeId = widget.student.tradeId;
    _selectedTradeSubjectId = widget.student.tradeSubjectId;

    _loadStudentDetails();
  }

  // ================================================================
  // LOAD STUDENT DETAILS
  // ================================================================

  Future<void> _loadStudentDetails() async {
    try {
      final detail = await ref.read(
        adminStudentDetailsProvider(widget.student.studentId).future,
      );

      if (!mounted) {
        return;
      }

      _nameController.text = detail.studentName;
      _emailController.text = detail.email;
      _phoneController.text = detail.phoneNumber ?? '';
      _studentNumberController.text = detail.studentNumber;

      setState(() {
        _selectedClassId = detail.classId;
        _selectedDepartmentId = detail.departmentId;
        _selectedTradeId = detail.tradeId;
        _selectedTradeSubjectId = detail.tradeSubjectId;
        _isLoadingStudent = false;
      });
    } catch (error, stackTrace) {
      debugPrint('LOAD STUDENT DETAILS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingStudent = false;
      });
    }
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentNumberController.dispose();

    super.dispose();
  }

  // ================================================================
  // SAVE STUDENT
  // ================================================================

  Future<void> _saveStudent() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ============================================================
    // CLASS REQUIRED
    // ============================================================

    if (_selectedClassId == null || _selectedClassId!.trim().isEmpty) {
      _showError('Please select a class.');
      return;
    }

    // ============================================================
    // FIND SELECTED CLASS
    // ============================================================

    final dashboardState = ref.read(adminDashboardProvider);

    final classes = dashboardState.value?.classes ?? [];

    AdminClassModel? selectedClass;

    for (final item in classes) {
      if (item.classId == _selectedClassId) {
        selectedClass = item;
        break;
      }
    }

    if (selectedClass == null) {
      _showError('Selected class could not be found.');
      return;
    }

    // ============================================================
    // SENIOR
    // ============================================================

    final isSenior = selectedClass.schoolLevelId == 2;

    // ============================================================
    // SENIOR DEPARTMENT REQUIRED
    // ============================================================

    if (isSenior &&
        (_selectedDepartmentId == null ||
            _selectedDepartmentId!.trim().isEmpty)) {
      _showError('Please select a department for this student.');
      return;
    }

    // ============================================================
    // JUNIOR CANNOT HAVE DEPARTMENT
    // ============================================================

    if (!isSenior) {
      _selectedDepartmentId = null;
    }

    // ============================================================
    // TRADE SUBJECT REQUIRED WHEN TRADE IS SELECTED
    // ============================================================

    if (_selectedTradeId != null &&
        _selectedTradeId!.trim().isNotEmpty &&
        (_selectedTradeSubjectId == null ||
            _selectedTradeSubjectId!.trim().isEmpty)) {
      _showError('Please select a trade subject.');
      return;
    }

    // ============================================================
    // START SAVING
    // ============================================================

    setState(() {
      _isSaving = true;
    });

    try {
      final data = AdminEditStudentModel(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        studentNumber: _studentNumberController.text.trim(),
        classRoomId: _selectedClassId!,
        departmentId: _selectedDepartmentId,
        tradeId: _selectedTradeId,
        tradeSubjectId: _selectedTradeSubjectId,
      );

      final updatedStudent = await ref
          .read(adminDashboardProvider.notifier)
          .updateStudent(studentId: widget.student.studentId, data: data);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      if (updatedStudent == null) {
        _showError('Unable to update student. Please try again.');
        return;
      }

      Navigator.of(context).pop(updatedStudent);
    } catch (error, stackTrace) {
      debugPrint('UPDATE STUDENT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showError('Something went wrong while updating the student.');
    }
  }

  // ================================================================
  // ERROR MESSAGE
  // ================================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);

    final classes = dashboardState.value?.classes ?? [];
    final departments = dashboardState.value?.departments ?? [];
    final trades = dashboardState.value?.trades ?? [];
    final subjects = dashboardState.value?.subjects ?? [];

    // ================================================================
    // SELECTED CLASS
    // ================================================================

    AdminClassModel? selectedClass;

    for (final item in classes) {
      if (item.classId == _selectedClassId) {
        selectedClass = item;
        break;
      }
    }

    // ================================================================
    // SCHOOL LEVEL
    // ================================================================

    final isSenior = selectedClass?.schoolLevelId == 2;

    // ================================================================
    // TRADE SUBJECTS
    // ================================================================

    final filteredSubjects = subjects.where((subject) {
      return subject.tradeId == _selectedTradeId;
    }).toList();

    // ================================================================
    // VALID TRADE SUBJECT
    // ================================================================

    final validTradeSubjectId =
        filteredSubjects.any(
          (subject) => subject.subjectId == _selectedTradeSubjectId,
        )
        ? _selectedTradeSubjectId
        : null;

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),

          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),

        title: const Text(
          'Edit Student',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: _isLoadingStudent
            ? const Center(child: CircularProgressIndicator(color: primary))
            : Form(
                key: _formKey,

                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================
                      _header(),

                      const SizedBox(height: 24),

                      // ==================================================
                      // STUDENT INFORMATION
                      // ==================================================
                      _sectionTitle('Student Information'),

                      const SizedBox(height: 12),

                      _textField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter student full name',
                        icon: Icons.person_outline_rounded,

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _textField(
                        controller: _studentNumberController,
                        label: 'Student Number',
                        hint: 'Enter student number',
                        icon: Icons.badge_outlined,

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Student number is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _textField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter student email',
                        icon: Icons.email_outlined,

                        keyboardType: TextInputType.emailAddress,

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }

                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _textField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // ACADEMIC INFORMATION
                      // ==================================================
                      _sectionTitle('Academic Information'),

                      const SizedBox(height: 12),

                      // ==================================================
                      // CLASS
                      // ==================================================
                      _dropdown(
                        label: 'Class',
                        hint: 'Select class',
                        icon: Icons.class_outlined,
                        value: _selectedClassId,

                        items: classes.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.classId,

                            child: Text(
                              item.className,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),

                        onChanged: (value) {
                          AdminClassModel? selected;

                          for (final item in classes) {
                            if (item.classId == value) {
                              selected = item;
                              break;
                            }
                          }

                          final senior = selected?.schoolLevelId == 2;

                          setState(() {
                            _selectedClassId = value;

                            if (!senior) {
                              _selectedDepartmentId = null;
                            }
                          });
                        },

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select a class';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // SCHOOL LEVEL
                      // ==================================================
                      _readOnlyField(
                        label: 'School Level',

                        value: selectedClass == null
                            ? 'Not available'
                            : isSenior
                            ? 'Senior'
                            : 'Junior',

                        icon: Icons.school_outlined,
                      ),

                      // ==================================================
                      // DEPARTMENT
                      // ==================================================
                      if (isSenior) ...[
                        const SizedBox(height: 14),

                        _dropdown(
                          label: 'Department',
                          hint: 'Select department',
                          icon: Icons.account_tree_outlined,

                          value: _selectedDepartmentId,

                          items: departments.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.departmentId,

                              child: Text(
                                item.departmentName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          onChanged: (value) {
                            setState(() {
                              _selectedDepartmentId = value;
                            });
                          },

                          validator: (value) {
                            if (isSenior &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Department is required';
                            }

                            return null;
                          },
                        ),
                      ],

                      // ==================================================
                      // TRADE
                      // ==================================================
                      const SizedBox(height: 14),

                      _dropdown(
                        label: 'Trade',
                        hint: 'Select trade (optional)',
                        icon: Icons.construction_outlined,

                        value: _selectedTradeId,

                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No trade'),
                          ),

                          ...trades.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.tradeId,

                              child: Text(
                                item.tradeName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],

                        onChanged: (value) {
                          setState(() {
                            _selectedTradeId = value;

                            // Changing/removing trade means the
                            // previous subject is no longer valid.
                            _selectedTradeSubjectId = null;
                          });
                        },
                      ),

                      // ==================================================
                      // TRADE SUBJECT
                      // ==================================================
                      if (_selectedTradeId != null &&
                          _selectedTradeId!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),

                        _dropdown(
                          label: 'Trade Subject *',
                          hint: 'Select trade subject',
                          icon: Icons.menu_book_outlined,

                          value: validTradeSubjectId,

                          items: filteredSubjects.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.subjectId,

                              child: Text(
                                item.subjectName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          onChanged: (value) {
                            setState(() {
                              _selectedTradeSubjectId = value;
                            });
                          },

                          // IMPORTANT:
                          // Trade selected = subject required.
                          validator: (value) {
                            if (_selectedTradeId != null &&
                                _selectedTradeId!.trim().isNotEmpty &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Trade subject is required';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 7),

                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),

                            const SizedBox(width: 6),

                            Expanded(
                              child: Text(
                                'A trade subject is required when a trade is selected.',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 30),

                      // ==================================================
                      // SAVE BUTTON
                      // ==================================================
                      _saveButton(),
                    ],
                  ),
                ),
              ),
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
        color: primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Center(
              child: Text(
                _initials(_nameController.text),

                style: const TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Update student',

                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _nameController.text,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _studentNumberController.text.isEmpty
                      ? 'No student number'
                      : 'Student No: '
                            '${_studentNumberController.text}',

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DROPDOWN
  // ================================================================

  Widget _dropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final exists = items.any((item) => item.value == value);

    return DropdownButtonFormField<String>(
      initialValue: exists ? value : null,

      isExpanded: true,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(icon, color: primary),

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

        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.4),
        ),
      ),

      items: items,

      onChanged: _isSaving ? null : onChanged,

      validator: validator,
    );
  }

  // ================================================================
  // READ ONLY FIELD
  // ================================================================

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,

      enabled: false,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(icon, color: primary),

        filled: true,

        fillColor: Colors.grey.shade100,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType: keyboardType,

      validator: validator,

      enabled: !_isSaving,

      textCapitalization: TextCapitalization.words,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(icon, color: primary),

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

        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),

          borderSide: BorderSide(color: primary, width: 1.4),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: Colors.red, width: 1.4),
        ),
      ),
    );
  }

  // ================================================================
  // SAVE BUTTON
  // ================================================================

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,

      child: FilledButton(
        onPressed: _isSaving ? null : _saveStudent,

        style: FilledButton.styleFrom(
          backgroundColor: primary,

          disabledBackgroundColor: primary.withValues(alpha: 0.5),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        child: _isSaving
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
                  Icon(Icons.save_outlined),

                  SizedBox(width: 8),

                  Text(
                    'Save Changes',

                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        color: textDark,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ================================================================
  // INITIALS
  // ================================================================

  String _initials(String name) {
    final value = name.trim();

    if (value.isEmpty) {
      return 'S';
    }

    final parts = value
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
