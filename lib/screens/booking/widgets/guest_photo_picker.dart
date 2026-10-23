import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class GuestPhotoPicker extends StatelessWidget {
  const GuestPhotoPicker({required this.bytes, required this.onTap, super.key});
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Stack(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.gold.withValues(alpha: .22),
            backgroundImage: bytes == null ? null : MemoryImage(bytes!),
            child: bytes == null
                ? const Icon(
                    Icons.person_outline,
                    color: AppColors.darkGold,
                    size: 30,
                  )
                : null,
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.darkGold,
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.cream,
                size: 14,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(width: 14),
      Expanded(
        child: CustomPaint(
          foregroundPainter: DashedRoundedBorderPainter(AppColors.gold),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.darkGold,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        bytes == null
                            ? 'Upload Photo (JPG, PNG)'
                            : 'Change Photo',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class DashedRoundedBorderPainter extends CustomPainter {
  const DashedRoundedBorderPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
