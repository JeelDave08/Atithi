import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class WhyChooseAtithiCard extends StatelessWidget {
  const WhyChooseAtithiCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose Atithi?',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),
        const Wrap(
          runSpacing: 15,
          children: [
            _Benefit(Icons.king_bed_outlined, 'Premium Rooms & Suites'),
            _Benefit(Icons.verified_user_outlined, 'Safe & Secure Stay'),
            _Benefit(Icons.support_agent, '24/7 Support'),
            _Benefit(Icons.local_offer_outlined, 'Best Rates'),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 8, 9),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Comfort, Our Priority',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              CircleAvatar(
                backgroundColor: AppColors.navy,
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width * .39,
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: Colors.white.withValues(alpha: .1),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
