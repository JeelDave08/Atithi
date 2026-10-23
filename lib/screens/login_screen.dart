import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository.dart';
import '../providers/pending_booking_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_components.dart';
import '../widgets/app_text_field.dart';
import '../widgets/atithi_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.authRepository = const AuthService(), super.key});
  final AuthRepository authRepository;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _googleSignInPending = false;

  void _continueAfterLogin() {
    final pending = ProviderScope.containerOf(context)
        .read(pendingBookingProvider);
    context.go(pending == null ? '/home' : '/booking');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    if (value.length < 6) return 'Use at least 6 characters.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: true,
      );
      if (mounted) _continueAfterLogin();
    } on AuthFailure catch (failure) {
      if (mounted) showAuthMessage(context, authFailureMessage(failure));
    } catch (_) {
      if (mounted) {
        showAuthMessage(context, 'Unable to sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _googleSignInPending = true;
    });
    try {
      final result = await widget.authRepository.signInWithGoogle();
      if (!mounted) return;
      switch (result.status) {
        case GoogleSignInStatus.success:
          _continueAfterLogin();
        case GoogleSignInStatus.cancelled:
          showAuthMessage(context, 'Google sign-in was cancelled.');
        case GoogleSignInStatus.error:
          showAuthMessage(
            context,
            result.message ?? 'Google sign-in failed. Please try again.',
          );
      }
    } on AuthFailure catch (failure) {
      if (mounted) showAuthMessage(context, authFailureMessage(failure));
    } catch (error, stackTrace) {
      debugPrint(
        'Unexpected Google sign-in handler error: $error\n$stackTrace',
      );
      if (mounted) showAuthMessage(context, error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _googleSignInPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: AtithiLogo()),
        const SizedBox(height: 24),
        const AuthHeading(
          title: 'Welcome back',
          subtitle: 'Sign in to continue your stay journey.',
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              AppTextField(
                hint: 'Email address',
                controller: _emailController,
                validator: validateEmailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                hint: 'Password',
                controller: _passwordController,
                validator: _validatePassword,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isSubmitting
                ? null
                : () => context.push('/forgot-password'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AuthPrimaryButton(
          label: 'Sign In',
          onPressed: _isSubmitting ? null : _submit,
          isLoading: _isSubmitting && !_googleSignInPending,
        ),
        const SizedBox(height: 23),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _signInWithGoogle,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cream,
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_googleSignInPending)
                  const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  )
                else
                  SvgPicture.asset(
                    'assets/images/google_g.svg',
                    width: 21,
                    height: 21,
                    semanticsLabel: 'Google logo',
                  ),
                const SizedBox(width: 10),
                Text(
                  _googleSignInPending
                      ? 'Connecting to Google…'
                      : 'Continue with Google',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: AuthFooterLink(
            prompt: "Don't have an account?",
            label: 'Create Account',
            onPressed: _isSubmitting ? null : () => context.push('/register'),
          ),
        ),
      ],
    ),
  );
}
