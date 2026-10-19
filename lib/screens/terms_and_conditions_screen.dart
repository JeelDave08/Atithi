import 'package:flutter/material.dart';

import '../data/terms_content.dart';

const _cream = Color(0xFFF5F0E4);
const _navy = Color(0xFF1B2A4A);
const _bodyColor = Color(0xFF566176);

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _navy),
        title: const Text(
          termsAppBarTitle,
          style: TextStyle(color: _navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                termsPageHeading,
                style: TextStyle(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                termsLastUpdated,
                style: TextStyle(color: _bodyColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                termsIntroduction,
                style: TextStyle(color: _bodyColor, height: 1.5),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < termsContent.length; i++) ...[
                Text(
                  '${i + 1}. ${termsContent[i].title}',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  termsContent[i].body,
                  style: const TextStyle(color: _bodyColor, height: 1.5),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _navy,
                      side: const BorderSide(color: _navy),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text(termsCloseLabel),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text(termsAgreeLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
