import 'package:app/Components/Buttons/back_button.dart';
import 'package:app/Components/TextFields/custom_textfield.dart';
import 'package:app/Dtos/auth_dtos/sign_up_request.dart';
import 'package:app/Providers/auth_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  final Function()? onTogglePage;

  const SignUpPage({super.key, this.onTogglePage});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _phoneNumberController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _termsAndCondition = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),

                child: Column(
                  children: [
                    // HEADER
                    Stack(
                      children: [
                        ClipPath(
                          clipper: WaveClipperOne(),

                          child: Container(
                            height: keyboardOpen
                                ? size.height * 0.12
                                : size.height * 0.25,

                            color: const Color.fromARGB(255, 9, 25, 147),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.only(
                            left: size.width * 0.1,

                            right: size.width * 0.05,

                            top: size.height * 0.04,
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
                                        "Sign Up",

                                        style: TextStyle(
                                          color: Colors.white,

                                          fontSize: size.width * 0.10,

                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      SizedBox(
                                        width: size.width * 0.5,

                                        child: keyboardOpen
                                            ? null
                                            : Text(
                                                "Register to Start Your Exciting Learning Process",
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

                              if (!keyboardOpen)
                                SizedBox(height: size.height * 0.04),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // FORM AREA
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.08,
                      ),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          children: [
                            CustomTextfield(
                              controller: _fullNameController,
                              hintText: "Full Name",
                              iconType: Icons.person_outline,
                              textFieldName: "Full Name",
                              textInputType: TextInputType.text,
                              obscureText: false,

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Full Name is required";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            CustomTextfield(
                              controller: _emailController,
                              hintText: "Email Address",
                              iconType: Icons.email_outlined,
                              textFieldName: "Email Address",
                              textInputType: TextInputType.emailAddress,
                              obscureText: false,

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email address is required";
                                }

                                if (!value.contains('@')) {
                                  return "Enter a valid email";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            CustomTextfield(
                              controller: _phoneNumberController,
                              hintText: "Phone Number",
                              iconType: Icons.call_outlined,
                              textFieldName: "Phone number",
                              textInputType: TextInputType.number,
                              obscureText: false,

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Phone number is required";
                                }

                                if (value.length < 11) {
                                  return "Must be at least 11 characters";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            CustomTextfield(
                              controller: _passwordController,
                              hintText: "Enter a Password",
                              iconType: Icons.lock_outline,
                              textFieldName: "Create a Password",
                              textInputType: TextInputType.visiblePassword,
                              obscureText: true,

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Password is required";
                                }

                                if (value.length < 6) {
                                  return "Must be at least 6 characters";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            CustomTextfield(
                              controller: _confirmPasswordController,
                              hintText: "Retype Password",
                              iconType: Icons.lock_outline,
                              textFieldName: "Confirm Password",
                              textInputType: TextInputType.visiblePassword,
                              obscureText: true,

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Re-enter your password";
                                }

                                if (value != _passwordController.text) {
                                  return "Passwords do not match";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Checkbox(
                                  value: _termsAndCondition,

                                  onChanged: (value) {
                                    setState(() {
                                      _termsAndCondition = value ?? false;
                                    });
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

                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.black,

                                        fontSize: 12,
                                      ),

                                      children: [
                                        const TextSpan(
                                          text: "By signing up you accept our ",
                                        ),

                                        TextSpan(
                                          text: "Terms of Service",

                                          style: const TextStyle(
                                            color: Color(0xFF091993),

                                            fontWeight: FontWeight.w600,
                                          ),

                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {},
                                        ),

                                        const TextSpan(text: " & "),

                                        TextSpan(
                                          text: "Privacy Policy",

                                          style: const TextStyle(
                                            color: Color(0xFF091993),

                                            fontWeight: FontWeight.w600,
                                          ),

                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,

                              height:
                                  MediaQuery.of(context).size.height * 0.065,

                              child: Consumer<AuthProvider>(
                                builder: (context, auth, child) {
                                  return ElevatedButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () async {
                                            if (!_formKey.currentState!
                                                .validate()) {
                                              return;
                                            }

                                            final success = await auth.signUp(
                                              SignUpRequest(
                                                fullName: _fullNameController
                                                    .text
                                                    .trim(),

                                                email: _emailController.text
                                                    .trim(),

                                                password:
                                                    _passwordController.text,

                                                phoneNumber:
                                                    _phoneNumberController.text,
                                              ),
                                            );

                                            if (!mounted) return;

                                            if (success) {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                '/dashboard',
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Error in signing up user",
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
                                        : const Text(
                                            "Get Set to Explore",

                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,

                                              fontSize: 16,
                                            ),
                                          ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,

                              child: OutlinedButton(
                                onPressed: widget.onTogglePage,

                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    const Text(
                                      "Already a Member ?",
                                      style: TextStyle(fontSize: 16),
                                    ),

                                    const SizedBox(width: 4),

                                    TextButton(
                                      onPressed: widget.onTogglePage,

                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),

                                      child: const Text(
                                        "Login Now",

                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF091993),
                                        ),
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
