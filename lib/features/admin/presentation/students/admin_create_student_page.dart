import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCreateStudentPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateStudentPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminCreateStudentPage> createState() =>
      _AdminCreateStudentPageState();
}

class _AdminCreateStudentPageState
    extends ConsumerState<AdminCreateStudentPage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentNumberController = TextEditingController();

  String? _selectedClassId;
  bool _isCreating = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  // ================================================================
  // CREATE STUDENT
  // ================================================================

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a class.')));
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final student = await ref
          .read(adminDashboardProvider.notifier)
          .createStudent(
            schoolId: widget.schoolId,
            data: AdminCreateStudentModel(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              studentNumber: _studentNumberController.text.trim(),
              classRoomId: _selectedClassId!,
            ),
          );

      if (!mounted) return;

      if (student != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student created successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create student.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create student: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);
    final classes = dashboardState.value?.classes ?? [];

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Add Student',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================
                const Text(
                  'Create Student',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Register a new student and assign them to a class.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // FORM CARD
                // ==================================================
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
                      _fieldLabel('Full Name'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _fullNameController,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          hint: 'Enter student full name',
                          icon: Icons.person_outline_rounded,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      _fieldLabel('Email'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emailController,

                        keyboardType: TextInputType.emailAddress,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          hint: 'Enter student email',
                          icon: Icons.email_outlined,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }

                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      _fieldLabel('Password'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,

                        obscureText: _obscurePassword,

                        textInputAction: TextInputAction.next,

                        decoration:
                            _inputDecoration(
                              hint: 'Enter student password',
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

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }

                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      _fieldLabel('Student Number'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _studentNumberController,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          hint: 'e.g. 01',
                          icon: Icons.badge_outlined,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Student number is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      _fieldLabel('Class'),

                      const SizedBox(height: 8),

                      if (dashboardState.isLoading && classes.isEmpty)
                        Container(
                          height: 56,

                          padding: const EdgeInsets.symmetric(horizontal: 15),

                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primary,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Loading classes...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else if (dashboardState.hasError && classes.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),

                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: const Text(
                            'Unable to load classes. Please go back and try again.',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        )
                      else if (classes.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),

                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: const Text(
                            'No classes are available for this school.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedClassId,

                          isExpanded: true,

                          decoration: _inputDecoration(
                            hint: 'Select class',
                            icon: Icons.class_outlined,
                          ),

                          items: classes.map((schoolClass) {
                            return DropdownMenuItem<String>(
                              value: schoolClass.classId,
                              child: Text(
                                schoolClass.className,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          onChanged: _isCreating
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedClassId = value;
                                  });
                                },

                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a class';
                            }

                            return null;
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // CREATE BUTTON
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed: _isCreating || classes.isEmpty
                        ? null
                        : _createStudent,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

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
                              Icon(Icons.person_add_alt_1_rounded, size: 20),
                              SizedBox(width: 9),
                              Text(
                                'Create Student',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'The student will be assigned to your school automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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
        fontSize: 13,
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

      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),

      prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),

      filled: true,
      fillColor: Colors.grey.shade50,

      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),

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
    );
  }
}
