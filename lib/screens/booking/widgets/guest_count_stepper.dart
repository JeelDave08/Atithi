import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class GuestCountStepper extends StatelessWidget {
  const GuestCountStepper({
    required this.label,
    required this.count,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int count;
  final int minimum;
  final int? maximum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      IconButton(
        onPressed: count > minimum ? () => onChanged(count - 1) : null,
        icon: const Icon(
          Icons.remove_circle_outline,
          color: AppColors.darkGold,
        ),
      ),
      Text(
        '$count',
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
      ),
      IconButton(
        onPressed: maximum == null || count < maximum!
            ? () => onChanged(count + 1)
            : null,
        icon: const Icon(Icons.add_circle_outline, color: AppColors.darkGold),
      ),
    ],
  );
}
