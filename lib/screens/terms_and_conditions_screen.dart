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
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.navy,
      elevation: 0,
      title: const SizedBox.shrink(),
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
                    const Center(child: AtithiLogo(size: 84)),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      termsLastUpdated,
                      style: TextStyle(color: AppColors.navy, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      termsIntroduction,
                      style: TextStyle(color: AppColors.navy, height: 1.55),
                    ),
                    const SizedBox(height: 22),
                    for (var i = 0; i < termsContent.length; i++) ...[
                      Text(
                        termsContent[i].title,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        termsContent[i].body,
                        style: const TextStyle(
                          color: AppColors.navy,
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
            child: AuthPrimaryButton(
              label: 'I Agree',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}
