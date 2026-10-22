import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoomCapacitySummary extends StatelessWidget {
  const RoomCapacitySummary({
    required this.capacity,
    required this.bedInfo,
    required this.guestCount,
    super.key,
  });

  final int? capacity;
  final String? bedInfo;
  final int guestCount;

  @override
  Widget build(BuildContext context) {
    final exceedsCapacity = capacity != null && guestCount > capacity!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Capacity',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (capacity != null && capacity! > 0)
                _CapacityInfo(
                  icon: Icons.people_outline,
                  label: '$capacity Guests (Max)',
                ),
              if (bedInfo?.trim().isNotEmpty == true)
                _CapacityInfo(icon: Icons.bed_outlined, label: bedInfo!.trim()),
            ],
          ),
          if (exceedsCapacity) ...[
            const SizedBox(height: 10),
            Text(
              'This room fits up to $capacity guests',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CapacityInfo extends StatelessWidget {
  const _CapacityInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.darkGold, size: 17),
      const SizedBox(width: 6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.navy, fontSize: 12),
        ),
      ),
    ],
  );
}
