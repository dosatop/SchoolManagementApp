import 'package:app/Components/Buttons/back_button.dart';
import 'package:app/Components/TextFields/custom_textfield.dart';
import 'package:app/Dtos/auth_dtos/login_request.dart';
import 'package:app/Dtos/auth_dtos/sign_up_request.dart';
import 'package:app/Providers/auth_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

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

  bool _termsAndCondtion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
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
                                "Sign Up",
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
                      // Image.asset(
                      //   "lib/assets/svgs/sign_up.png",
                      //   // color: Colors.blue,
                      //   height: 250,
                      //   width: 250,
                      //   fit: BoxFit.scaleDown,
                      // ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Form(
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
                        SizedBox(height: 8),
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
                        SizedBox(height: 8),
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
                        SizedBox(height: 8),
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
                        SizedBox(height: 8),
                        CustomTextfield(
                          controller: _confirmPasswordController,
                          hintText: "Retype Password",
                          iconType: Icons.lock_outline,
                          textFieldName: "Confirm Password",
                          textInputType: TextInputType.visiblePassword,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Re-enter your password to confirm";
                            }

                            if (value != _passwordController.text) {
                              return "Passwords do not match";
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _termsAndCondtion,
                                  onChanged: (value) {
                                    setState(() {
                                      _termsAndCondtion = value!;
                                    });
                                  },
                                  activeColor: Color.fromARGB(255, 9, 25, 147),
                                  shape: const CircleBorder(),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),

                                SizedBox(
                                  width: 250,
                                  child: RichText(
                                    textAlign: TextAlign.start,
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
                                            ..onTap = () {
                                              // Navigate to Terms of Service page
                                            },
                                        ),
                                        const TextSpan(text: " & "),
                                        TextSpan(
                                          text: "Privacy Policy",
                                          style: const TextStyle(
                                            color: Color(0xFF091993),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              // Navigate to Privacy Policy page
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                                          if (!_formKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          final success = await auth.signUp(
                                            SignUpRequest(
                                              fullName: _fullNameController.text
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
                                                  'Error in signing up user',
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
                                          "Get Set to Explore",
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already a Member ?",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, "/login"),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Login Now",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 9, 25, 147),
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
          ],
        ),
      ),
    );
  }
}
