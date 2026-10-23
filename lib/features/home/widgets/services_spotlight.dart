import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_colors.dart';

class ServicesSpotlight<T> extends StatefulWidget {
  const ServicesSpotlight({
    required this.services,
    required this.nameOf,
    required this.descriptionOf,
    required this.iconOf,
    super.key,
  });

  final List<T> services;
  final String Function(T) nameOf;
  final String Function(T) descriptionOf;
  final IconData Function(T) iconOf;

  @override
  State<ServicesSpotlight<T>> createState() => _ServicesSpotlightState<T>();
}

class _ServicesSpotlightState<T> extends State<ServicesSpotlight<T>> {
  static const _viewportFraction = 0.58;

  final PageController _pageController = PageController(
    viewportFraction: _viewportFraction,
  );
  Timer? _autoPlayTimer;
  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant ServicesSpotlight<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.services.length != widget.services.length) {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (widget.services.length < 2 ||
        _activePointers > 0 ||
        _autoPlayTimer != null) {
      return;
    }
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;
      final page = _pageController.page ?? 0;
      final currentIndex = page
          .round()
          .clamp(0, widget.services.length - 1)
          .toInt();
      final nextIndex = currentIndex == widget.services.length - 1
          ? 0
          : currentIndex + 1;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPointerDown(PointerDownEvent _) {
    _activePointers++;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _onPointerEnd(PointerEvent _) {
    if (_activePointers > 0) _activePointers--;
    if (_activePointers == 0) _startAutoPlay();
  }

  Future<void> _openService(int index) async {
    if (widget.services.length > 1 && _pageController.hasClients) {
      final currentIndex = (_pageController.page ?? 0).round();
      if (currentIndex != index) {
        await _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    }
    if (mounted) await context.push<void>('/services');
  }

  double _requiredHeight(BuildContext context, double cardWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    final titleStyle = GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );
    final descriptionStyle = GoogleFonts.dmSans(fontSize: 12, height: 1.2);
    final textWidth = math.max(0.0, cardWidth - 32).toDouble();
    var maxHeight = 176.0;

    for (final service in widget.services) {
      final titlePainter = TextPainter(
        text: TextSpan(text: widget.nameOf(service), style: titleStyle),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        maxLines: 2,
      )..layout(maxWidth: textWidth);
      final description = widget.descriptionOf(service).trim();
      var contentHeight = 40 + 52 + 12 + titlePainter.height + 8 + 18;
      if (description.isNotEmpty) {
        final descriptionPainter = TextPainter(
          text: TextSpan(text: description, style: descriptionStyle),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: textWidth);
        contentHeight += 4 + descriptionPainter.height;
      }
      maxHeight = math.max(maxHeight, contentHeight).toDouble();
    }
    return maxHeight;
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCarousel = widget.services.length > 1;
        final cardWidth = isCarousel
            ? constraints.maxWidth * _viewportFraction
            : constraints.maxWidth;
        final height = _requiredHeight(context, cardWidth);

        if (!isCarousel) {
          final service = widget.services.first;
          return _SpotlightCard(
            name: widget.nameOf(service),
            description: widget.descriptionOf(service),
            icon: widget.iconOf(service),
            active: true,
            scale: 1,
            opacity: 1,
            height: height,
            margin: const EdgeInsets.symmetric(vertical: 4),
            onTap: () => _openService(0),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final page = _pageController.hasClients
                      ? _pageController.page ?? 0
                      : _pageController.initialPage.toDouble();
                  return Listener(
                    onPointerDown: _onPointerDown,
                    onPointerUp: _onPointerEnd,
                    onPointerCancel: _onPointerEnd,
                    child: PageView.builder(
                      controller: _pageController,
                      padEnds: false,
                      clipBehavior: Clip.none,
                      itemCount: widget.services.length,
                      itemBuilder: (context, index) {
                        final service = widget.services[index];
                        final distance = (page - index).abs();
                        return _SpotlightCard(
                          name: widget.nameOf(service),
                          description: widget.descriptionOf(service),
                          icon: widget.iconOf(service),
                          active: distance < 0.5,
                          scale: 1 - (0.1 * distance.clamp(0, 1).toDouble()),
                          opacity: 1 - (0.15 * distance.clamp(0, 1).toDouble()),
                          height: height,
                          onTap: () => _openService(index),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final page = _pageController.hasClients
                    ? _pageController.page ?? 0
                    : _pageController.initialPage.toDouble();
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: List.generate(widget.services.length, (index) {
                    final active = (page - index).abs() < 0.5;
                    return GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(
                            alpha: active ? 1 : 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightCard extends StatefulWidget {
  const _SpotlightCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.active,
    required this.scale,
    required this.opacity,
    required this.height,
    this.margin = const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    required this.onTap,
  });

  final String name;
  final String description;
  final IconData icon;
  final bool active;
  final double scale;
  final double opacity;
  final double height;
  final EdgeInsetsGeometry margin;
  final VoidCallback onTap;

  @override
  State<_SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<_SpotlightCard> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    setState(() => _pressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = widget.description.trim().isNotEmpty;
    return Transform.scale(
      scale: widget.scale,
      child: Opacity(
        opacity: widget.opacity,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: widget.margin,
              decoration: BoxDecoration(
                color: widget.active ? null : AppColors.surface,
                gradient: widget.active
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF12284C), Color(0xFF0C1D3A)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.gold.withValues(
                    alpha: widget.active ? 0.6 : 0.28,
                  ),
                  width: 1,
                ),
                boxShadow: widget.active
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.height - 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ServiceIcon(icon: widget.icon, active: widget.active),
                      const SizedBox(height: 12),
                      Text(
                        widget.name,
                        maxLines: 2,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.active ? Colors.white : AppColors.navy,
                          height: 1.2,
                        ),
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: widget.active
                                ? const Color(0xFFB8C4D9)
                                : AppColors.secondaryText,
                            height: 1.2,
                          ),
                        ),
                      ],
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: widget.active ? 1 : 0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore',
                              style: GoogleFonts.dmSans(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.gold,
                              size: 14,
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
        ),
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (active) const _PulsingRing(),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? null : const Color(0xFFF6E7C3),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0D78F), Color(0xFFD4A84F)],
                  )
                : null,
          ),
          child: Icon(
            icon,
            color: active ? AppColors.navy : const Color(0xFFB98A2C),
            size: 24,
          ),
        ),
      ],
    ),
  );
}

class _PulsingRing extends StatefulWidget {
  const _PulsingRing();

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final progress = Curves.easeOut.transform(_controller.value);
      return Transform.scale(
        scale: 1 + (0.25 * progress),
        child: Opacity(
          opacity: 1 - progress,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.75),
                width: 1.5,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ServicesSpotlightSkeleton extends StatelessWidget {
  const ServicesSpotlightSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 176,
    child: Shimmer.fromColors(
      baseColor: AppColors.gold.withValues(alpha: 0.12),
      highlightColor: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: List.generate(3, (index) {
          final width = MediaQuery.sizeOf(context).width * 0.58;
          return Container(
            width: width,
            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: width * 0.68,
                  height: 17,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: width * 0.84,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ),
  );
}
