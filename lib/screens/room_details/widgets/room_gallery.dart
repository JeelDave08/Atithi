import 'package:flutter/material.dart';

import '../../../core/image_utils.dart';
import '../../../models/room.dart';
import '../../../widgets/app_network_image.dart';

class RoomGallery extends StatefulWidget {
  const RoomGallery({required this.room, super.key});

  final Room room;

  @override
  State<RoomGallery> createState() => _RoomGalleryState();
}

class _RoomGalleryState extends State<RoomGallery> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  List<String> get _galleryImages {
    final urls = widget.room.imageUrls;
    if (urls.length >= 4) return urls;

    final result = List<String>.from(urls);
    final type =
        '${widget.room.roomType ?? ''} ${widget.room.roomName}'.toLowerCase();

    final fallbacks = <String>[];
    if (type.contains('family')) {
      fallbacks.addAll(const [
        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
      ]);
    } else if (type.contains('suite')) {
      fallbacks.addAll(const [
        'https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=800&q=80',
      ]);
    } else if (type.contains('budget')) {
      fallbacks.addAll(const [
        'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=800&q=80',
      ]);
    } else {
      fallbacks.addAll(const [
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=800&q=80',
      ]);
    }

    for (final fb in fallbacks) {
      if (result.length >= 4) break;
      if (!result.contains(fb)) result.add(fb);
    }

    return result;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
    final images = _galleryImages;
    final nextIndex = index + 1;
    if (nextIndex >= images.length) return;

    final nextUrl = resolveImageUrl(images[nextIndex]);
    if (nextUrl == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      try {
        await precacheImage(NetworkImage(nextUrl), context);
      } catch (error) {
        debugPrint('Room gallery precache failed: $nextUrl | $error');
      }
    });
  }

  void _goTo(int index) {
    final images = _galleryImages;
    if (index < 0 || index >= images.length) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _galleryImages;
    final total = images.length;
    final badge = widget.room.badge?.trim().isNotEmpty == true
        ? widget.room.badge!
        : 'Best Seller';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Large Main Image
        AspectRatio(
          aspectRatio: 16 / 10.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isEmpty)
                  const AppNetworkImage(url: null)
                else
                  PageView.builder(
                    controller: _pageController,
                    itemCount: total,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) => AppNetworkImage(
                      url: images[index],
                      fit: BoxFit.cover,
                    ),
                  ),

                // Top-Left "Best Seller" Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEECB),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .12),
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
                          size: 13,
                          color: Color(0xFF281E0F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF281E0F),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom-Right "1/4" Counter Badge
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xB8102F52),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedIndex + 1}/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Thumbnails Row with Previous & Next Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Chevron Arrow
            _NavArrow(
              icon: Icons.chevron_left_rounded,
              enabled: _selectedIndex > 0,
              onTap: () => _goTo(_selectedIndex - 1),
            ),

            const SizedBox(width: 6),

            // Thumbnails (up to 4 visible)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  total.clamp(0, 4),
                  (index) {
                    final isSelected = index == _selectedIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _goTo(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD8A640)
                                  : const Color(0xFFE5DDD0),
                              width: isSelected ? 2.2 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFD8A640)
                                          .withValues(alpha: .25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AppNetworkImage(
                            url: images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Right Chevron Arrow
            _NavArrow(
              icon: Icons.chevron_right_rounded,
              enabled: _selectedIndex < total - 1,
              onTap: () => _goTo(_selectedIndex + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: 26,
      height: 48,
      child: Center(
        child: Icon(
          icon,
          color: enabled
              ? const Color(0xFF102F52)
              : const Color(0xFF102F52).withValues(alpha: .30),
          size: 24,
        ),
      ),
    ),
  );
}
