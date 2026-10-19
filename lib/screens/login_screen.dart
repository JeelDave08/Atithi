import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../auth/auth_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/atithi_text_field.dart';
import '../widgets/auth_components.dart';
import '../widgets/atithi_round_logo.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.authRepository = const UnconfiguredAuthRepository(),
    super.key,
  });

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isSubmitting = false;
  bool _googleSignInPending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    return null;
  }

  void _showFailure(AuthFailure failure) {
    showAuthMessage(context, authFailureMessage(failure));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      if (mounted) showAuthMessage(context, 'Signed in successfully.');
    } on AuthFailure catch (failure) {
      if (mounted) _showFailure(failure);
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
      await widget.authRepository.signInWithGoogle();
      if (mounted) {
        showAuthMessage(context, 'Signed in with Google successfully.');
      }
    } on AuthFailure catch (failure) {
      if (mounted) _showFailure(failure);
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
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: AtithiRoundLogo(size: 150)),
          const SizedBox(height: 38),
          const AuthHeading(
            title: 'Welcome Back',
            subtitle: 'Sign in to continue your stay journey.',
          ),
          const SizedBox(height: 27),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                AtithiTextField(
                  hint: 'Email Address',
                  controller: _emailController,
                  validator: validateEmailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AtithiTextField(
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
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.navy,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Remember me',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ForgotPasswordScreen(
                      authRepository: widget.authRepository,
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1B2A4A),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2A4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AuthPrimaryButton(
            label: 'Sign In',
            onPressed: _isSubmitting ? null : _submit,
            isLoading: _isSubmitting,
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_googleSignInPending)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    SvgPicture.asset(
                      'assets/images/google_g.svg',
                      width: 21,
                      height: 21,
                      semanticsLabel: 'Google logo',
                    ),
                  const SizedBox(width: 11),
                  Text(
                    _googleSignInPending
                        ? 'Connecting to Google…'
                        : 'Continue with Google',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 23),
          Center(
            child: AuthFooterLink(
              prompt: "Don't have an account?",
              label: 'Create Account',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RegisterScreen(authRepository: widget.authRepository),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
