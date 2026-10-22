import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class BookingHeader extends StatelessWidget {
  const BookingHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
    child: ColoredBox(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      backgroundColor: AppColors.cream.withValues(alpha: .12),
                    ),
                    icon: const Icon(Icons.arrow_back_outlined),
                  ),
                  const Spacer(),
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Image.asset(
                      'assets/images/atithi_mark.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Atithi support is available 24/7.'),
                      ),
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      backgroundColor: AppColors.cream.withValues(alpha: .12),
                    ),
                    icon: const Icon(Icons.support_agent_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Guest Details & Booking',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.cream,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Please fill in your details to complete your booking.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
