import 'package:flutter/material.dart';

import '../data/terms_content.dart';
import '../theme/app_colors.dart';
import '../widgets/atithi_logo.dart';
import '../widgets/auth_components.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});
  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _accepted = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: AppColors.cream,
      elevation: 0,
      title: const Text(
        'Terms & Conditions',
        style: TextStyle(
          color: AppColors.cream,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: AtithiLogo(size: 132)),
                    const SizedBox(height: 18),
                    const Text(
                      termsPageHeading,
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      termsLastUpdated,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      termsIntroduction,
                      style: TextStyle(color: AppColors.muted, height: 1.55),
                    ),
                    const SizedBox(height: 22),
                    for (var i = 0; i < termsContent.length; i++) ...[
                      Text(
                        (i + 1).toString() + '. ' + termsContent[i].title,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        termsContent[i].body,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: Column(
              children: [
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (value) =>
                      setState(() => _accepted = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.gold,
                  checkColor: AppColors.navy,
                  title: const Text(
                    'I agree to the Terms & Conditions',
                    style: TextStyle(color: AppColors.cream, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                AuthPrimaryButton(
                  label: 'I Agree & Create Account',
                  onPressed: _accepted
                      ? () => Navigator.pop(context, true)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
