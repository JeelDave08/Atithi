import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/room.dart';
import '../../../theme/app_colors.dart';
import 'room_image_carousel.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    required this.room,
    this.isFavorite = false,
    this.onFavorite,
    required this.onDetails,
    required this.onBook,
    this.scrollOffset,
    super.key,
  });

  final Room room;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback onDetails, onBook;
  final ValueListenable<double>? scrollOffset;

  String get _displayRoomTitle {
    if (room.roomNumber != null && room.roomNumber!.trim().isNotEmpty) {
      return room.roomNumber!.trim();
    }
    final name = room.roomName ?? 'Room';
    final match = RegExp(r'\b\d{2,4}\b').firstMatch(name);
    if (match != null) {
      return match.group(0)!;
    }
    return name;
  }

  String get _displayRoomType =>
      room.roomType?.trim().isNotEmpty == true
          ? room.roomType!
          : 'Luxury Suite';

  String get _displayBedInfo {
    if (room.bedInfo != null && room.bedInfo!.trim().isNotEmpty) {
      return room.bedInfo!;
    }
    return '1 King Bed';
  }

  String get _displaySize {
    if (room.sizeSqft != null && room.sizeSqft! > 0) {
      return '${room.sizeSqft} sq.ft';
    }
    return '400 sq.ft';
  }

  String get _displayDescription {
    if (room.description != null && room.description!.trim().isNotEmpty) {
      return room.description!.trim();
    }
    return 'A comfortable and elegant stay designed for luxury and relaxation.';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: const Color(0xFFF0EBE1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Room Image Carousel with Badges & Counter
          if (scrollOffset == null)
            RoomImageCarousel(key: ValueKey(room.id), room: room)
          else
            ValueListenableBuilder<double>(
              valueListenable: scrollOffset!,
              builder: (context, offset, _) => ClipRect(
                child: Transform.translate(
                  offset: Offset(0, (offset * .035) % 12 - 6),
                  child: RoomImageCarousel(
                    key: ValueKey(room.id),
                    room: room,
                  ),
                ),
              ),
            ),

          // 2. Card Content Area
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Room Number & Category Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _displayRoomTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2D9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _displayRoomType,
                        style: const TextStyle(
                          color: Color(0xFFA67C24),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Line 2: Amenities / Specs Row
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Guests
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: Color(0xFF4A5568),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room.capacity ?? 2} Guests',
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Beds
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bed_outlined,
                          size: 16,
                          color: Color(0xFF4A5568),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _displayBedInfo,
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Size sq.ft
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.aspect_ratio_rounded,
                          size: 16,
                          color: Color(0xFF4A5568),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _displaySize,
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Line 3: Description & Circular Gold Action Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _displayDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Circular Gold Button with Navy Forward Arrow
                    Material(
                      color: const Color(0xFFF6D686),
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: const Color(0x35F6D686),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onDetails,
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.navy,
                              size: 20,
                            ),
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
