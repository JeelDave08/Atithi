import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

export '../data/countries.dart' show CountryDialCode;

import '../auth/auth_repository.dart';
import '../data/countries.dart';
import '../widgets/atithi_logo.dart';
import '../widgets/auth_components.dart';
import '../widgets/app_text_field.dart';
import '../widgets/phone_field.dart';
import 'terms_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.authRepository = const AuthService(), super.key});
  final AuthRepository authRepository;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  CountryDialCode _country = indiaCountry;
  bool _isSubmitting = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter your full name.';
    if (name.length < 2) return 'Enter at least 2 characters.';
    return null;
  }

  String? _validateMobile(String? value) {
    final number = value?.trim() ?? '';
    if (number.isEmpty) return 'Please enter your mobile number.';
    if (number.length != 10) return 'Enter a valid 10-digit number.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please create a password.';
    if (value.length < 6) return 'Use at least 6 characters.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;
    if (!_acceptedTerms) {
      showAuthMessage(context, 'Please accept the Terms & Conditions');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _country.dialCode + _mobileController.text.trim(),
        countryCode: _country.dialCode,
        countryIso: _country.iso2,
        password: _passwordController.text,
      );
      if (mounted) showAuthMessage(context, 'Your account has been created.');
    } on AuthFailure catch (failure) {
      if (mounted) showAuthMessage(context, authFailureMessage(failure));
    } catch (_) {
      if (mounted) {
        showAuthMessage(
          context,
          'Unable to create your account. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: AtithiLogo()),
        const SizedBox(height: 20),
        const AuthHeading(
          title: 'Create your account',
          subtitle: 'Join Atithi for a comfortable stay.',
        ),
        const SizedBox(height: 22),
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              AppTextField(
                hint: 'Full name',
                controller: _nameController,
                validator: _validateName,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                hint: 'Email address',
                controller: _emailController,
                validator: validateEmailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              PhoneField(
                country: _country,
                controller: _mobileController,
                onCountryChanged: (country) =>
                    setState(() => _country = country),
                validator: _validateMobile,
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
        const SizedBox(height: 22),
        Row(
          children: [
            Checkbox(
              value: _acceptedTerms,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _acceptedTerms = value ?? false),
              activeColor: const Color(0xFFE0BC73),
              checkColor: const Color(0xFF0B2347),
              side: const BorderSide(color: Color(0xFFFAF5EB)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Expanded(
              child: InkWell(
                onTap: _isSubmitting
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TermsAndConditionsScreen(),
                        ),
                      ),
                child: const Text.rich(
                  TextSpan(
                    style: TextStyle(color: Color(0xFFFAF5EB), fontSize: 14),
                    children: [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: Color(0xFFE0BC73),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AuthPrimaryButton(
          label: 'Create Account',
          onPressed: _isSubmitting ? null : _submit,
          isLoading: _isSubmitting,
        ),
        const SizedBox(height: 18),
        Center(
          child: AuthFooterLink(
            prompt: 'Already have an account?',
            label: 'Sign In',
            onPressed: _isSubmitting ? null : () => context.pop(),
          ),
        ),
      ],
    ),
  );
}
