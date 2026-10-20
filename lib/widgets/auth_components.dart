import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_repository.dart';
import '../theme/app_colors.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 24,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 31,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          height: 1.15,
          color: AppColors.cream,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    ],
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
        disabledBackgroundColor: AppColors.gold.withValues(alpha: .45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.navy,
              ),
            )
          : Text(label),
    ),
  );
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.prompt,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String prompt;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        prompt,
        style: const TextStyle(color: AppColors.muted, fontSize: 14),
      ),
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    ],
  );
}

void showAuthMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF142F58),
      ),
    );
}

String? validateEmailAddress(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Please enter your email address.';
  final emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  if (!emailPattern.hasMatch(email))
    return 'Please enter a valid email address.';
  return null;
}

String authFailureMessage(AuthFailure failure) => switch (failure.code) {
  AuthFailureCode.invalidCredentials => 'Email or password is incorrect.',
  AuthFailureCode.emailAlreadyInUse =>
    'This email is already registered. Try signing in instead.',
  AuthFailureCode.cancelled => 'Google sign-in was cancelled.',
  AuthFailureCode.network =>
    'Unable to connect. Check your connection and try again.',
  AuthFailureCode.unknown => failure.message,
};
