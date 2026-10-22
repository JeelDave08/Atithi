import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../atithi_home_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/sunset_widgets.dart';
import '../../theme/app_colors.dart';
import '../../widgets/logout_dialog.dart';

class LegacyHomeScreen extends StatelessWidget {
  const LegacyHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.navy,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, c) {
          final scale = (c.maxWidth / 390).clamp(.85, 1.1).toDouble();
          return Stack(
            children: [
              Positioned(
                right: -70,
                top: -90,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Palette.gold.withOpacity(.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(22 * scale, 16, 0, 92),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'G O O D   E V E N I N G',
                              style: TextStyle(
                                fontSize: 11 * scale,
                                letterSpacing: 1.1,
                                color: Palette.cream.withOpacity(.65),
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 15 * scale,
                                  color: Palette.cream,
                                ),
                                children: const [
                                  TextSpan(text: 'Namaste, '),
                                  TextSpan(
                                    text: 'Guest',
                                    style: TextStyle(
                                      color: Palette.gold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          tooltip: 'Account options',
                          color: AppColors.cream,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (value) {
                            if (value == 'logout') showLogoutDialog(context);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: AppColors.navy,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Log out',
                                    style: TextStyle(color: AppColors.navy),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            width: 42,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Palette.gold),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(21),
                                bottom: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(
                              Icons.wb_sunny_outlined,
                              color: Palette.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),
                    const SizedBox(height: 25),
                    RichText(
                      text: TextSpan(
                        style: serif(32 * scale, italic: true),
                        children: const [
                          TextSpan(text: 'Chase the\n'),
                          TextSpan(
                            text: 'golden hour',
                            style: TextStyle(color: Palette.gold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: GestureDetector(
                        onTap: () => context.go('/availability'),
                        child: CreamPill(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: Palette.navy,
                                size: 21,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Where to?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Palette.navy,
                                      ),
                                    ),
                                    Text(
                                      'Goa · 20–22 Oct · 2 guests',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Palette.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Palette.gold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Palette.navy,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 106,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _mood(Icons.beach_access, 'Beach', scale),
                          _mood(Icons.account_balance, 'Heritage', scale),
                          _mood(Icons.forest, 'Nature', scale),
                          _mood(Icons.nightlife, 'Nightlife', scale),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Tonight's golden stays",
                              style: serif(18 * scale),
                            ),
                          ),
                          const Text(
                            'View all',
                            style: TextStyle(
                              color: Palette.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _propertyCard(context, scale),
                          _propertyCard(context, scale),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: FloatingBottomNav(selected: 0),
              ),
            ],
          );
        },
      ),
    ),
  );
  Widget _mood(IconData icon, String label, double scale) => Padding(
    padding: const EdgeInsets.only(right: 13),
    child: Column(
      children: [
        ArchContainer(
          top: 35,
          bottom: 10,
          borderColor: Palette.gold.withOpacity(.53),
          color: Colors.transparent,
          child: SizedBox(
            width: 70 * scale,
            height: 66,
            child: Icon(icon, color: Palette.gold, size: 24),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Palette.cream, fontSize: 11)),
      ],
    ),
  );
  Widget _propertyCard(BuildContext context, double scale) => GestureDetector(
    onTap: () => context.go('/property'),
    child: Container(
      width: 230 * scale,
      height: 330,
      margin: const EdgeInsets.only(right: 14),
      child: ClipPath(
        clipper: const ArchClipper(top: 112, bottom: 22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=700',
              fit: BoxFit.cover,
              placeholder: (context, url) => const _StayImageFallback(),
              errorWidget: (context, url, error) => const _StayImageFallback(),
            ),
            const Positioned(
              top: 60,
              left: 50,
              child: Icon(Icons.wb_sunny, color: Palette.gold, size: 34),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 18, top: 56),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Palette.navy],
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '★ 4.8 · Goa',
                      style: TextStyle(color: Palette.gold, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Sunset Villa Resort',
                      style: serif(21, italic: true),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '₹4,500  / night',
                      style: TextStyle(
                        color: Palette.cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StayImageFallback extends StatelessWidget {
  const _StayImageFallback();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF355C68), Color(0xFFBB875B), Palette.navy],
        stops: [0, .45, 1],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const AtithiHomeScreen();
}
