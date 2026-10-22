import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/image_utils.dart';
import '../../../models/room.dart';
import '../../../theme/app_colors.dart';

class RoomGallery extends StatefulWidget {
  const RoomGallery({required this.room, super.key});

  final Room room;

  @override
  State<RoomGallery> createState() => _RoomGalleryState();
}

class _RoomGalleryState extends State<RoomGallery> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    final urls = widget.room.imageUrls;
    final nextIndex = index + 1;
    if (nextIndex >= urls.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(
        CachedNetworkImageProvider(
          optimizedImageUrl(urls[nextIndex]),
          maxWidth: 800,
        ),
        context,
        onError: (_, _) {},
      );
    });
  }

  void _openFullScreen() {
    if (widget.room.imageUrls.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenRoomGallery(
          images: widget.room.imageUrls,
          initialIndex: _page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.room.imageUrls;
    final badge = widget.room.badge?.trim().isNotEmpty == true
        ? widget.room.badge
        : widget.room.roomType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isEmpty)
                  const _ImagePlaceholder(showIcon: true)
                else
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: _openFullScreen,
                      child: _cachedImage(images[index]),
                    ),
                  ),
                if (badge != null && badge.trim().isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (images.length >= 2)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.chevron_left,
                        onPressed: _page == 0
                            ? null
                            : () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              ),
                      ),
                    ),
                  ),
                if (images.length >= 2)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.chevron_right,
                        onPressed: _page >= images.length - 1
                            ? null
                            : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              ),
                      ),
                    ),
                  ),
                if (images.length >= 2)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        child: Text(
                          '${_page + 1}/${images.length}',
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 56,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: index == _page
                            ? AppColors.gold
                            : AppColors.border,
                        width: index == _page ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _cachedImage(images[index]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cachedImage(String url) => CachedNetworkImage(
    imageUrl: optimizedImageUrl(url),
    memCacheWidth: 800,
    maxWidthDiskCache: 800,
    fadeInDuration: const Duration(milliseconds: 200),
    filterQuality: FilterQuality.low,
    fit: BoxFit.cover,
    placeholder: (_, _) => const _ImagePlaceholder(),
    errorWidget: (_, _, _) => const _ImagePlaceholder(showIcon: true),
  );
}

class FullScreenRoomGallery extends StatefulWidget {
  const FullScreenRoomGallery({
    required this.images,
    required this.initialIndex,
    super.key,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<FullScreenRoomGallery> createState() => _FullScreenRoomGalleryState();
}

class _FullScreenRoomGalleryState extends State<FullScreenRoomGallery> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: optimizedImageUrl(
                    widget.images[index],
                    width: 1600,
                  ),
                  memCacheWidth: 1600,
                  maxWidthDiskCache: 1600,
                  fadeInDuration: const Duration(milliseconds: 200),
                  filterQuality: FilterQuality.low,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const _ImagePlaceholder(),
                  errorWidget: (_, _, _) =>
                      const _ImagePlaceholder(showIcon: true),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppColors.gold),
            ),
          ),
          if (widget.images.length >= 2)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_page + 1}/${widget.images.length}',
                  style: const TextStyle(color: AppColors.cream),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cream.withValues(alpha: .9),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.navy),
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.showIcon = false});
  final bool showIcon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.cream,
    child: showIcon
        ? const Center(
            child: Icon(
              Icons.bed_outlined,
              color: AppColors.greyText,
              size: 38,
            ),
          )
        : null,
  );
}
