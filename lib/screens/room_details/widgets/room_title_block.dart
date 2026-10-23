import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/room.dart';

class RoomTitleBlock extends StatelessWidget {
  const RoomTitleBlock({required this.room, super.key});

  final Room room;

  String get _roomTitle =>
      room.roomName?.trim().isNotEmpty == true ? room.roomName!.trim() : 'Deluxe Room';

  String get _bedInfo =>
      room.bedInfo?.trim().isNotEmpty == true ? room.bedInfo!.trim() : '1 King Bed';

  String get _guests => '${room.capacity ?? 2} Guests';

  String get _size =>
      room.sizeSqft != null && room.sizeSqft! > 0
          ? '${room.sizeSqft} sq.ft'
          : '350 sq.ft';

  String get _rating =>
      room.rating != null && room.rating! > 0
          ? room.rating!.toStringAsFixed(1)
          : '4.8';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1. Room Name in Elegant Serif
      Text(
        _roomTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFF102F52),
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),

      const SizedBox(height: 12),

      // 2. Specs Row (Beds, Guests, Size)
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _SpecChip(icon: Icons.bed_outlined, label: _bedInfo),
          _SpecChip(icon: Icons.people_outline_rounded, label: _guests),
          _SpecChip(icon: Icons.aspect_ratio_rounded, label: _size),
        ],
      ),

      const SizedBox(height: 10),

      // 3. Star Rating Chip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE4D4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Color(0xFFD8A640),
              size: 16,
            ),
            const SizedBox(width: 5),
            Text(
              _rating,
              style: const TextStyle(
                color: Color(0xFF102F52),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEDE4D4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFD8A640), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF102F52),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
