import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class AmenityChip extends StatelessWidget {
  const AmenityChip({required this.amenity, super.key});
  final String amenity;
  static const labels = {
    'wifi': 'Wi-Fi',
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
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: AppColors.gold.withValues(alpha: .2),
        child: Icon(
          icons[amenity] ?? Icons.check,
          size: 15,
          color: AppColors.darkGold,
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: 56,
        child: Text(
          labels[amenity] ?? amenity,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: AppColors.greyText),
        ),
      ),
    ],
  );
}
