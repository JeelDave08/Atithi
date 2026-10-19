import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/sunset_widgets.dart';
import '../property/property.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({required this.property, super.key});
  final Property property;
  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  int _start = 0, _end = 2, _guests = 2;
  final int _rooms = 1;
  int get _nights => math.max(1, _end - _start).toInt();
  List<RoomType> get _availableRooms => widget.property.roomTypes
      .where((room) => room.guests >= _guests)
      .toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.navy,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 390)
              .clamp(.86, 1.08)
              .toDouble();
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(22 * scale, 18, 22 * scale, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'S U N S E T  V I L L A  R E S O R T',
                      style: TextStyle(
                        color: Palette.gold,
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'When will the sun find you here?',
                      style: serif(27 * scale, italic: true),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    SunsetDialPainter(
                      start: _start,
                      end: _end,
                      onChange: (a, b) => setState(() {
                        _start = a;
                        _end = b;
                      }),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 41,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: List.generate(14, (i) {
                          final selected = i == _start || i == _end,
                              between = i > _start && i < _end,
                              day = 20 + i;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (i <= _start) {
                                  _start = i;
                                  _end = math.max(i + 1, _end).toInt();
                                } else {
                                  _end = i;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Palette.gold
                                    : between
                                    ? Palette.gold.withOpacity(.33)
                                    : Palette.cream.withOpacity(.1),
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(i == _start ? 22 : 7),
                                  right: Radius.circular(i == _end ? 22 : 7),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day %
                                        7],
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: selected
                                          ? Palette.navy
                                          : Palette.cream.withOpacity(.65),
                                    ),
                                  ),
                                  Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Palette.navy
                                          : Palette.cream,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Palette.gold.withOpacity(.33),
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Guests · $_guests   Rooms · $_rooms',
                              style: const TextStyle(
                                color: Palette.cream,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          _counter(
                            Icons.remove,
                            () => setState(
                              () => _guests = math.max(1, _guests - 1).toInt(),
                            ),
                            filled: false,
                          ),
                          const SizedBox(width: 8),
                          _counter(
                            Icons.add,
                            () => setState(() => _guests++),
                            filled: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 19, 20, 12),
                  decoration: const BoxDecoration(
                    color: Palette.cream,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Free for your nights',
                              style: serif(16, color: Palette.navy),
                            ),
                          ),
                          Text(
                            '${_availableRooms.length} rooms',
                            style: const TextStyle(
                              color: Palette.darkGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _availableRooms.length,
                          separatorBuilder: (c, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final room = _availableRooms[i];
                            return Container(
                              height: 76,
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.07),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipPath(
                                    clipper: const ArchClipper(
                                      top: 18,
                                      bottom: 9,
                                    ),
                                    child: Container(
                                      width: 48,
                                      height: 56,
                                      color: Palette.sand,
                                      child: const Icon(
                                        Icons.bed,
                                        color: Palette.darkGold,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room.name,
                                          style: const TextStyle(
                                            color: Palette.navy,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${room.guests} Guests · ${room.beds}',
                                          style: const TextStyle(
                                            color: Palette.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${room.price}',
                                        style: const TextStyle(
                                          color: Palette.navy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Text(
                                        '/ night',
                                        style: TextStyle(
                                          color: Palette.grey,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      GoldButton(
                        label:
                            'Reserve $_nights ${_nights == 1 ? 'night' : 'nights'} →',
                        dark: true,
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your dates are ready to reserve',
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _counter(IconData icon, VoidCallback action, {required bool filled}) =>
      InkWell(
        onTap: action,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: filled ? Palette.gold : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Palette.gold),
          ),
          child: Icon(
            icon,
            size: 17,
            color: filled ? Palette.navy : Palette.gold,
          ),
        ),
      );
}

class SunsetDialPainter extends StatefulWidget {
  const SunsetDialPainter({
    required this.start,
    required this.end,
    required this.onChange,
    super.key,
  });
  final int start, end;
  final void Function(int, int) onChange;
  @override
  State<SunsetDialPainter> createState() => _SunsetDialPainterState();
}

class _SunsetDialPainterState extends State<SunsetDialPainter> {
  bool? _draggingStart;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    width: double.infinity,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 340.0).toDouble();
        return Center(
          child: GestureDetector(
            onPanStart: (details) {
              final radius = math.min(width * .43, 190 * .91);
              final centerX = width / 2;
              final startX =
                  centerX +
                  radius * math.cos(math.pi + math.pi * widget.start / 14);
              final endX =
                  centerX +
                  radius * math.cos(math.pi + math.pi * widget.end / 14);
              _draggingStart =
                  (details.localPosition.dx - startX).abs() <=
                  (details.localPosition.dx - endX).abs();
            },
            onPanUpdate: (details) {
              final radius = math.min(width * .43, 190 * .91);
              final position =
                  ((details.localPosition.dx - (width / 2 - radius)) /
                          (radius * 2) *
                          14)
                      .round()
                      .clamp(0, 13)
                      .toInt();
              HapticFeedback.selectionClick();
              if (_draggingStart == true) {
                widget.onChange(
                  position.clamp(0, widget.end - 1).toInt(),
                  widget.end,
                );
              } else {
                widget.onChange(
                  widget.start,
                  position.clamp(widget.start + 1, 13).toInt(),
                );
              }
            },
            onPanEnd: (_) => _draggingStart = null,
            child: SizedBox(
              width: width,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(width, 190),
                    painter: _DialPainter(start: widget.start, end: widget.end),
                  ),
                  Positioned(
                    top: 83,
                    child: Column(
                      children: [
                        Text(
                          '${widget.end - widget.start}',
                          style: serif(46, color: Palette.gold),
                        ),
                        const Text(
                          'nights',
                          style: TextStyle(color: Palette.cream, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 42,
                    child: Text(
                      'In · ${20 + widget.start} Oct',
                      style: const TextStyle(
                        color: Palette.cream,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 42,
                    child: Text(
                      'Out · ${20 + widget.end} Oct',
                      style: const TextStyle(
                        color: Palette.cream,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.start, required this.end});
  final int start, end;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .98),
        radius = math.min(size.width * .43, size.height * .91);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.white.withOpacity(.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawArc(
      rect,
      math.pi + math.pi * start / 14,
      math.pi * (end - start) / 14,
      false,
      Paint()
        ..color = Palette.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    for (final day in [start, end]) {
      final angle = math.pi + math.pi * day / 14,
          point = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );
      canvas.drawCircle(point, 13, Paint()..color = Palette.gold);
      canvas.drawCircle(point, 5, Paint()..color = Palette.navy);
    }
    for (var i = 0; i <= 14; i++) {
      final angle = math.pi + math.pi * i / 14;
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        1.4,
        Paint()..color = Colors.white.withOpacity(.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.start != start || old.end != end;
}
