import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/room.dart';
import '../../../theme/app_colors.dart';
import 'amenity_chip.dart';
import 'room_image_carousel.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    required this.room,
    required this.isFavorite,
    required this.onFavorite,
    required this.onDetails,
    required this.onBook,
    super.key,
  });
  final Room room;
  final bool isFavorite;
  final VoidCallback onFavorite, onDetails, onBook;
  @override
  Widget build(BuildContext context) {
    final available = room.status == 'available';
    final limited = available && room.unitsLeft != null && room.unitsLeft! <= 2;
    final state = available
        ? (limited ? 'Limited Availability' : 'Available')
        : 'Sold Out';
    final stateColor = available
        ? (limited ? AppColors.darkGold : const Color(0xFF25804B))
        : const Color(0xFFB53838);
    final info = [
      if (room.capacity != null && room.capacity! > 0)
        '${room.capacity} Guests',
      if (room.bedInfo?.trim().isNotEmpty == true) room.bedInfo!,
      if (room.sizeSqft != null && room.sizeSqft! > 0) '${room.sizeSqft} sq.ft',
    ];
    final amenities = room.amenities.take(4).toList();
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      shadowColor: AppColors.navy.withValues(alpha: .12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoomImageCarousel(
              room: room,
              isFavorite: isFavorite,
              onFavorite: onFavorite,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        room.roomName ?? 'Room',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      if (room.roomType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: .22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            room.roomType!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.darkGold,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (info.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      children: info
                          .map(
                            (v) => Text(
                              v,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.greyText,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (room.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      room.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.greyText,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 4,
                      runSpacing: 5,
                      children: amenities
                          .map((a) => AmenityChip(amenity: a))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E5C8),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          '₹${NumberFormat('#,##,##0', 'en_IN').format(room.pricePerNight ?? 0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          '/ night',
                          style: TextStyle(
                            color: AppColors.greyText,
                            fontSize: 9,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 3,
                              backgroundColor: stateColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: stateColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDetails,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.darkGold),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'View Details →',
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FilledButton(
                          onPressed: available ? onBook : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.darkGold,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Book Now →',
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
