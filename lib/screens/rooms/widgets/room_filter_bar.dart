import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoomFilterBar extends StatelessWidget {
  const RoomFilterBar({
    required this.isActive,
    required this.activeCount,
    required this.onAll,
    required this.onFilters,
    super.key,
  });

  final bool isActive;
  final int activeCount;
  final VoidCallback onAll;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _button(
          label: 'All',
          selected: !isActive,
          onPressed: onAll,
          icon: Icons.grid_view_rounded,
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _button(
              label: 'Filters',
              selected: false,
              onPressed: onFilters,
              icon: Icons.tune_rounded,
            ),
            if (activeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _button({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
    required IconData icon,
  }) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: SizedBox(
      height: 48,
      child: selected
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const StadiumBorder(),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const StadiumBorder(),
              ),
            ),
    ),
  );
}
