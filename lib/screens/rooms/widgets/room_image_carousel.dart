import 'package:flutter/material.dart';

import '../../../core/image_utils.dart';
import '../../../models/room.dart';
import '../../../theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final urls = widget.room.imageUrls;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: urls.isEmpty ? 1 : urls.length,
            onPageChanged: (v) => _onPageChanged(v, urls),
            itemBuilder: (_, i) =>
                AppNetworkImage(url: urls.isEmpty ? null : urls[i]),
          ),
          if (widget.room.badge != null && widget.room.badge!.trim().isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.room.badge!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: WishlistButton(roomId: widget.room.id),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Semantics(
                label: 'Image ${page + 1} of ${urls.length}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < urls.length; index++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: index == page ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == page
                              ? AppColors.gold
                              : Colors.white70,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (urls.length >= 2)
            Positioned(
              right: 9,
              bottom: 9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      color: AppColors.gold,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${page + 1}/${urls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
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
