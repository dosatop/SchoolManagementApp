import 'package:app/features/Subjects/models/create_subject_request.dart';
import 'package:app/features/Subjects/provider/subjects_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateSubjectPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String schoolName;

  const CreateSubjectPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  ConsumerState<CreateSubjectPage> createState() => _CreateSubjectPageState();
}

class _CreateSubjectPageState extends ConsumerState<CreateSubjectPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ===============================================================
  // CREATE SUBJECT
  // ===============================================================

  Future<void> _createSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isCreating = true;
    });

    final request = CreateSubjectRequest(
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
    );

    final error = await ref
        .read(subjectsProvider(widget.schoolId).notifier)
        .createSubject(request);

    if (!mounted) return;

    setState(() {
      _isCreating = false;
    });

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject created successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // =============================================================
      // APP BAR
      // =============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Subject',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              widget.schoolName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),

      // =============================================================
      // BODY
      // =============================================================
      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),

            children: [
              // =====================================================
              // HEADER
              // =====================================================
              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, Color(0xFF2638C4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(22),

                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(.16),
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
                        color: Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'New Subject',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Add a subject to ${widget.schoolName}.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // =====================================================
              // SECTION TITLE
              // =====================================================
              const Text(
                'Subject Information',
                style: TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Enter the subject details.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              const SizedBox(height: 20),

              // =====================================================
              // SUBJECT NAME
              // =====================================================
              _label('Subject Name'),

              const SizedBox(height: 8),

              _field(
                controller: _nameController,
                hint: 'e.g. Mathematics',
                icon: Icons.menu_book_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject name is required.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 17),

              // =====================================================
              // SUBJECT CODE
              // =====================================================
              _label('Subject Code'),

              const SizedBox(height: 8),

              _field(
                controller: _codeController,
                hint: 'e.g. MATH101',
                icon: Icons.tag_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject code is required.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // =====================================================
              // CREATE BUTTON
              // =====================================================
              SizedBox(
                height: 54,
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createSubject,

                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline_rounded),

                  label: Text(
                    _isCreating ? 'Creating...' : 'Create Subject',

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withOpacity(.6),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =====================================================
              // CANCEL BUTTON
              // =====================================================
              SizedBox(
                height: 50,
                width: double.infinity,

                child: OutlinedButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: BorderSide(color: Colors.grey.shade300),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // LABEL
  // ===============================================================

  Widget _label(String text) {
    return Text(
      text,

      style: const TextStyle(
        color: textDark,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ===============================================================
  // FIELD
  // ===============================================================

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),

        prefixIcon: Icon(icon, color: Colors.grey.shade600),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
