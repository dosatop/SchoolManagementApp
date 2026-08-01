import 'package:app/Providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BackButtonFilled extends StatelessWidget {
  const BackButtonFilled({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return IconButton.filled(
          onPressed: auth.isLoading ? null : () => Navigator.of(context).pop(),

          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF091993),
          ),
          icon: Icon(Icons.arrow_back),
        );
      },
    );
  }
}
