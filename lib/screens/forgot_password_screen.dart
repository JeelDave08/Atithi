import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../widgets/atithi_logo.dart';
import '../widgets/auth_components.dart';
import '../widgets/auth_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    this.authRepository = const AuthService(),
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
        _emailController.text.trim(),
      );
      if (mounted)
        showAuthMessage(
          context,
          'If an account exists for this email, password reset instructions have been sent.',
        );
    } on AuthFailure catch (failure) {
      if (mounted) showAuthMessage(context, authFailureMessage(failure));
    } catch (_) {
      if (mounted)
        showAuthMessage(
          context,
          'Unable to send the reset link. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back to sign in',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFFAF5EB),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: AtithiLogo()),
        const SizedBox(height: 24),
        const AuthHeading(
          title: 'Forgot password?',
          subtitle: 'Enter your email and we’ll send you a secure reset link.',
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: AuthField(
            hint: 'Email address',
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
          label: 'Send reset link',
          onPressed: _isSubmitting ? null : _submit,
          isLoading: _isSubmitting,
        ),
      ],
    ),
  );
}
