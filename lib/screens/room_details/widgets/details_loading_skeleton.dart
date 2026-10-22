import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_colors.dart';

class DetailsLoadingSkeleton extends StatelessWidget {
  const DetailsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.gold.withValues(alpha: .12),
    highlightColor: AppColors.cream,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _line(width: 220, height: 24),
          const SizedBox(height: 12),
          _line(width: 150, height: 14),
          const SizedBox(height: 22),
          _line(width: double.infinity, height: 96),
          const SizedBox(height: 16),
          _line(width: double.infinity, height: 110),
        ],
      ),
    ),
  );

  Widget _line({required double width, required double height}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
