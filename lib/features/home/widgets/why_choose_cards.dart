import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import 'reveal_on_scroll.dart';

class WhyChooseFeature {
  const WhyChooseFeature({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.assetImage,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String? assetImage;
}

class WhyChooseCards extends StatelessWidget {
  const WhyChooseCards({super.key});

  static const features = [
    WhyChooseFeature(
      number: '01',
      title: 'Premium Rooms & Suites',
      subtitle: 'Spacious, clean & comfortable stays',
      icon: Icons.king_bed_rounded,
      route: '/about',
    ),
    WhyChooseFeature(
      number: '02',
      title: 'Safe & Secure Stay',
      subtitle: 'Your safety is our top priority',
      icon: Icons.verified_user_rounded,
      route: '/about',
    ),
    WhyChooseFeature(
      number: '03',
      title: '24/7 Support',
      subtitle: "We're always here for you",
      icon: Icons.headset_mic_rounded,
      route: '/about',
    ),
    WhyChooseFeature(
      number: '04',
      title: 'Best Rates',
      subtitle: 'Great stays at the best prices',
      icon: Icons.sell_rounded,
      route: '/about',
    ),
  ];

  static const reasons = [
    ('Premium Rooms & Suites', Icons.king_bed_outlined),
    ('Safe & Secure Stay', Icons.shield_outlined),
    ('24/7 Support', Icons.support_agent_outlined),
    ('Best Rates', Icons.local_offer_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < features.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(
                    child: RevealOnScroll(
                      delay: Duration(milliseconds: i * 100),
                      slideFrom: const Offset(0, .12),
                      child: _FeatureCard(feature: features[i]),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: RevealOnScroll(
                      delay: const Duration(milliseconds: 0),
                      slideFrom: const Offset(0, .12),
                      child: _FeatureCard(feature: features[0]),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RevealOnScroll(
                      delay: const Duration(milliseconds: 100),
                      slideFrom: const Offset(0, .12),
                      child: _FeatureCard(feature: features[1]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: RevealOnScroll(
                      delay: const Duration(milliseconds: 200),
                      slideFrom: const Offset(0, .12),
                      child: _FeatureCard(feature: features[2]),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RevealOnScroll(
                      delay: const Duration(milliseconds: 300),
                      slideFrom: const Offset(0, .12),
                      child: _FeatureCard(feature: features[3]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature});

  final WhyChooseFeature feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.feature.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          context.push('/about');
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
          constraints: const BoxConstraints(minHeight: 224),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                  top: 18,
                  right: 18,
                  child: Text(
                    widget.feature.number,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF0D78F),
                          AppColors.gold,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 52),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0xFFFBE7B5),
                                    Color(0x00FBE7B5),
                                  ],
                                  stops: [0.35, 1.0],
                                ),
                              ),
                            ),
                            if (widget.feature.assetImage != null &&
                                widget.feature.assetImage!.isNotEmpty)
                              Image.asset(
                                widget.feature.assetImage!,
                                height: 80,
                                fit: BoxFit.contain,
                              )
                            else
                              Icon(
                                widget.feature.icon,
                                size: 46,
                                color: const Color(0xFFB98A2C),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.feature.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.feature.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
