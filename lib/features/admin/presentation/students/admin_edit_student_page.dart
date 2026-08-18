import 'package:app/features/admin/models/students/admin_class_model.dart';
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

class _AdminEditStudentPageState
    extends ConsumerState<AdminEditStudentPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _studentNumberController;

  String? _selectedClassId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.student.studentName,
    );

    _emailController = TextEditingController(
      text: widget.student.email,
    );

    _phoneController = TextEditingController(
      text: widget.student.phoneNumber ?? '',
    );

    _studentNumberController = TextEditingController(
      text: widget.student.studentNumber,
    );

    _selectedClassId = widget.student.classId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentNumberController.dispose();

    super.dispose();
  }

  // ================================================================
  // SAVE
  // ================================================================

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassId == null ||
        _selectedClassId!.trim().isEmpty) {
      _showError('Please select a class.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final data = AdminEditStudentModel(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      studentNumber: _studentNumberController.text.trim(),
      classRoomId: _selectedClassId!,
    );

    final updatedStudent = await ref
        .read(adminDashboardProvider.notifier)
        .updateStudent(
          studentId: widget.student.studentId,
          data: data,
        );

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student updated successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(updatedStudent);
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
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final dashboardState =
        ref.watch(adminDashboardProvider);

    final classes =
        dashboardState.value?.classes ?? [];

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textDark,
          ),
        ),

        title: const Text(
          'Edit Student',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              40,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                _header(),

                const SizedBox(height: 24),

                _sectionTitle('Student Information'),

                const SizedBox(height: 12),

                _textField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter student full name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
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
                    if (value == null ||
                        value.trim().isEmpty) {
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
                  keyboardType:
                      TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Email is required';
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegex.hasMatch(
                      value.trim(),
                    )) {
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
                  keyboardType:
                      TextInputType.phone,
                ),

                const SizedBox(height: 24),

                _sectionTitle('Class'),

                const SizedBox(height: 12),

                _classDropdown(classes),

                const SizedBox(height: 30),

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
              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Center(
              child: Text(
                _initials(widget.student.studentName),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,

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
                  widget.student.studentName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  widget.student.studentNumber.isEmpty
                      ? 'No student number'
                      : 'Student No: '
                          '${widget.student.studentNumber}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
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

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: primary,
        ),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder:
            const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(14),
          ),
          borderSide: BorderSide(
            color: primary,
            width: 1.4,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CLASS DROPDOWN
  // ================================================================

  Widget _classDropdown(
    List<AdminClassModel> classes,
  ) {
    final selectedExists = classes.any(
      (item) => item.classId == _selectedClassId,
    );

    final effectiveValue = selectedExists
        ? _selectedClassId
        : null;

    return DropdownButtonFormField<String>(
      value: effectiveValue,

      isExpanded: true,

      decoration: InputDecoration(
        labelText: 'Class',
        hintText: 'Select student class',

        prefixIcon: const Icon(
          Icons.class_outlined,
          color: primary,
        ),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder:
            const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(14),
          ),
          borderSide: BorderSide(
            color: primary,
            width: 1.4,
          ),
        ),
      ),

      items: classes.map((schoolClass) {
        return DropdownMenuItem<String>(
          value: schoolClass.classId,

          child: Text(
            schoolClass.className,
            overflow:
                TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: _isSaving
          ? null
          : (value) {
              setState(() {
                _selectedClassId = value;
              });
            },

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select a class';
        }

        return null;
      },
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
        onPressed:
            _isSaving ? null : _saveStudent,

        style: FilledButton.styleFrom(
          backgroundColor: primary,
          disabledBackgroundColor:
              primary.withValues(alpha: 0.5),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),

        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_outlined,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
        .where(
          (item) => item.trim().isNotEmpty,
        )
        .toList();

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}