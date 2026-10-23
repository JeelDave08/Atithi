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
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE8E2D5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "All" Tab
          _TabPill(
            label: 'All',
            icon: Icons.grid_view_rounded,
            selected: !isActive,
            onTap: onAll,
          ),

          // "Filters" Tab
          Stack(
            clipBehavior: Clip.none,
            children: [
              _TabPill(
                label: 'Filters',
                icon: Icons.tune_rounded,
                selected: isActive,
                onTap: onFilters,
              ),
              if (activeCount > 0)
                Positioned(
                  right: 6,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.navy : Colors.transparent,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : AppColors.navy,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.navy,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
