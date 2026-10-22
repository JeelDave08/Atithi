import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class AmenityChip extends StatelessWidget {
  const AmenityChip({required this.amenity, super.key});
  final String amenity;
  static const labels = {
    'wifi': 'WiFi',
    'tv': 'TV',
    'ac': 'AC',
    'room_service': 'Room Service',
    'mini_bar': 'Mini Bar',
    'kids_friendly': 'Kids Friendly',
    'work_desk': 'Work Desk',
  };
  static const icons = {
    'wifi': Icons.wifi,
    'tv': Icons.tv,
    'ac': Icons.ac_unit,
    'room_service': Icons.room_service,
    'mini_bar': Icons.local_bar,
    'kids_friendly': Icons.child_friendly,
    'work_desk': Icons.desk,
  };
  @override
  Widget build(BuildContext context) {
    final key = amenity.trim().toLowerCase().replaceAll(' ', '_');
    final label =
        labels[key] ??
        key
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icons[key] ?? Icons.check_rounded,
            size: 14,
            color: AppColors.darkGold,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.greyText),
          ),
        ],
      ),
    );
  }
}
