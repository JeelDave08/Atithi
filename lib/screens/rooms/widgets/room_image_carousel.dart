import 'package:flutter/material.dart';

import '../../../core/image_utils.dart';
import '../../../models/room.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/wishlist_button.dart';

class RoomImageCarousel extends StatefulWidget {
  const RoomImageCarousel({required this.room, super.key});
  final Room room;

  @override
  State<RoomImageCarousel> createState() => _RoomImageCarouselState();
}

class _RoomImageCarouselState extends State<RoomImageCarousel> {
  int page = 0;

  void _onPageChanged(int index, List<String> urls) {
    setState(() => page = index);

    final nextIndex = index + 1;
    if (nextIndex >= urls.length) return;

    final nextUrl = resolveImageUrl(urls[nextIndex]);
    if (nextUrl == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      try {
        await precacheImage(NetworkImage(nextUrl), context);
      } catch (error) {
        debugPrint('Room image precache failed: $nextUrl | $error');
      }
    });
  }

  String get _badgeText {
    if (widget.room.badge != null && widget.room.badge!.trim().isNotEmpty) {
      return widget.room.badge!;
    }
    final type = widget.room.roomType?.toLowerCase() ?? '';
    final cap = widget.room.capacity ?? 2;
    if (type.contains('family') || cap >= 3) {
      return 'Family Friendly';
    }
    return 'Luxury Stay';
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.room.imageUrls;
    final totalImages = urls.isEmpty ? 1 : urls.length;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. PageView Images
          PageView.builder(
            itemCount: totalImages,
            onPageChanged: (v) => _onPageChanged(v, urls),
            itemBuilder: (_, i) =>
                AppNetworkImage(url: urls.isEmpty ? null : urls[i]),
          ),

          // 2. Top-Left Badge (Family Friendly / Room Badge)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEECB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    size: 14,
                    color: Color(0xFF281E0F),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF281E0F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top-Right Circular Favorite Button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: WishlistButton(
                roomId: widget.room.id,
                size: 40,
              ),
            ),
          ),

          // 4. Bottom-Center Carousel Indicators
          if (totalImages > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Semantics(
                label: 'Image ${page + 1} of $totalImages',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < totalImages; index++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: index == page ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == page
                              ? const Color(0xFFFCEECB)
                              : Colors.white.withValues(alpha: .75),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x30000000),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 5. Bottom-Right Image Count Badge ("1/3")
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xB810284B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${page + 1}/$totalImages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
