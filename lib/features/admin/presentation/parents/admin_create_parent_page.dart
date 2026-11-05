import 'package:app/features/admin/models/parents/admin_create_parent_request_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCreateParentPage extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminCreateParentPage({super.key, required this.schoolId});

  @override
  ConsumerState<AdminCreateParentPage> createState() =>
      _AdminCreateParentPageState();
}

class _AdminCreateParentPageState extends ConsumerState<AdminCreateParentPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ================================================================
  // CREATE PARENT
  // ================================================================

  Future<void> _createParent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final request = AdminCreateParentRequestModel(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    dynamic parent;
    String? errorMessage;

    try {
      parent = await ref
          .read(adminDashboardProvider.notifier)
          .createParent(request: request);
    } catch (error) {
      parent = null;
      errorMessage = error.toString().replaceFirst('Exception: ', '').trim();
    }

    if (!mounted) return;

    if (parent == null) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (errorMessage == null || errorMessage.isEmpty)
                ? 'Unable to create parent. Please try again.'
                : errorMessage,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Refresh the dashboard so the new parent shows in the list.
    try {
      await ref.read(adminDashboardProvider.notifier).refresh();
    } catch (_) {}

    if (!mounted) return;

    setState(() => _isLoading = false);

    final name = _fullNameController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name was added. Link their children from the parent page.'),
        backgroundColor: Colors.green,
      ),
    );

    context.pop();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          onPressed: _isLoading ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),

        title: const Text(
          'Create Parent',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

            padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),

            children: [
              _header(),

              const SizedBox(height: 25),

              _label('Full Name'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _fullNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,

                textInputAction: TextInputAction.next,

                decoration: _inputDecoration(
                  hintText: 'Enter full name',
                  icon: Icons.person_outline_rounded,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }

                  if (value.trim().length < 2) {
                    return 'Please enter a valid name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _label('Phone Number'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _phoneController,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,

                textInputAction: TextInputAction.next,

                decoration: _inputDecoration(
                  hintText: 'Enter phone number',
                  icon: Icons.phone_outlined,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }

                  if (value.trim().length < 7) {
                    return 'Please enter a valid phone number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _label('Email Address'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,

                keyboardType: TextInputType.emailAddress,

                textInputAction: TextInputAction.next,

                autocorrect: false,

                decoration: _inputDecoration(
                  hintText: 'Enter email address',
                  icon: Icons.email_outlined,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }

                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _label('Login password'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,

                textInputAction: TextInputAction.done,

                decoration: _inputDecoration(
                  hintText: 'Enter password',
                  icon: Icons.lock_outline_rounded,
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }

                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }

                  return null;
                },

                onFieldSubmitted: (_) {
                  if (!_isLoading) {
                    _createParent();
                  }
                },
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Share this password with the parent. They sign in '
                      'with their email and this password.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 54,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createParent,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,

                    disabledBackgroundColor: primary.withValues(alpha: 0.5),

                    disabledForegroundColor: Colors.white70,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                            Icon(Icons.person_add_alt_1_rounded, size: 20),

                            SizedBox(width: 9),

                            Text(
                              'Create Parent',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
    ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2B3FD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a new parent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Create their login. You can link their children '
                  'after the account is created.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
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
  // LABEL
  // ================================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: textDark,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,

      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),

      prefixIcon: Icon(icon, color: primary, size: 20),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.white,

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