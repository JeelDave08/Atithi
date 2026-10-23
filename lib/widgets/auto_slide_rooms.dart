import 'dart:async';

import 'package:flutter/material.dart';

class AutoSlideRooms extends StatefulWidget {
  const AutoSlideRooms({
    required this.itemCount,
    required this.itemBuilder,
    this.height = 450,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;

  @override
  State<AutoSlideRooms> createState() => _AutoSlideRoomsState();
}

class _AutoSlideRoomsState extends State<AutoSlideRooms> {
  late final PageController _controller;
  Timer? _timer;
  int _activePointers = 0;

  int get _initialPage => widget.itemCount * 5000;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: .88,
      initialPage: _initialPage,
    );
    _startTimer();
  }

  void _startTimer() {
    if (widget.itemCount < 2 || _activePointers > 0 || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients) return;
      final page = _controller.page?.round() ?? _initialPage;
      _controller.animateToPage(
        page + 1,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPointerDown(PointerDownEvent _) {
    _activePointers++;
    _timer?.cancel();
    _timer = null;
  }

  void _onPointerUp(PointerEvent _) {
    if (_activePointers > 0) _activePointers--;
    if (_activePointers == 0) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: PageView.builder(
          controller: _controller,
          padEnds: false,
          itemBuilder: (context, index) {
            final item = widget.itemBuilder(context, index % widget.itemCount);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: item,
            );
          },
        ),
      ),
    );
  }
}
