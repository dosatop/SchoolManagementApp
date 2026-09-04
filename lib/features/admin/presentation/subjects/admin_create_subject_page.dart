import 'package:app/features/admin/models/subjects/admin_create_subject_model.dart';
import 'package:app/features/admin/models/students/admin_department_model.dart';
import 'package:app/features/admin/models/subjects/admin_trade_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCreateSubjectPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateSubjectPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminCreateSubjectPage> createState() =>
      _AdminCreateSubjectPageState();
}

class _AdminCreateSubjectPageState
    extends ConsumerState<AdminCreateSubjectPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;

  // ================================================================
  // SUBJECT TYPE
  // ================================================================
  //
  // 1 = General
  // 2 = Department
  // 3 = Trade
  //
  // The user selects the category and we automatically determine
  // the type sent to the API.
  // ================================================================

  int _selectedType = 1;

  String? _selectedDepartmentId;
  String? _selectedTradeId;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ================================================================
  // CREATE SUBJECT
  // ================================================================

  Future<void> _createSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Department subject must have a department.
    if (_selectedType == 2 &&
        (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty)) {
      _showError('Please select a department.');
      return;
    }

    // Trade subject must have a trade.
    if (_selectedType == 3 &&
        (_selectedTradeId == null || _selectedTradeId!.isEmpty)) {
      _showError('Please select a trade.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    // ==============================================================
    // BUILD REQUEST
    // ==============================================================
    //
    // General:
    // {
    //   name,
    //   code,
    //   type: 1
    // }
    //
    // Department:
    // {
    //   name,
    //   code,
    //   type: 2,
    //   departmentId
    // }
    //
    // Trade:
    // {
    //   name,
    //   code,
    //   type: 3,
    //   tradeId
    // }
    // ==============================================================

    final data = AdminCreateSubjectModel(
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      type: _selectedType,
      departmentId: _selectedType == 2 ? _selectedDepartmentId : null,
      tradeId: _selectedType == 3 ? _selectedTradeId : null,
    );

    try {
      final subject = await ref
          .read(adminDashboardProvider.notifier)
          .createSubject(schoolId: widget.schoolId, data: data);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (subject != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        context.pop();
      } else {
        _showError('Unable to create subject.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError('Unable to create subject. Please try again.');
    }
  }

  // ================================================================
  // ERROR
  // ================================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ================================================================
  // CHANGE TYPE
  // ================================================================

  void _changeType(int type) {
    if (_isLoading) {
      return;
    }

    setState(() {
      _selectedType = type;

      // Clear unrelated selections.
      if (type != 2) {
        _selectedDepartmentId = null;
      }

      if (type != 3) {
        _selectedTradeId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: background,

      // ================================================================
      // APP BAR
      // ================================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 8,

        leading: IconButton(
          onPressed: _isLoading
              ? null
              : () {
                  context.pop();
                },
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Subject',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Create a new subject',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),

      // ================================================================
      // BODY
      // ================================================================
      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 35),

            children: [
              // ==========================================================
              // HEADER
              // ==========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: primary,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Subject',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Create a general, department or trade subject.',
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
              ),

              const SizedBox(height: 28),

              // ==========================================================
              // SUBJECT NAME
              // ==========================================================
              const Text(
                'Subject Name',
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,

                decoration: _inputDecoration(
                  hintText: 'e.g. Mathematics',
                  icon: Icons.menu_book_outlined,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the subject name';
                  }

                  if (value.trim().length < 2) {
                    return 'Subject name is too short';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==========================================================
              // SUBJECT CODE
              // ==========================================================
              const Text(
                'Subject Code',
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,

                decoration: _inputDecoration(
                  hintText: 'e.g. MAT',
                  icon: Icons.code_rounded,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the subject code';
                  }

                  if (value.trim().length < 2) {
                    return 'Subject code is too short';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              Text(
                'Use a short code such as MAT, ENG, PHY or BIO.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),

              const SizedBox(height: 25),

              // ==========================================================
              // SUBJECT CATEGORY
              // ==========================================================
              const Text(
                'Subject Category',
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose where this subject belongs.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // TYPE SELECTOR
              // ==========================================================
              Row(
                children: [
                  Expanded(
                    child: _typeCard(
                      type: 1,
                      title: 'General',
                      subtitle: 'All students',
                      icon: Icons.public_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _typeCard(
                      type: 2,
                      title: 'Department',
                      subtitle: 'Department',
                      icon: Icons.account_tree_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _typeCard(
                      type: 3,
                      title: 'Trade',
                      subtitle: 'Trade',
                      icon: Icons.build_rounded,
                    ),
                  ),
                ],
              ),

              // ==========================================================
              // DEPARTMENT SELECTOR
              // ==========================================================
              if (_selectedType == 2) ...[
                const SizedBox(height: 20),

                const Text(
                  'Department',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                dashboardState.when(
                  loading: () => _loadingDropdown(),

                  error: (_, __) =>
                      _dropdownError('Unable to load departments'),

                  data: (dashboard) {
                    final departments = dashboard.departments
                        .where(
                          (department) =>
                              department.schoolId == widget.schoolId,
                        )
                        .toList();

                    if (departments.isEmpty) {
                      return _dropdownError(
                        'No departments found for this school.',
                      );
                    }

                    return _departmentDropdown(departments);
                  },
                ),
              ],

              // ==========================================================
              // TRADE SELECTOR
              // ==========================================================
              if (_selectedType == 3) ...[
                const SizedBox(height: 20),

                const Text(
                  'Trade',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                dashboardState.when(
                  loading: () => _loadingDropdown(),

                  error: (_, __) => _dropdownError('Unable to load trades'),

                  data: (dashboard) {
                    final trades = dashboard.trades
                        .where((trade) => trade.schoolId == widget.schoolId)
                        .toList();

                    if (trades.isEmpty) {
                      return _dropdownError('No trades found for this school.');
                    }

                    return _tradeDropdown(trades);
                  },
                ),
              ],

              const SizedBox(height: 35),

              // ==========================================================
              // CREATE BUTTON
              // ==========================================================
              SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createSubject,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,

                    disabledBackgroundColor: primary.withOpacity(.5),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    elevation: 0,
                  ),

                  child: _isLoading
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
                            Icon(Icons.add_rounded, size: 21),

                            SizedBox(width: 8),

                            Text(
                              'Create Subject',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
  // TYPE CARD
  // ================================================================

  Widget _typeCard({
    required int type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selectedType == type;

    return GestureDetector(
      onTap: () => _changeType(type),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),

        decoration: BoxDecoration(
          color: selected ? primaryLight : Colors.white,

          borderRadius: BorderRadius.circular(13),

          border: Border.all(
            color: selected ? primary : Colors.grey.shade200,

            width: selected ? 1.5 : 1,
          ),
        ),

        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color: selected ? primary : const Color(0xFFF3F4F8),

                borderRadius: BorderRadius.circular(11),
              ),

              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,

              style: TextStyle(
                color: selected ? primary : textDark,

                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              subtitle,
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DEPARTMENT DROPDOWN
  // ================================================================

  Widget _departmentDropdown(List<AdminDepartmentModel> departments) {
    return DropdownButtonFormField<String>(
      value: _selectedDepartmentId,
      isExpanded: true,
      decoration: _inputDecoration(
        hintText: 'Select department',
        icon: Icons.account_tree_rounded,
      ),

      items: departments.map((department) {
        return DropdownMenuItem<String>(
          value: department.departmentId,
          child: Text(
            department.departmentName,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _selectedDepartmentId = value;
              });
            },

      validator: (value) {
        if (_selectedType == 2 && (value == null || value.isEmpty)) {
          return 'Select a department';
        }

        return null;
      },
    );
  }

  // ================================================================
  // TRADE DROPDOWN
  // ================================================================

  Widget _tradeDropdown(List<AdminTradeModel> trades) {
    return DropdownButtonFormField<String>(
      value: _selectedTradeId,
      isExpanded: true,

      decoration: _inputDecoration(
        hintText: 'Select trade',
        icon: Icons.build_rounded,
      ),

      items: trades.map((trade) {
        return DropdownMenuItem<String>(
          value: trade.tradeId,
          child: Text(trade.tradeName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),

      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _selectedTradeId = value;
              });
            },

      validator: (value) {
        if (_selectedType == 3 && (value == null || value.isEmpty)) {
          return 'Select a trade';
        }

        return null;
      },
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,

      prefixIcon: Icon(icon, color: primary),

      filled: true,
      fillColor: Colors.white,

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
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // ================================================================
  // LOADING DROPDOWN
  // ================================================================

  Widget _loadingDropdown() {
    return Container(
      height: 56,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,

          child: CircularProgressIndicator(strokeWidth: 2, color: primary),
        ),
      ),
    );
  }

  // ================================================================
  // DROPDOWN ERROR
  // ================================================================

  Widget _dropdownError(String message) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.05),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.red.withOpacity(.15)),
      ),

      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 19),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
