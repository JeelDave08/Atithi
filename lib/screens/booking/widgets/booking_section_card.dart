import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class BookingSectionCard extends StatelessWidget {
  const BookingSectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.keyAnchor,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Key? keyAnchor;

  @override
  Widget build(BuildContext context) => Container(
    key: keyAnchor,
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: .045),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
