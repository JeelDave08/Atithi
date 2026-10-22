import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured = widget.obscureText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    validator: widget.validator,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    obscureText: _isObscured,
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
    style: const TextStyle(
      color: Color(0xFF0B2347),
      fontSize: 16,
      height: 1.2,
    ),
    cursorColor: const Color(0xFF0B2347),
    decoration: InputDecoration(
      hintText: widget.hint,
      hintMaxLines: 1,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFFAF5EA),
      isDense: false,
      constraints: const BoxConstraints(minHeight: 56),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      errorMaxLines: 2,
      prefixIcon: widget.prefixIcon == null
          ? null
          : Icon(
              widget.prefixIcon,
              color: const Color(0xFF0B2347).withValues(alpha: .62),
              size: 20,
            ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      suffixIcon: widget.obscureText
          ? IconButton(
              tooltip: _isObscured ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _isObscured = !_isObscured),
              icon: Icon(
                _isObscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF0B2347).withValues(alpha: .62),
              ),
            )
          : null,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      counterText: '',
      errorStyle: const TextStyle(
        color: Color(0xFFFF8A8A),
        fontSize: 12,
        height: 1.2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFDFB96F), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFFF8A8A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFFF8A8A)),
      ),
    ),
  );
}
