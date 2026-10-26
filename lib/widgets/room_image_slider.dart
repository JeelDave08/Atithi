import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/image_utils.dart';
import '../theme/app_colors.dart';

/// A self-contained, infinite image slider for room cards.
///
/// Features:
/// - Independent PageController, Timer, and currentIndex per card.
/// - One-directional infinite loop using PageView.builder (modulo indexing).
/// - Staggered timer intervals based on [roomIndex] so adjacent cards don't slide together.
/// - `ValueNotifier<int>` for indicators so only dots rebuild on page changes.
/// - Pauses on mouse hover and user drag; resumes after 3 seconds.
/// - Seamless clipping and pre-caching with no edge flashing.
class RoomImageSlider extends StatefulWidget {
  const RoomImageSlider({
    required this.imageUrls,
    required this.height,
    this.roomIndex = 0,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(20)),
    super.key,
  });

  final List<String> imageUrls;
  final double height;
  final int roomIndex;
  final BorderRadius borderRadius;

  @override
  State<RoomImageSlider> createState() => _RoomImageSliderState();
}

class _RoomImageSliderState extends State<RoomImageSlider> {
  PageController? _controller;
  Timer? _timer;
  Timer? _resumeTimer;
  late final ValueNotifier<int> _currentIndexNotifier;
  bool _isHovering = false;
  bool _isDragging = false;
  bool _precacheDone = false;

  int get _initialPage => widget.imageUrls.length * 1000;

  @override
  void initState() {
    super.initState();
    _currentIndexNotifier = ValueNotifier<int>(0);
    if (widget.imageUrls.length > 1) {
      _controller = PageController(
        initialPage: _initialPage,
        viewportFraction: 1.0,
      );
      _startTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precacheDone) {
      _precacheDone = true;
      _precacheImages();
    }
  }

  @override
  void didUpdateWidget(covariant RoomImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.imageUrls, widget.imageUrls) ||
        oldWidget.roomIndex != widget.roomIndex) {
      if (widget.imageUrls.length > 1) {
        _controller ??= PageController(
          initialPage: _initialPage,
          viewportFraction: 1.0,
        );
        _precacheImages();
        _startTimer();
      } else {
        _pauseTimer();
        _controller?.dispose();
        _controller = null;
      }
    }
  }

  void _precacheImages() {
    for (final rawUrl in widget.imageUrls) {
      final resolved = resolveImageUrl(rawUrl);
      if (resolved != null && resolved.isNotEmpty) {
        try {
          precacheImage(NetworkImage(resolved), context);
        } catch (_) {}
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _timer = null;
    _resumeTimer = null;
    if (widget.imageUrls.length <= 1 || _isHovering || _isDragging) return;

    final staggerSeconds = 3 + (widget.roomIndex % 3) * 1;
    _timer = Timer.periodic(Duration(seconds: staggerSeconds), (_) {
      if (!mounted || _controller == null || !_controller!.hasClients) return;
      _controller!.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _resumeTimer?.cancel();
    _resumeTimer = null;
  }

  void _restartTimerAfterDelay() {
    if (_isHovering || _isDragging || widget.imageUrls.length <= 1) return;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), _startTimer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _controller?.dispose();
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  Widget _buildImage(String? rawUrl) {
    final resolved = resolveImageUrl(rawUrl);
    if (resolved == null) {
      return const ColoredBox(
        color: AppColors.cream,
        child: Center(
          child: Icon(Icons.bed_outlined, color: AppColors.greyText, size: 48),
        ),
      );
    }
    return Image.network(
      resolved,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => const ColoredBox(
        color: AppColors.cream,
        child: Center(
          child: Icon(Icons.bed_outlined, color: AppColors.greyText, size: 48),
        ),
      ),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: AppColors.cream,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.darkGold,
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: const ColoredBox(
            color: AppColors.cream,
            child: Center(
              child: Icon(
                Icons.bed_outlined,
                color: AppColors.greyText,
                size: 48,
              ),
            ),
          ),
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: _buildImage(widget.imageUrls.first),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: MouseRegion(
          onEnter: (_) {
            _isHovering = true;
            _pauseTimer();
          },
          onExit: (_) {
            _isHovering = false;
            _restartTimerAfterDelay();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    if (notification.dragDetails != null) {
                      _isDragging = true;
                      _pauseTimer();
                    }
                  } else if (notification is ScrollEndNotification) {
                    if (_isDragging) {
                      _isDragging = false;
                      _restartTimerAfterDelay();
                    }
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (i) {
                    _currentIndexNotifier.value = i % widget.imageUrls.length;
                  },
                  itemBuilder: (context, index) {
                    final url =
                        widget.imageUrls[index % widget.imageUrls.length];
                    return SizedBox.expand(
                      child: _buildImage(url),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentIndexNotifier,
                  builder: (context, activeIndex, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (
                        var index = 0;
                        index < widget.imageUrls.length;
                        index++
                      )
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == activeIndex ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index == activeIndex
                                ? const Color(0xFFFDEECB)
                                : Colors.white.withValues(alpha: .75),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x30000000),
                                blurRadius: 3,
                              ),
                            ],
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
}
