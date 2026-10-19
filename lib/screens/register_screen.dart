import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../auth/auth_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/atithi_text_field.dart';
import '../widgets/auth_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    this.authRepository = const UnconfiguredAuthRepository(),
    super.key,
  });

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
  final _confirmPasswordController = TextEditingController();
  CountryDialCode? _country;
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.trim().length < 2) return 'Enter at least 2 characters.';
    return null;
  }

  String? _validateMobile(String? value) {
    final number = value?.trim() ?? '';
    if (number.isEmpty) return 'Please enter your mobile number.';
    final country = _country;
    if (country == null) return 'Please select a country code.';
    try {
      final parsed = PhoneNumber.parse(
        number,
        callerCountry: country.isoCode,
        destinationCountry: country.isoCode,
      );
      if (parsed.isoCode != country.isoCode ||
          !parsed.isValid(type: PhoneNumberType.mobile)) {
        return 'Enter a valid mobile number for ${country.name}.';
      }
    } on PhoneNumberException {
      return 'Enter a valid mobile number for ${country.name}.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please create a password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value)) {
      return 'Include an uppercase letter, a lowercase letter, and a number.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;
    final formIsValid = _formKey.currentState!.validate();
    final country = _country;
    setState(() {
      _termsError = !_acceptedTerms;
    });
    if (!formIsValid || !_acceptedTerms || country == null) return;

    setState(() => _isSubmitting = true);
    try {
      final parsedPhone = PhoneNumber.parse(
        _mobileController.text.trim(),
        callerCountry: country.isoCode,
        destinationCountry: country.isoCode,
      );
      await widget.authRepository.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: parsedPhone.international,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAuthMessage(context, 'Account created. You can now sign in.');
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
          const Center(child: AtithiBrand()),
          const SizedBox(height: 30),
          const AuthHeading(
            title: 'Create Your Account',
            subtitle: 'Join Atithi for a comfortable stay.',
          ),
          const SizedBox(height: 23),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                AtithiTextField(
                  hint: 'Full Name',
                  controller: _nameController,
                  validator: _validateName,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 13),
                AtithiTextField(
                  hint: 'Email Address',
                  controller: _emailController,
                  validator: validateEmailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 13),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<CountryDialCode>(
                        initialValue: _country,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Country Code',
                          prefixIcon: Icon(
                            Icons.public_outlined,
                            color: AppColors.muted,
                            size: 21,
                          ),
                        ),
                        validator: (country) => country == null
                            ? 'Please select a country code.'
                            : null,
                        items: _countries
                            .map(
                              (country) => DropdownMenuItem(
                                value: country,
                                child: Text(
                                  '${country.dialCode} ${country.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (country) {
                                if (country == null) return;
                                setState(() => _country = country);
                                _formKey.currentState?.validate();
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: AtithiTextField(
                        hint: 'Mobile Number',
                        controller: _mobileController,
                        validator: _validateMobile,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                AtithiTextField(
                  hint: 'Password',
                  controller: _passwordController,
                  validator: _validatePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_confirmPasswordController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: 13),
                AtithiTextField(
                  hint: 'Confirm Password',
                  controller: _confirmPasswordController,
                  validator: _validateConfirmation,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _acceptedTerms,
            activeColor: AppColors.navy,
            visualDensity: VisualDensity.compact,
            onChanged: _isSubmitting
                ? null
                : (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                      if (_acceptedTerms) _termsError = false;
                    });
                  },
            title: const Text(
              'I agree to the Terms and Conditions',
              style: TextStyle(color: AppColors.navy, fontSize: 14),
            ),
          ),
          if (_termsError)
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Please accept the Terms and Conditions to continue.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 10),
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
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.dialCode,
    required this.isoCode,
  });

  final String name;
  final String dialCode;
  final IsoCode isoCode;
}

const _countries = [
  CountryDialCode(name: 'India', dialCode: '+91', isoCode: IsoCode.IN),
  CountryDialCode(name: 'United States', dialCode: '+1', isoCode: IsoCode.US),
  CountryDialCode(name: 'United Kingdom', dialCode: '+44', isoCode: IsoCode.GB),
  CountryDialCode(name: 'Canada', dialCode: '+1', isoCode: IsoCode.CA),
  CountryDialCode(name: 'Australia', dialCode: '+61', isoCode: IsoCode.AU),
  CountryDialCode(name: 'Singapore', dialCode: '+65', isoCode: IsoCode.SG),
  CountryDialCode(
    name: 'United Arab Emirates',
    dialCode: '+971',
    isoCode: IsoCode.AE,
  ),
];
