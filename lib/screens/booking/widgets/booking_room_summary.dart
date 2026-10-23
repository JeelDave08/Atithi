import 'package:flutter/material.dart';

import '../../../models/room.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_network_image.dart';
import '../../room_details/widgets/room_amenities_card.dart';
import 'booking_section_card.dart';

class BookingRoomSummary extends StatelessWidget {
  const BookingRoomSummary({required this.room, super.key});

  final Room room;

  @override
  Widget build(BuildContext context) => BookingSectionCard(
    title: 'Room Summary',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: AppNetworkImage(
              url: room.imageUrls.isEmpty ? null : room.imageUrls.first,
            ),
          ),
        ),
        if (room.badge?.trim().isNotEmpty == true ||
            room.roomType?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              room.badge?.trim().isNotEmpty == true
                  ? room.badge!
                  : room.roomType!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          room.roomName ?? 'Room',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (room.bedInfo?.trim().isNotEmpty == true)
              _chip(Icons.bed_outlined, room.bedInfo!),
            if (room.capacity != null)
              _chip(Icons.people_outline, '${room.capacity} Guests'),
            if (room.sizeSqft != null)
              _chip(Icons.open_in_full, '${room.sizeSqft} sq.ft'),
          ],
        ),
        if (room.amenities.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: room.amenities
                  .take(4)
                  .map(
                    (key) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 58,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 21,
                              backgroundColor: AppColors.cream,
                              child: Icon(
                                _icon(key),
                                color: AppColors.darkGold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              RoomAmenitiesCard.labelFor(key),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    ),
  );

  static Widget _chip(IconData icon, String label) => Container(
    constraints: const BoxConstraints(maxWidth: 190),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.darkGold),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.navy, fontSize: 10),
          ),
        ),
      ],
    ),
  );

  static IconData _icon(String key) => switch (key) {
    'wifi' => Icons.wifi_outlined,
    'tv' => Icons.tv_outlined,
    'ac' => Icons.ac_unit_outlined,
    'mini_bar' => Icons.local_bar_outlined,
    'room_service' => Icons.room_service_outlined,
    'work_desk' => Icons.desk_outlined,
    'balcony' => Icons.window_outlined,
    'kids_friendly' => Icons.child_friendly_outlined,
    _ => Icons.check_circle_outline,
  };
}
