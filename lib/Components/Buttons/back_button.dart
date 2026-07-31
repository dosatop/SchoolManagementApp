import 'package:flutter/material.dart';

class BackButtonFilled extends StatelessWidget {
  const BackButtonFilled({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: () {
        Navigator.of(context).pop();
      },
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF091993),
      ),
      icon: Icon(Icons.arrow_back),
    );
  }
}
