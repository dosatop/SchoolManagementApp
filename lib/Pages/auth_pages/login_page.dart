import 'package:app/Components/Buttons/back_button.dart';
import 'package:app/Components/Dividers/horizontal_divider.dart';
import 'package:app/Components/TextFields/custom_textfield.dart';
import 'package:app/Components/Tiles/auth_tile.dart';
import 'package:app/Dtos/auth_dtos/login_request.dart';
import 'package:app/Providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final bool isLogin = true; // Change this to false to show the register page
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Login"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: WaveClipperOne(),
                  child: Container(
                    height: 250,
                    color: const Color.fromARGB(255, 9, 25, 147),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 70, top: 70, right: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Log In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  "Experience a better learning environment",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          BackButtonFilled(),
                        ],
                      ),
                      Image.asset(
                        "lib/assets/svgs/exam.png",
                        height: 250,
                        width: 250,
                        fit: BoxFit.scaleDown,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                              activeColor: Color.fromARGB(255, 9, 25, 147),
                              shape: const CircleBorder(),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text(
                              "Remember me",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        TextButton(
                          onPressed: () {
                            // forgot password action
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: Color(0xFF091993),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      final success = await auth.login(
                                        LoginRequest(
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text,
                                        ),
                                      );

                                      if (!mounted) return;

                                      if (success) {
                                        Navigator.pushReplacementNamed(
                                          // ignore: use_build_context_synchronously
                                          context,
                                          '/dashboard',
                                        );
                                      } else {
                                        // ignore: use_build_context_synchronously
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Invalid email or password',
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
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 15),
                    HorizontalDivider(textString: "OR"),
                    const SizedBox(height: 15),
                    AuthTile(
                      authText: "Sign in with Google",
                      imageLink: "lib/assets/svgs/google.svg",
                    ),
                    const SizedBox(height: 12),
                    AuthTile(
                      authText: "Sign in with Apple",
                      imageLink: "lib/assets/svgs/apple.svg",
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 9, 25, 147),
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
  }
}
