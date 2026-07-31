import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class LoginOrRegisterPage extends StatelessWidget {
  const LoginOrRegisterPage({super.key});
  final bool isLogin = true; // Change this to false to show the register page

  @override
  Widget build(BuildContext context) {
    if (isLogin) {
      return const LoginPage();
    } else {
      return const RegisterPage();
    }
  }
}

