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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 170,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => _Benefit(
            index: index,
            icon: const [
              Icons.king_bed_outlined,
              Icons.verified_user_outlined,
              Icons.support_agent,
              Icons.local_offer_outlined,
            ][index],
            label: const [
              'Premium Suites',
              'Safe & Secure',
              '24/7 Support',
              'Best Rates',
            ][index],
          ),
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
  const _Benefit({
    required this.index,
    required this.icon,
    required this.label,
  });
  final int index;
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withValues(alpha: .2)),
    ),
    child: Stack(
      children: [
        Positioned(
          top: 8,
          right: 10,
          child: Text(
            '0${index + 1}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .17),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
