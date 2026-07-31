import 'package:flutter/material.dart';

class CustomTextfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData iconType;
  final String textFieldName;
  final bool obscureText;
  final TextInputType textInputType;
  final String? Function(String?)? validator;

  const CustomTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.iconType,
    required this.textFieldName,
    required this.textInputType,
    this.validator, required this.obscureText,
  });

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.textFieldName),
        const SizedBox(height: 5),
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? const Color(0xFF091993)
                  : Colors.grey,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  widget.iconType,
                  color: _focusNode.hasFocus
                      ? const Color(0xFF091993)
                      : Colors.grey,
                ),
              ),

              const SizedBox(height: 30, child: VerticalDivider()),

              Expanded(
                child: TextFormField(
                  obscureText: widget.obscureText,
                  focusNode: _focusNode,
                  controller: widget.controller,
                  validator: widget.validator,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                  ),
                  keyboardType: widget.textInputType,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
