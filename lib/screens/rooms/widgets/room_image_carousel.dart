import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/image_utils.dart';
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

  void _onPageChanged(int index, List<String> urls) {
    setState(() => page = index);

    final nextIndex = index + 1;
    if (nextIndex >= urls.length) return;

    final nextUrl = optimizedImageUrl(urls[nextIndex]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(
        CachedNetworkImageProvider(nextUrl, maxWidth: 800),
        context,
        onError: (_, _) {},
      );
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
            itemBuilder: (_, i) => urls.isEmpty
                ? const _RoomImagePlaceholder(showBedIcon: true)
                : CachedNetworkImage(
                    imageUrl: optimizedImageUrl(urls[i]),
                    memCacheWidth: 800,
                    maxWidthDiskCache: 800,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    filterQuality: FilterQuality.low,
                    placeholder: (_, _) => const _RoomImagePlaceholder(),
                    errorWidget: (_, _, _) =>
                        const _RoomImagePlaceholder(showBedIcon: true),
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
                          color: index == page ? AppColors.gold : Colors.white70,
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
                    const Icon(Icons.image_outlined, color: AppColors.gold, size: 13),
                    const SizedBox(width: 4),
                    Text('${page + 1}/${urls.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder({this.showBedIcon = false});
  final bool showBedIcon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.cream,
    child: showBedIcon
        ? const Center(
            child: Icon(
              Icons.bed_outlined,
              color: AppColors.greyText,
              size: 36,
            ),
          )
        : null,
  );
}
