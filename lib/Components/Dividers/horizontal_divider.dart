import 'package:flutter/material.dart';

class HorizontalDivider extends StatelessWidget {
  final String textString;

  const HorizontalDivider({super.key, required this.textString});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 1, color: Color.fromARGB(255, 0, 0, 0)),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            textString,
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),

        const Expanded(
          child: Divider(thickness: 1, color: Color.fromARGB(255, 0, 2, 12)),
        ),
      ],
    );
  }
}
