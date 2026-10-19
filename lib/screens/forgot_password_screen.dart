import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../widgets/atithi_text_field.dart';
import '../widgets/auth_components.dart';
import '../widgets/atithi_round_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    this.authRepository = const UnconfiguredAuthRepository(),
    super.key,
  });

  final AuthRepository authRepository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.sendPasswordReset(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      showAuthMessage(
        context,
        'If an account exists for this email, password reset instructions have been sent.',
      );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      showAuthMessage(context, authFailureMessage(failure));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back to Login',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: AtithiRoundLogo(size: 150)),
          const SizedBox(height: 38),
          const AuthHeading(
            title: 'Reset Your Password',
            subtitle: 'Enter the email address linked to your account. We will use it to send password reset instructions once email authentication is connected.',
          ),
          const SizedBox(height: 27),
          Form(
            key: _formKey,
            child: AtithiTextField(
              hint: 'Email Address',
              controller: _emailController,
              validator: validateEmailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'Send Reset Link',
            onPressed: _isSubmitting ? null : _submit,
            isLoading: _isSubmitting,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Login'),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
