import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_menu_button.dart';
import '../../../widgets/app_network_image.dart';

const String _defaultHeroBedroom =
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80';

class RoomsHeader extends StatelessWidget {
  const RoomsHeader({this.imageUrl, super.key});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final effectiveImageUrl =
        (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? imageUrl!
            : _defaultHeroBedroom;

    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF8F2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Soft warm background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFCF9F3),
                    Color(0xFFF9F4EA),
                    Color(0xFFF6EFE2),
                  ],
                ),
              ),
            ),
          ),

          // 2. Botanical leaf accent in the top-left corner
          const Positioned(
            left: 0,
            top: 0,
            width: 140,
            height: 200,
            child: IgnorePointer(
              child: CustomPaint(painter: _BotanicalLeafPainter()),
            ),
          ),

          // 3. Luxury bedroom image on the right with soft gradient blend
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: isMobile
                ? MediaQuery.sizeOf(context).width * 0.62
                : 580,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0.0, 0.35, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0x99000000),
                    Colors.black,
                  ],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.8, 1.0],
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: AppNetworkImage(
                    url: effectiveImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // 4. Smooth flowing gold ribbon wave at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: const IgnorePointer(
              child: CustomPaint(painter: _GoldenWavePainter()),
            ),
          ),

          // 5. Hero Content & Navigation
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                isMobile ? 28 : 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Row(
                    children: [
                      _circleButton(
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.navy,
                          size: 20,
                        ),
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                      const Spacer(),
                      // Center Atithi Logo
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF0EBE1),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/atithi_mark.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Spacer(),
                      // Notification Button with Gold Badge Dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _circleButton(
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.navy,
                              size: 20,
                            ),
                            onTap: () {},
                          ),
                          const Positioned(
                            right: 11,
                            top: 10,
                            child: CircleAvatar(
                              radius: 3.5,
                              backgroundColor: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      // Hamburger Menu Button
                      _circleButton(
                        child: const AppMenuButton(onDarkBackground: false),
                        onTap: () {},
                      ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 26 : 34),

                  // Title: "Our" in deep navy, "Rooms" in champagne gold
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile
                          ? MediaQuery.sizeOf(context).width * 0.58
                          : 540,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: GoogleFonts.playfairDisplay(
                              fontSize: context.responsive(
                                mobile: 34,
                                tablet: 38,
                                desktop: 42,
                              ),
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Our ',
                                style: TextStyle(color: AppColors.navy),
                              ),
                              TextSpan(
                                text: 'Rooms',
                                style: TextStyle(color: Color(0xFFC59B3F)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          'Find your perfect stay from a wide range of rooms, designed for comfort and luxury.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF2C3E50),
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Gold Italic Tagline with curved underline accent
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "More than a stay,\nit's an experience",
                                  style: GoogleFonts.playfairDisplay(
                                    color: const Color(0xFFC59B3F),
                                    fontSize: 14.5,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Padding(
                                  padding: EdgeInsets.only(top: 14),
                                  child: Icon(
                                    Icons.favorite_border_rounded,
                                    size: 16,
                                    color: Color(0xFFC59B3F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const SizedBox(
                              width: 145,
                              height: 8,
                              child: CustomPaint(
                                painter: _TaglineUnderlinePainter(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Extra bottom breathing room for the wave curve
                  SizedBox(height: isMobile ? 32 : 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required Widget child,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: const Color(0x18000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0EBE1), width: 1),
            ),
            child: Center(child: child),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Custom Painters for Golden Wave, Botanical Leaves & Tagline Underline
// ---------------------------------------------------------------------------

class _GoldenWavePainter extends CustomPainter {
  const _GoldenWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back wave ribbon
    final path1 = Path();
    path1.moveTo(0, h * 0.58);
    path1.cubicTo(w * 0.28, h * 0.45, w * 0.58, h * 0.90, w, h * 0.62);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x22E6C678),
          Color(0x45D4A84F),
          Color(0x15E6C678),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path1, paint1);

    // Front wave ribbon
    final path2 = Path();
    path2.moveTo(0, h * 0.72);
    path2.cubicTo(w * 0.22, h * 0.60, w * 0.62, h * 0.92, w, h * 0.68);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x60FFFFFF),
          Color(0x80F7E6B8),
          Color(0x35D4A84F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path2, paint2);

    // Glowing golden wave line
    final strokePath = Path();
    strokePath.moveTo(0, h * 0.72);
    strokePath.cubicTo(w * 0.22, h * 0.60, w * 0.62, h * 0.92, w, h * 0.68);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = const LinearGradient(
        colors: [
          Color(0x70D4A84F),
          Color(0xFFF7E2A9),
          Color(0xFFD4A84F),
          Color(0x40E8CA82),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BotanicalLeafPainter extends CustomPainter {
  const _BotanicalLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x2ED4A84F),
          Color(0x1AA67C24),
          Color(0x08E5C578),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0x30C59B3F);

    final stem = Path()
      ..moveTo(0, 15)
      ..cubicTo(size.width * 0.35, 45, size.width * 0.65, 85, size.width * 0.82, 135);
    canvas.drawPath(stem, stemPaint);

    void drawLeaf(double cx, double cy, double rx, double ry, double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -ry)
        ..quadraticBezierTo(rx, 0, 0, ry)
        ..quadraticBezierTo(-rx, 0, 0, -ry);
      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    drawLeaf(14, 38, 7, 20, 0.42);
    drawLeaf(28, 62, 8, 22, 0.58);
    drawLeaf(46, 88, 9, 25, 0.72);
    drawLeaf(66, 116, 8, 20, 0.86);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TaglineUnderlinePainter extends CustomPainter {
  const _TaglineUnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFC59B3F),
          Color(0xFFE8CA82),
          Color(0x20C59B3F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.95,
        size.width * 0.96,
        size.height * 0.2,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
