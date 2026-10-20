import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class AuthField extends StatefulWidget {
  const AuthField({
    required this.hint,
    required this.controller,
    this.validator,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
    this.onFieldSubmitted,
    super.key,
  });

  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    validator: widget.validator,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    obscureText: _hidden,
    maxLines: 1,
    textAlignVertical: TextAlignVertical.center,
    inputFormatters: [
      ...?widget.inputFormatters,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(widget.maxLength),
    ],
    onChanged: widget.onChanged,
    onFieldSubmitted: widget.onFieldSubmitted,
    autocorrect: !widget.obscureText,
    enableSuggestions: !widget.obscureText,
    style: const TextStyle(color: AppColors.navy, fontSize: 16, height: 1.2),
    cursorColor: AppColors.navy,
    decoration: InputDecoration(
      hintText: widget.hint,
      hintStyle: const TextStyle(color: Color(0xFF758198), fontSize: 16),
      filled: true,
      fillColor: AppColors.cream,
      constraints: const BoxConstraints(minHeight: 56),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      prefixIcon: widget.prefixIcon == null
          ? null
          : Icon(
              widget.prefixIcon,
              color: AppColors.navy.withValues(alpha: .62),
              size: 20,
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 56),
      suffixIcon: widget.obscureText
          ? IconButton(
              tooltip: _hidden ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.navy.withValues(alpha: .62),
              ),
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 56),
      counterText: '',
      errorStyle: const TextStyle(
        color: Color(0xFFFF8C8C),
        fontSize: 11,
        height: 1.2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE87979)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE87979)),
      ),
    ),
  );
}
