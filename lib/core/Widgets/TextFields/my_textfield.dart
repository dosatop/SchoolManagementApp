import 'package:flutter/material.dart';

class MyTextfield extends StatefulWidget {
  final String hintText;
  final bool? obscureText;
  final String? labelText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;

  const MyTextfield({
    super.key,
    required this.hintText,
    this.obscureText,
    required this.controller,
    required this.keyboardType,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.labelText,
  });

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: widget.obscureText ?? false,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        border: InputBorder.none,

        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        // enabledBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(12),
        //   borderSide: const BorderSide(color: Colors.grey, width: 1),
        // ),
        // focusedBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(12),
        //   borderSide: const BorderSide(color: Colors.blue, width: 2),
        // ),
      ),
      onChanged: widget.onChanged,
    );
  }
}
