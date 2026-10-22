import 'dart:async';

import 'package:flutter/material.dart';

/// One-time fade, slide, and scale entrance for lazily built scroll items.
class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({
    required this.child,
    this.delay = Duration.zero,
    this.slideFrom = const Offset(0, .15),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Offset slideFrom;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  Timer? _delayTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _delayTimer?.cancel();
      _controller.value = 1;
    } else if (_controller.value == 0 && _delayTimer == null) {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              widget.slideFrom.dx * (1 - progress) * 100,
              widget.slideFrom.dy * (1 - progress) * 100,
            ),
            child: Transform.scale(scale: .95 + (.05 * progress), child: child),
          ),
        );
      },
    ),
  );
}
