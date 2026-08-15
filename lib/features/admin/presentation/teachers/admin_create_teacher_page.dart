import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminCreateTeacherPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateTeacherPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminCreateTeacherPage> createState() =>
      _AdminCreateTeacherPageState();
}

class _AdminCreateTeacherPageState
    extends ConsumerState<AdminCreateTeacherPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeNumberController = TextEditingController();

  bool _isCreating = false;
  bool _obscurePassword = true;

  // Optional if your backend requires a password.
  final _passwordController = TextEditingController();

  String get schoolId => widget.schoolId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeNumberController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ================================================================
  // CREATE
  // ================================================================

  Future<void> _createTeacher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final confirmed = await _showConfirmationDialog();

    if (confirmed != true || !mounted) {
      return;
    }

    await _submitTeacher();
  }

  // ================================================================
  // CONFIRMATION DIALOG
  // ================================================================

  Future<bool?> _showConfirmationDialog() {
    final name = _fullNameController.text.trim();
    final employeeNumber = _employeeNumberController.text.trim();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryLight,
                child: Icon(Icons.person_add_alt_1_rounded, color: primary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Create Teacher',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to create $name as a teacher?\n\n'
            'Employee No: ${employeeNumber.isEmpty ? 'N/A' : employeeNumber}',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'No',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primary),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Yes, Create'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // SUBMIT
  // ================================================================

  Future<void> _submitTeacher() async {
    setState(() {
      _isCreating = true;
    });

    final data = {
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'employeeNumber': _employeeNumberController.text.trim(),
      'phoneNumber': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),

      // Remove this if your API does not use password during teacher creation.
      if (_passwordController.text.trim().isNotEmpty)
        'password': _passwordController.text.trim(),
    };

    final teacher = await ref
        .read(adminDashboardProvider.notifier)
        .createTeacher(schoolId: schoolId, data: data);

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreating = false;
    });

    if (teacher != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher created successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to create teacher. Please try again.'),
        backgroundColor: Colors.red,
      ),
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

        title: const Text(
          'Add Teacher',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ====================================================
                // HEADER
                // ====================================================
                const Text(
                  'Create Teacher',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Enter the teacher information below to add '
                  'a new teacher to your school.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // ====================================================
                // FORM CARD
                // ====================================================
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Teacher Information',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // FULL NAME
                      // ==================================================
                      _fieldLabel('Full Name'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller: _fullNameController,

                        textCapitalization: TextCapitalization.words,

                        decoration: _inputDecoration(
                          hint: 'Enter teacher full name',
                          icon: Icons.person_outline_rounded,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the teacher name';
                          }

                          if (value.trim().length < 2) {
                            return 'Enter a valid teacher name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // EMPLOYEE NUMBER
                      // ==================================================
                      _fieldLabel('Employee Number'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller: _employeeNumberController,

                        keyboardType: TextInputType.text,

                        decoration: _inputDecoration(
                          hint: 'Enter employee number',
                          icon: Icons.badge_outlined,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the employee number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // EMAIL
                      // ==================================================
                      _fieldLabel('Email Address'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller: _emailController,

                        keyboardType: TextInputType.emailAddress,

                        decoration: _inputDecoration(
                          hint: 'teacher@example.com',
                          icon: Icons.email_outlined,
                        ),

                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Please enter an email address';
                          }

                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex.hasMatch(email)) {
                            return 'Enter a valid email address';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // PHONE
                      // ==================================================
                      _fieldLabel('Phone Number'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller: _phoneController,

                        keyboardType: TextInputType.phone,

                        decoration: _inputDecoration(
                          hint: '07000000000',
                          icon: Icons.phone_outlined,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // PASSWORD
                      // ==================================================
                      _fieldLabel('Password'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller: _passwordController,

                        obscureText: _obscurePassword,

                        decoration:
                            _inputDecoration(
                              hint: 'Enter password',
                              icon: Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ====================================================
                // CREATE BUTTON
                // ====================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    onPressed: _isCreating ? null : _createTeacher,

                    child: _isCreating
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
                              Icon(Icons.person_add_alt_1_rounded),
                              SizedBox(width: 9),
                              Text(
                                'Create Teacher',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // ====================================================
                // INFO
                // ====================================================
                Container(
                  padding: const EdgeInsets.all(13),

                  decoration: BoxDecoration(
                    color: primaryLight.withOpacity(.55),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: primary,
                        size: 18,
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          'Make sure the teacher information is '
                          'correct before creating the account.',
                          style: TextStyle(
                            color: primary.withOpacity(.85),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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
  // FIELD LABEL
  // ================================================================

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: textDark,
        fontSize: 12,
        fontWeight: FontWeight.w600,
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

      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),

      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),

      filled: true,
      fillColor: const Color(0xFFFAFAFC),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }
}
