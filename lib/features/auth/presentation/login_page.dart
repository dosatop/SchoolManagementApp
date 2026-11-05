import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================================================================
// LOGIN
// ==================================================================

// Accounts are created by the school (admin), not by users, so there
// is no sign-up option here.

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const Color _primary = Color(0xFF091993);
  static const Color _primaryDark = Color(0xFF050F5E);
  static const Color _textDark = Color(0xFF20232E);
  static const Color _field = Color(0xFFF4F5FA);

  final StorageService _storage = StorageService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _showPassword = false;
  bool _submitting = false;

  /// For "press back twice to exit".
  static const Duration _exitWindow = Duration(seconds: 2);
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _loadLoginInfo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadLoginInfo() async {
    final info = await _storage.getLoginInfo();
    if (!mounted || info == null) return;

    setState(() {
      _rememberMe = info.rememberMe;
      if (_rememberMe) {
        _emailController.text = info.email;
        _passwordController.text = info.password;
      }
    });
  }

  // ================================================================
  // LOGIN
  // ================================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final error = await ref
        .read(authProvider.notifier)
        .login(
          LoginRequest(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      _snack(_friendlyError(error), error: true);
      return;
    }

    if (_rememberMe) {
      await _storage.saveLoginInfo(
        _emailController.text.trim(),
        _passwordController.text,
        true,
      );
    } else {
      await _storage.clearLoginInfo();
    }

    if (!mounted) return;

    final auth = ref.read(authProvider).value;
    final role = auth?.role;
    final schoolId = auth?.user?.schoolId;

    switch (role) {
      case 'SuperAdmin':
        context.go('/super-admin');
      case 'Admin':
        if (schoolId == null || schoolId.isEmpty) {
          _snack(
            'This admin account is not linked to a school yet.',
            error: true,
          );
          return;
        }
        context.go('/admin-dashboard/$schoolId');
      case 'Teacher':
        context.go('/teacher/dashboard');
      case 'Parent':
        context.go('/parent/dashboard');
      case 'Student':
        context.go('/student/dashboard');
      default:
        _snack('Unknown account role: ${role ?? 'none'}', error: true);
    }
  }

  String _friendlyError(String error) {
    final e = error.replaceFirst('Exception: ', '').trim();
    final lower = e.toLowerCase();

    if (lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('invalid')) {
      return 'Wrong email or password. Please try again.';
    }
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (lower.contains('timeout')) {
      return 'The server took too long to respond. Please try again.';
    }
    return e.isEmpty ? 'Something went wrong. Please try again.' : e;
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : _primary,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  // ================================================================
  // BACK: press twice to exit the app
  // ================================================================
  // There is nothing behind the login screen (onboarding and logout
  // both arrive here with go()), so Back never navigates — the first
  // press asks, a second press within 2 seconds closes the app.

  void _handleBack() {
    // First Back just closes the keyboard if it's open.
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      FocusScope.of(context).unfocus();
      return;
    }

    final now = DateTime.now();

    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) <= _exitWindow) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: _exitWindow,
          backgroundColor: _textDark,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Are you sure you want to exit? Press back again to close the app.',
                  style: GoogleFonts.exo(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final busy = _submitting || ref.watch(authProvider).isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              _header(keyboardOpen),
              Transform.translate(
                offset: const Offset(0, -36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _formCard(busy),
                ),
              ),
              _helpNote(),
              const SizedBox(height: 24),
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

  Widget _header(bool keyboardOpen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: keyboardOpen ? 190 : 300,
      child: Stack(
        children: [
          // Wave background
          ClipPath(
            clipper: WaveClipperOne(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Decorative circles
          Positioned(top: -40, right: -30, child: _bubble(150, .08)),
          Positioned(top: 70, right: 70, child: _bubble(36, .12)),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back 👋',
                                style: GoogleFonts.exo(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Log in',
                                style: GoogleFonts.exo(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pick up where you left off.',
                                style: GoogleFonts.exo(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: keyboardOpen
                              ? const SizedBox.shrink()
                              : Image.asset(
                                  'assets/svgs/exam.png',
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  // ================================================================
  // FORM CARD
  // ================================================================

  Widget _formCard(bool busy) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: .10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Email address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: _decoration(
                  hint: 'you@school.com',
                  icon: Icons.alternate_email_rounded,
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _label('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !busy,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => busy ? null : _login(),
                decoration: _decoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Password is required';
                  if (value.length < 6) return 'Must be at least 6 characters';
                  return null;
                },
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: busy
                        ? null
                        : () => setState(() => _rememberMe = !_rememberMe),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _rememberMe ? _primary : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _rememberMe
                                    ? _primary
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: _rememberMe
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: GoogleFonts.exo(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => _snack(
                            'Ask your school admin to reset your password.',
                          ),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.exo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ---------------- LOGIN BUTTON ----------------
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: busy
                        ? null
                        : const LinearGradient(
                            colors: [_primary, Color(0xFF2437C5)],
                          ),
                    color: busy ? Colors.grey.shade300 : null,
                    boxShadow: busy
                        ? null
                        : [
                            BoxShadow(
                              color: _primary.withValues(alpha: .3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: busy ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: _primary,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Log in',
                                style: GoogleFonts.exo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 19),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.exo(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _textDark,
    ),
  );

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.exo(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _field,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_primary, 1.5),
      errorBorder: border(Colors.red.shade300),
      focusedErrorBorder: border(Colors.red.shade400, 1.5),
    );
  }

  // ================================================================
  // HELP NOTE (no self sign-up)
  // ================================================================

  Widget _helpNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Don't have login details? Your school creates accounts for "
              'students, teachers and parents — contact your school admin.',
              style: GoogleFonts.exo(
                fontSize: 12.5,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}