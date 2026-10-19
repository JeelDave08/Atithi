import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AtithiTextField extends StatefulWidget {
  const AtithiTextField({
    required this.hint,
    required this.controller,
    required this.validator,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.onChanged,
    super.key,
  });

  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<AtithiTextField> createState() => _AtithiTextFieldState();
}

class _AtithiTextFieldState extends State<AtithiTextField> {
  late bool _isObscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _isObscured,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      autocorrect: !widget.obscureText,
      enableSuggestions: !widget.obscureText,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, color: AppColors.muted, size: 21),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _isObscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _isObscured = !_isObscured),
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                ),
              )
            : null,
      ),
    );
  }
}
