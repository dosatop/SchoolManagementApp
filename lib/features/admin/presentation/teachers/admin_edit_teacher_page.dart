import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminEditTeacherPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String teacherId;

  // Optional initial values from the teacher list.
  // This allows the page to open immediately with existing data.
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? gender;

  const AdminEditTeacherPage({
    super.key,
    required this.schoolId,
    required this.teacherId,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.gender,
  });

  @override
  ConsumerState<AdminEditTeacherPage> createState() =>
      _AdminEditTeacherPageState();
}

class _AdminEditTeacherPageState
    extends ConsumerState<AdminEditTeacherPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _selectedGender;

  bool _isLoading = false;

  String get schoolId => widget.schoolId;

  String get teacherId => widget.teacherId;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(
      text: widget.fullName ?? '',
    );

    _emailController = TextEditingController(
      text: widget.email ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.phoneNumber ?? '',
    );

    _selectedGender = widget.gender;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // ================================================================
  // UPDATE TEACHER
  // ================================================================

  Future<void> _updateTeacher() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      _showMessage('Please select the teacher\'s gender.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /*
       * ============================================================
       * CONNECT YOUR PROVIDER HERE
       * ============================================================
       *
       * Example:
       *
       * await ref
       *     .read(adminTeachersProvider.notifier)
       *     .updateTeacher(
       *       teacherId: teacherId,
       *       schoolId: schoolId,
       *       fullName: _fullNameController.text.trim(),
       *       email: _emailController.text.trim(),
       *       phoneNumber: _phoneController.text.trim(),
       *       gender: _selectedGender!,
       *     );
       */

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      _showMessage(
        'Teacher updated successfully.',
        success: true,
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) return;

      // Return true so the teacher list knows an update happened.
      context.pop(true);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to update teacher. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
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

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          onPressed: _isLoading
              ? null
              : () {
                  context.pop();
                },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),

        title: const Text(
          'Edit Teacher',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),

            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              40,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                _pageHeader(),

                const SizedBox(height: 25),

                // ==================================================
                // PERSONAL INFORMATION
                // ==================================================

                _sectionTitle(
                  title: 'Teacher Information',
                  subtitle: 'Update the teacher\'s personal details.',
                ),

                const SizedBox(height: 14),

                _inputField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter teacher full name',
                  icon: Icons.person_outline_rounded,
                  textCapitalization:
                      TextCapitalization.words,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Full name is required';
                    }

                    if (value.trim().length < 3) {
                      return 'Enter a valid full name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 13),

                _inputField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'teacher@example.com',
                  icon: Icons.email_outlined,
                  keyboardType:
                      TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Email address is required';
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegex.hasMatch(
                      value.trim(),
                    )) {
                      return 'Enter a valid email address';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 13),

                _inputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '08012345678',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Phone number is required';
                    }

                    if (value.trim().length < 10) {
                      return 'Enter a valid phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 13),

                // ==================================================
                // GENDER
                // ==================================================

                _genderField(),

                const SizedBox(height: 28),

                // ==================================================
                // SCHOOL
                // ==================================================

                _schoolInfoCard(),

                const SizedBox(height: 28),

                // ==================================================
                // UPDATE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : _updateTeacher,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor:
                          primary.withOpacity(.55),
                      foregroundColor: Colors.white,
                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            width: 23,
                            height: 23,
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
                                size: 21,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Teacher ID: $teacherId',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
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
  // HEADER
  // ================================================================

  Widget _pageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            Color(0xFF2437C5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Teacher',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Update this teacher\'s information.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
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

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // INPUT
  // ================================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,

      style: const TextStyle(
        color: textDark,
        fontSize: 14,
      ),

      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  // ================================================================
  // GENDER
  // ================================================================

  Widget _genderField() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,

      decoration: _inputDecoration(
        label: 'Gender',
        hint: 'Select teacher gender',
        icon: Icons.wc_outlined,
      ),

      items: const [
        DropdownMenuItem(
          value: 'Male',
          child: Text('Male'),
        ),
        DropdownMenuItem(
          value: 'Female',
          child: Text('Female'),
        ),
      ],

      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _selectedGender = value;
              });
            },

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Gender is required';
        }

        return null;
      },
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 13,
      ),

      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13,
      ),

      prefixIcon: Icon(
        icon,
        color: primary,
        size: 21,
      ),

      filled: true,
      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ================================================================
  // SCHOOL INFO
  // ================================================================

  Widget _schoolInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withOpacity(.10),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.school_outlined,
              color: primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'School Assignment',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'School ID: $schoolId',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'This teacher belongs to your school.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}