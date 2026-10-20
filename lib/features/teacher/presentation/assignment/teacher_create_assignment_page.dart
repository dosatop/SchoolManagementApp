import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherCreateAssignmentPage extends ConsumerStatefulWidget {
  final String classId;
  final String subjectId;
  final String subjectName;
  final String className;

  const TeacherCreateAssignmentPage({
    super.key,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.className,
  });

  @override
  ConsumerState<TeacherCreateAssignmentPage> createState() =>
      _TeacherCreateAssignmentPageState();
}

class _TeacherCreateAssignmentPageState
    extends ConsumerState<TeacherCreateAssignmentPage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _attachmentController = TextEditingController();

  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _dueDate = pickedDate;
    });
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dueDate == null) {
      _showMessage('Please select a due date.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ref
          .read(teachersProvider.notifier)
          .createAssignment(
            classId: widget.classId,
            subjectId: widget.subjectId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            attachmentUrl: _attachmentController.text.trim().isEmpty
                ? null
                : _attachmentController.text.trim(),
            dueDate: _dueDate!.toIso8601String(),
          );

      if (!mounted) return;

      if (success) {
        _showMessage('Assignment created successfully.', success: true);

        context.pop();
      } else {
        final error = ref.read(teachersProvider).error;

        _showMessage(error?.toString() ?? 'Unable to create assignment.');
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to create assignment. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),
        title: const Text(
          'Create Assignment',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
          children: [
            // ========================================================
            // CLASS / SUBJECT
            // ========================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: primary),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subjectName,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.className,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Assignment Details',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // ========================================================
            // TITLE
            // ========================================================
            _label('Assignment Title'),

            const SizedBox(height: 7),

            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                hint: 'e.g. Introduction to Livestock Farming',
                icon: Icons.title_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an assignment title';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            // ========================================================
            // DESCRIPTION
            // ========================================================
            _label('Description'),

            const SizedBox(height: 7),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: _inputDecoration(
                hint: 'Enter assignment instructions...',
                icon: Icons.description_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            // ========================================================
            // ATTACHMENT
            // ========================================================
            _label('Attachment URL'),

            const SizedBox(height: 7),

            TextFormField(
              controller: _attachmentController,
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(
                hint: 'https://example.com/file.pdf',
                icon: Icons.attach_file_rounded,
              ),
            ),

            const SizedBox(height: 18),

            // ========================================================
            // DUE DATE
            // ========================================================
            _label('Due Date'),

            const SizedBox(height: 7),

            InkWell(
              onTap: _isSubmitting ? null : _selectDueDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: primary,
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Select due date'
                            : _formatDate(_dueDate!),
                        style: TextStyle(
                          color: _dueDate == null
                              ? Colors.grey.shade500
                              : textDark,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ========================================================
            // CREATE BUTTON
            // ========================================================
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _createAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primary.withOpacity(.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Assignment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: textDark,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      prefixIcon: Icon(icon, color: primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
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
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
