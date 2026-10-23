import 'dart:async';

import 'package:flutter/material.dart';

class AutoSlideServices extends StatefulWidget {
  const AutoSlideServices({
    required this.itemCount,
    required this.itemExtent,
    required this.itemBuilder,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 2),
    super.key,
  });

  final int itemCount;
  final double itemExtent;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<AutoSlideServices> createState() => _AutoSlideServicesState();
}

class _AutoSlideServicesState extends State<AutoSlideServices> {
  static const int _cycles = 100000;

  late final ScrollController _controller;
  Timer? _timer;
  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(
      initialScrollOffset: widget.itemExtent * widget.itemCount * (_cycles ~/ 2),
    );
    _startTimer();
  }

  void _startTimer() {
    if (widget.itemCount < 2 || _activePointers > 0 || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_controller.hasClients) return;
      final position = _controller.position;
      final currentIndex = (position.pixels / widget.itemExtent).round();
      final nextIndex = currentIndex + 1;
      final recenterAt = position.maxScrollExtent - widget.itemExtent * 2;

      if (nextIndex * widget.itemExtent >= recenterAt) {
        final centeredIndex =
            widget.itemCount * (_cycles ~/ 2) + nextIndex % widget.itemCount;
        _controller.jumpTo(centeredIndex * widget.itemExtent);
        return;
      }

      _controller.animateTo(
        nextIndex * widget.itemExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
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
    if (widget.itemCount <= 0 || widget.itemExtent <= 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          itemExtent: widget.itemExtent,
          itemCount: widget.itemCount * _cycles,
          itemBuilder: (context, index) =>
              widget.itemBuilder(context, index % widget.itemCount),
        ),
      ),
    );
  }
}
