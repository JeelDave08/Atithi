import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/room.dart';
import '../../../theme/app_colors.dart';

class RoomImageCarousel extends StatefulWidget {
  const RoomImageCarousel({
    required this.room,
    required this.isFavorite,
    required this.onFavorite,
    super.key,
  });
  final Room room;
  final bool isFavorite;
  final VoidCallback onFavorite;
  @override
  State<RoomImageCarousel> createState() => _RoomImageCarouselState();
}

class _RoomImageCarouselState extends State<RoomImageCarousel> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final urls = widget.room.imageUrls;
    return AspectRatio(
      aspectRatio: 1.42,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: urls.isEmpty ? 1 : urls.length,
            onPageChanged: (v) => setState(() => page = v),
            itemBuilder: (_, i) => urls.isEmpty
                ? const _EmptyImage()
                : CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _EmptyImage(),
                    errorWidget: (_, _, _) => const _EmptyImage(),
                  ),
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
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: widget.onFavorite,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .92),
              ),
              icon: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? Colors.red : AppColors.navy,
                size: 19,
              ),
            ),
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
        ],
      ),
    );
  }
}

class _EmptyImage extends StatelessWidget {
  const _EmptyImage();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8E3D8),
    child: Center(
      child: Icon(Icons.bed_outlined, color: AppColors.greyText, size: 36),
    ),
  );
}
