import 'package:app/core/Widgets/Buttons/back_button.dart';
import 'package:app/core/Widgets/Dividers/horizontal_divider.dart';
import 'package:app/core/Widgets/TextFields/custom_textfield.dart';
import 'package:app/core/Widgets/Tiles/auth_tile.dart';
import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  final Function()? onTogglePage;

  const LoginPage({super.key, this.onTogglePage});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final StorageService storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadLoginInfo();
  }

  Future<void> _loadLoginInfo() async {
    final loginInfo = await storageService.getLoginInfo();

    if (!mounted || loginInfo == null) {
      return;
    }

    setState(() {
      _rememberMe = loginInfo.rememberMe;
      if (_rememberMe) {
        _emailController.text = loginInfo.email;
        _passwordController.text = loginInfo.password;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final authState = ref.watch(authProvider);
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 9, 25, 147),
      resizeToAvoidBottomInset: true,
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipPath(
                            clipper: WaveClipperOne(),
                            child: Container(
                              height: keyboardOpen
                                  ? size.height * 0.15
                                  : size.height * 0.27,
                              color: const Color.fromARGB(255, 9, 25, 147),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(
                              left: size.width * 0.1,
                              top: size.height * 0.04,
                              right: size.width * 0.05,
                            ),

                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          "Log In",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size.width * 0.10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        SizedBox(
                                          width: size.width * 0.6,

                                          child: Text(
                                            "Experience a better learning environment",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: size.width * 0.038,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    BackButtonFilled(),
                                  ],
                                ),

                                SizedBox(
                                  height: keyboardOpen
                                      ? size.height * 0.05
                                      : size.height * 0.08,
                                ),

                                if (!keyboardOpen)
                                  Image.asset(
                                    "assets/svgs/exam.png",
                                    height: size.height * 0.18,
                                    width: size.width * 0.45,
                                    fit: BoxFit.contain,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // FORM
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.08,
                        ),

                        child: Form(
                          key: _formKey,

                          child: Column(
                            children: [
                              CustomTextfield(
                                hintText: "Email",
                                controller: _emailController,
                                iconType: Icons.email_outlined,
                                textFieldName: 'Email address',
                                textInputType: TextInputType.emailAddress,

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Email is required";
                                  }

                                  if (!value.contains("@")) {
                                    return "Enter a valid email";
                                  }

                                  return null;
                                },

                                obscureText: false,
                              ),

                              const SizedBox(height: 8),

                              CustomTextfield(
                                hintText: "Password",
                                obscureText: true,

                                controller: _passwordController,

                                iconType: Icons.lock_clock_outlined,

                                textFieldName: 'Password',

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Password is required";
                                  }

                                  if (value.length < 6) {
                                    return "Must be at least 6 characters";
                                  }

                                  return null;
                                },

                                textInputType: TextInputType.visiblePassword,
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) async {
                                          final onChangedValue = value ?? false;

                                          setState(() {
                                            _rememberMe = onChangedValue;
                                          });

                                          // await storageService.saveLoginInfo(
                                          //   _emailController.text,
                                          //   onChangedValue,
                                          // );
                                        },

                                        activeColor: const Color.fromARGB(
                                          255,
                                          9,
                                          25,
                                          147,
                                        ),

                                        shape: const CircleBorder(),

                                        visualDensity: VisualDensity.compact,
                                      ),

                                      const Text(
                                        "Remember me",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),

                                  TextButton(
                                    onPressed: () {},

                                    child: const Text(
                                      "Forgot password?",
                                      style: TextStyle(
                                        color: Color(0xFF091993),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,

                                height: 50,

                                child: ElevatedButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!
                                              .validate()) {
                                            return;
                                          }

                                          final request = LoginRequest(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text
                                                .trim(),
                                          );

                                          if (!mounted) return;

                                          final error = await ref
                                              .read(authProvider.notifier)
                                              .login(request);

                                          if (!mounted) return;

                                          if (error == null) {
                                            if (_rememberMe) {
                                              await storageService
                                                  .saveLoginInfo(
                                                    _emailController.text,
                                                    _passwordController.text,
                                                    true,
                                                  );
                                            } else {
                                              await storageService
                                                  .clearLoginInfo();
                                            }

                                            if (!context.mounted) return;

                                            final auth = ref
                                                .read(authProvider)
                                                .value;

                                            if (!context.mounted) return;

                                            if (auth?.role == 'SuperAdmin') {
                                              context.go('/super-admin');
                                            } else if (auth?.role == 'Admin') {
                                              context.go('/dashboard');
                                            } else {
                                              context.go('/dashboard');
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Error: ${authState.error}",
                                                ),
                                              ),
                                            );
                                          }
                                        },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      9,
                                      25,
                                      147,
                                    ),

                                    foregroundColor: Colors.white,
                                  ),

                                  child: isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Color.fromARGB(
                                              255,
                                              9,
                                              25,
                                              147,
                                            ),
                                            strokeWidth:
                                                2, // Optional: makes the ring thinner
                                          ),
                                        )
                                      : const Text("Login"),
                                ),
                              ),

                              const SizedBox(height: 15),

                              HorizontalDivider(textString: "OR"),

                              const SizedBox(height: 15),

                              AuthTile(
                                authText: "Sign in with Google",
                                imageLink: "assets/svgs/google.svg",
                              ),

                              const SizedBox(height: 12),

                              AuthTile(
                                authText: "Sign in with Apple",
                                imageLink: "assets/svgs/apple.svg",
                              ),

                              const SizedBox(height: 15),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  const Text("Don't have an account?"),

                                  TextButton(
                                    onPressed: widget.onTogglePage,

                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.only(
                                        left: size.width * 0.01,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),

                                    child: const Text(
                                      "Sign up",
                                      style: TextStyle(
                                        color: Color(0xFF091993),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
