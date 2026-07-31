import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AuthTile extends StatelessWidget {
  final String authText;
  final String imageLink;

  const AuthTile({super.key, required this.authText, required this.imageLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromARGB(255, 29, 46, 173)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            authText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          SvgPicture.asset(imageLink, height: 24, width: 24),
        ],
      ),
    );
  }
}
