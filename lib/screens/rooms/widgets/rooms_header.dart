import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class RoomsHeader extends StatelessWidget {
  const RoomsHeader({this.imageUrl, super.key});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
    child: Stack(
      children: [
        Positioned.fill(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const _HeaderFallback(),
                )
              : const _HeaderFallback(),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x750B2347), Color(0xE00B2347)],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _circle(
                      Icons.arrow_back,
                      () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Image.asset(
                        'assets/images/atithi_mark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _circle(Icons.notifications_none, () {}),
                        const Positioned(
                          right: 8,
                          top: 7,
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    _circle(Icons.menu, () {}),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) => RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.playfairDisplay(
                        fontSize: constraints.maxWidth < 380 ? 32 : 36,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Our ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Rooms',
                          style: TextStyle(color: AppColors.gold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find your perfect stay from a wide range of rooms, designed for comfort and luxury.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        "More than a stay, it's an experience",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.favorite, size: 13, color: AppColors.gold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _circle(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white.withValues(alpha: .13),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

class _HeaderFallback extends StatelessWidget {
  const _HeaderFallback();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF28415E), Color(0xFF0B2347), Color(0xFF081B37)],
      ),
    ),
  );
}
