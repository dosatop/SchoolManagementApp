import 'package:app/features/admin/models/classes/admin_create_class_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminCreateClassPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateClassPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminCreateClassPage> createState() =>
      _AdminCreateClassPageState();
}

class _AdminCreateClassPageState extends ConsumerState<AdminCreateClassPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ================================================================
  // CREATE CLASS
  // ================================================================

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final schoolClass = await ref
        .read(adminDashboardProvider.notifier)
        .createClass(
          schoolId: widget.schoolId,
          data: AdminCreateClassModel(name: _nameController.text.trim()),
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (schoolClass != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create class'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

        titleSpacing: 20,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Class',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Create a new class in your school',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),

            children: [
              // ======================================================
              // HEADER ICON
              // ======================================================
              Center(
                child: Container(
                  width: 72,
                  height: 72,

                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(22),
                  ),

                  child: const Icon(
                    Icons.class_outlined,
                    color: primary,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Create a Class',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Enter the name of the class you want to add '
                'to your school.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // ======================================================
              // CLASS NAME
              // ======================================================
              const Text(
                'Class Name',
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

                decoration: InputDecoration(
                  hintText: 'e.g. JSS 1',

                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),

                  prefixIcon: const Icon(
                    Icons.class_outlined,
                    color: primary,
                    size: 21,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),

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

                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),

                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Please enter a class name';
                  }

                  if (name.length < 2) {
                    return 'Class name is too short';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ======================================================
              // INFO
              // ======================================================
              Container(
                padding: const EdgeInsets.all(13),

                decoration: BoxDecoration(
                  color: primaryLight,
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
                        'You can assign teachers and manage '
                        'students for this class after it has '
                        'been created.',
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

              const SizedBox(height: 30),

              // ======================================================
              // CREATE BUTTON
              // ======================================================
              SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createClass,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,

                    disabledBackgroundColor: primary.withOpacity(.5),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Icon(Icons.add_rounded, size: 20),

                            SizedBox(width: 8),

                            Text(
                              'Create Class',
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
