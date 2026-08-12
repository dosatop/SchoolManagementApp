import 'package:app/features/auth/presentation/sign_up_page.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class LoginOrSignUp extends StatefulWidget {
  final bool isLogin;

  const LoginOrSignUp({super.key, this.isLogin = true});

  @override
  State<LoginOrSignUp> createState() => _LoginOrSignUpState();
}

class _LoginOrSignUpState extends State<LoginOrSignUp> {
  late bool isLogin;
  // Change this to false to show the register page
  
  @override
  void initState() {
    super.initState();
    isLogin = widget.isLogin;
  }

  void togglePage() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLogin
        ? LoginPage(onTogglePage: togglePage)
        : SignUpPage(onTogglePage: togglePage);
  }
}
