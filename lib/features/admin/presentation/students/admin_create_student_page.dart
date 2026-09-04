import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:dio/dio.dart';
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
  String? _selectedDepartmentId;
  String? _selectedTradeId;

  bool _isCreating = false;
  bool _obscurePassword = true;

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        return responseData['message'].toString();
      }

      if (responseData is Map && responseData['error'] != null) {
        return responseData['error'].toString();
      }

      return error.message ?? 'Something went wrong.';
    }

    return error.toString();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class first.'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    // Trade is compulsory.
    if (_selectedTradeId == null || _selectedTradeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a trade.'),
          backgroundColor: Colors.orange,
        ),
      );

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

              // Department is optional and only available
              // for classes that support departments.
              departmentId: _selectedDepartmentId,

              // Trade is compulsory.
              tradeId: _selectedTradeId,

              // Class is compulsory.
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
          content: Text(_getErrorMessage(error)),
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
  // CLASS / DEPARTMENT LOGIC
  // ================================================================

  bool _isSeniorClass(String className) {
    final name = className.toLowerCase().trim();

    return RegExp(r'\byear\s*(10|11|12)\b').hasMatch(name) ||
        (RegExp(r'\b(10|11|12)\b').hasMatch(name) &&
            (name.contains('year') ||
                name.contains('level') ||
                name.contains('ss')));
  }

  bool _classAllowsDepartment(String? classId, List<dynamic> classes) {
    if (classId == null || classId.isEmpty) {
      return false;
    }

    final selectedClass = classes.cast<dynamic>().where((schoolClass) {
      return schoolClass.classId == classId;
    }).firstOrNull;

    if (selectedClass == null) {
      return false;
    }

    return _isSeniorClass(selectedClass.className.toString());
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);
    final notifier = ref.read(adminDashboardProvider.notifier);

    final allClasses = notifier.getClassesForSchool(widget.schoolId);
    final departments = notifier.getDepartmentsForSchool(widget.schoolId);
    final trades = notifier.getTradesForSchool(widget.schoolId);

    final selectedClass = _selectedClassId == null
        ? null
        : allClasses.cast<dynamic>().where((schoolClass) {
            return schoolClass.classId == _selectedClassId;
          }).firstOrNull;

    final classSelected =
        _selectedClassId != null && _selectedClassId!.isNotEmpty;

    final departmentAvailable =
        selectedClass != null &&
        _isSeniorClass(selectedClass.className.toString());

    // A junior class cannot have a department.
    if (classSelected &&
        !departmentAvailable &&
        _selectedDepartmentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedDepartmentId != null) {
          setState(() {
            _selectedDepartmentId = null;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: _isCreating
              ? null
              : () {
                  context.pop();
                },
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),
        title: const Text(
          'Add Student',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                  'Register a new student and assign them '
                  'to a class, department and trade.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 25),

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
                      // ==================================================
                      // FULL NAME
                      // ==================================================
                      _fieldLabel('Full Name'),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        enabled: !_isCreating,
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

                      // ==================================================
                      // EMAIL
                      // ==================================================
                      _fieldLabel('Email'),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isCreating,
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

                      // ==================================================
                      // PASSWORD
                      // ==================================================
                      _fieldLabel('Password'),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        enabled: !_isCreating,
                        decoration:
                            _inputDecoration(
                              hint: 'Enter student password',
                              icon: Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: _isCreating
                                    ? null
                                    : () {
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

                      // ==================================================
                      // STUDENT NUMBER
                      // ==================================================
                      _fieldLabel('Student Number'),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _studentNumberController,
                        textInputAction: TextInputAction.next,
                        enabled: !_isCreating,
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

                      const SizedBox(height: 24),

                      // ==================================================
                      // STEP 1 — CLASS
                      // ==================================================
                      _sectionTitle('Step 1', 'Select Class'),

                      const SizedBox(height: 5),

                      Text(
                        'Choose the student class first. '
                        'The class determines whether a department '
                        'can be selected.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (dashboardState.isLoading && allClasses.isEmpty)
                        _loadingDropdown(text: 'Loading classes...')
                      else if (dashboardState.hasError && allClasses.isEmpty)
                        _emptyDropdown(
                          text: 'Unable to load classes. Please try again.',
                          color: Colors.red,
                        )
                      else if (allClasses.isEmpty)
                        _emptyDropdown(
                          text: 'No classes are available for this school.',
                          color: Colors.orange,
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hint: 'Select class',
                            icon: Icons.class_outlined,
                          ),
                          items: allClasses.map((schoolClass) {
                            final className = schoolClass.className;

                            final isSenior = _isSeniorClass(
                              className.toLowerCase(),
                            );

                            return DropdownMenuItem<String>(
                              value: schoolClass.classId,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSenior
                                          ? primary.withOpacity(.08)
                                          : Colors.orange.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isSenior ? 'Senior' : 'Junior',
                                      style: TextStyle(
                                        color: isSenior
                                            ? primary
                                            : Colors.orange.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      className,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isCreating
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedClassId = value;

                                    // Class changed, therefore
                                    // department and trade must
                                    // be selected again.
                                    _selectedDepartmentId = null;
                                    _selectedTradeId = null;
                                  });
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a class';
                            }

                            return null;
                          },
                        ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // STEP 2 — DEPARTMENT
                      // ==================================================
                      _sectionTitle('Step 2', 'Department'),

                      const SizedBox(height: 5),

                      if (!classSelected)
                        _disabledInfo(
                          icon: Icons.lock_outline_rounded,
                          text:
                              'Select a class first before choosing a department.',
                        )
                      else if (!departmentAvailable)
                        _disabledInfo(
                          icon: Icons.info_outline_rounded,
                          text:
                              'This is a Junior class. Department selection is not available.',
                        )
                      else if (dashboardState.isLoading && departments.isEmpty)
                        _loadingDropdown(text: 'Loading departments...')
                      else if (dashboardState.hasError && departments.isEmpty)
                        _emptyDropdown(
                          text: 'Unable to load departments. Please try again.',
                          color: Colors.red,
                        )
                      else if (departments.isEmpty)
                        _emptyDropdown(
                          text: 'No departments are available for this school.',
                          color: Colors.orange,
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedDepartmentId,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hint: 'Select department (optional)',
                            icon: Icons.account_tree_outlined,
                          ),
                          items: departments.map((department) {
                            return DropdownMenuItem<String>(
                              value: department.departmentId,
                              child: Text(
                                department.departmentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _isCreating
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedDepartmentId = value;
                                  });
                                },
                          validator: (_) => null,
                        ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // STEP 3 — TRADE
                      // ==================================================
                      _sectionTitle('Step 3', 'Trade'),

                      const SizedBox(height: 5),

                      Text(
                        'Trade is compulsory. You can choose any available trade.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (!classSelected)
                        _disabledInfo(
                          icon: Icons.lock_outline_rounded,
                          text: 'Select a class first before choosing a trade.',
                        )
                      else if (dashboardState.isLoading && trades.isEmpty)
                        _loadingDropdown(text: 'Loading trades...')
                      else if (dashboardState.hasError && trades.isEmpty)
                        _emptyDropdown(
                          text: 'Unable to load trades. Please try again.',
                          color: Colors.red,
                        )
                      else if (trades.isEmpty)
                        _emptyDropdown(
                          text:
                              'No trades are available. A trade is required to create the student.',
                          color: Colors.red,
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedTradeId,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            hint: 'Select trade',
                            icon: Icons.construction_outlined,
                          ),
                          items: trades.map((trade) {
                            return DropdownMenuItem<String>(
                              value: trade.tradeId,
                              child: Text(
                                trade.code.isEmpty
                                    ? trade.tradeName
                                    : '${trade.tradeName} (${trade.code})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _isCreating
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedTradeId = value;
                                  });
                                },
                          validator: (value) {
                            if (!classSelected) {
                              return null;
                            }

                            if (value == null || value.isEmpty) {
                              return 'Please select a trade';
                            }

                            return null;
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ========================================================
                // CREATE BUTTON
                // ========================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _isCreating || allClasses.isEmpty || trades.isEmpty
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
                    'The student will be assigned to this school automatically.',
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
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle(String step, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // DISABLED INFO
  // ================================================================

  Widget _disabledInfo({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOADING DROPDOWN
  // ================================================================

  Widget _loadingDropdown({required String text}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: primary),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY DROPDOWN
  // ================================================================

  Widget _emptyDropdown({required String text, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
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
