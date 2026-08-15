import 'package:app/features/admin/models/subjects/admin_create_subject_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCreateSubjectPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateSubjectPage({
    super.key,
    required this.schoolId,
  });

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

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final data = AdminCreateSubjectModel(
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
    );

    final subject = await ref
        .read(adminDashboardProvider.notifier)
        .createSubject(
          schoolId: widget.schoolId,
          data: data,
        );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create subject'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textDark,
          ),
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
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
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
            padding: const EdgeInsets.fromLTRB(
              20,
              25,
              20,
              35,
            ),

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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                            'Enter the subject name and code below.',
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

                textCapitalization:
                    TextCapitalization.words,

                enabled: !_isLoading,

                decoration: InputDecoration(
                  hintText: 'e.g. Mathematics',
                  prefixIcon: const Icon(
                    Icons.menu_book_outlined,
                    color: primary,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: primary,
                      width: 1.5,
                    ),
                  ),

                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
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

                textCapitalization:
                    TextCapitalization.characters,

                enabled: !_isLoading,

                decoration: InputDecoration(
                  hintText: 'e.g. MAT',
                  prefixIcon: const Icon(
                    Icons.code_rounded,
                    color: primary,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: primary,
                      width: 1.5,
                    ),
                  ),

                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),

              const SizedBox(height: 35),

              // ==========================================================
              // CREATE BUTTON
              // ==========================================================

              SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _createSubject,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,

                    disabledBackgroundColor:
                        primary.withOpacity(.5),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
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
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 21,
                            ),
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
}