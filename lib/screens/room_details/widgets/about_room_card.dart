import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class AboutRoomCard extends StatelessWidget {
  const AboutRoomCard({required this.description, super.key});

  final String description;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: ColoredBox(
      color: AppColors.navy,
      child: CustomPaint(
        painter: const _GoldWavePainter(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About This Room',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.cream,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                description.trim().isEmpty
                    ? 'A welcoming space with thoughtful comforts, made for restful nights and easy mornings.'
                    : description,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Relax · Unwind · Feel at Home',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.gold,
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GoldWavePainter extends CustomPainter {
  const _GoldWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(0, size.height * .78)
      ..cubicTo(
        size.width * .22,
        size.height * .65,
        size.width * .34,
        size.height * .94,
        size.width * .55,
        size.height * .79,
      )
      ..cubicTo(
        size.width * .72,
        size.height * .68,
        size.width * .84,
        size.height * .91,
        size.width,
        size.height * .76,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldWavePainter oldDelegate) => false;
}
