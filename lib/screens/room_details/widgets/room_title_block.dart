import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/room.dart';
import '../../../theme/app_colors.dart';

class RoomTitleBlock extends StatelessWidget {
  const RoomTitleBlock({required this.room, super.key});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (room.bedInfo?.trim().isNotEmpty == true)
        _InfoChip(icon: Icons.bed_outlined, label: room.bedInfo!.trim()),
      if (room.capacity != null && room.capacity! > 0)
        _InfoChip(icon: Icons.people_outline, label: '${room.capacity} Guests'),
      if (room.sizeSqft != null && room.sizeSqft! > 0)
        _InfoChip(icon: Icons.open_in_full, label: '${room.sizeSqft} sq.ft'),
      if (room.rating != null && room.rating! > 0)
        _InfoChip(
          icon: Icons.star_outline,
          label: room.rating!.toStringAsFixed(1),
          highlight: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.roomName?.trim().isNotEmpty == true ? room.roomName! : 'Room',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.navy,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 240),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: highlight
          ? AppColors.gold.withValues(alpha: .18)
          : AppColors.cream,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.darkGold, size: 15),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
