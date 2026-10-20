import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

export '../data/countries.dart' show CountryDialCode;

import '../auth/auth_repository.dart';
import '../data/countries.dart';
import '../widgets/atithi_logo.dart';
import '../widgets/auth_components.dart';
import '../widgets/auth_field.dart';
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
    if (!RegExp(r'^[0-9]+$').hasMatch(number)) return 'Use digits only.';
    if (number.length != _country.phoneLength)
      return 'Enter exactly ' +
          _country.phoneLength.toString() +
          ' digits for ' +
          _country.name +
          '.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please create a password.';
    if (value.length < 6) return 'Use at least 6 characters.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const TermsAndConditionsScreen()),
    );
    if (accepted != true || !mounted) return;
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
      if (mounted)
        showAuthMessage(
          context,
          'Unable to create your account. Please try again.',
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
        const Center(child: AtithiLogo(size: 144)),
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
              AuthField(
                hint: 'Full name',
                controller: _nameController,
                validator: _validateName,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AuthField(
                hint: 'Email address',
                controller: _emailController,
                validator: validateEmailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              PhoneField(
                country: _country,
                controller: _mobileController,
                onCountryChanged: (country) =>
                    setState(() => _country = country),
                validator: _validateMobile,
              ),
              const SizedBox(height: 14),
              AuthField(
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
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'By creating an account, you agree to our Terms & Conditions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFBAC5D6), fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
