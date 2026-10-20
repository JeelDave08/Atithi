import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/atithi_logo.dart';

const _deepNavy = Color(0xFF1B1417);
const _gold = Color(0xFFE2BF73);
const _sand = Color(0xFFEBDDBB);
const _slate = Color(0xFF7A5C86);

/// Extends the SVG's sky and ground gradients into the letterboxed area.
class _SplashBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 390, size.height / 844);
    final left = (size.width - 390 * scale) / 2;
    final top = (size.height - 844 * scale) / 2;
    final stage = Rect.fromLTWH(left, top, 390 * scale, 844 * scale);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1B3D),
            Color(0xFF1D2F5E),
            _slate,
            Color(0xFFE58F5A),
            Color(0xFFF7C77E),
          ],
          stops: [0, .28, .48, .62, .76],
          tileMode: TileMode.clamp,
        ).createShader(stage),
    );
    final groundTop = top + 640 * scale;
    final groundBottom = top + 844 * scale;
    canvas.drawRect(
      Rect.fromLTRB(0, groundTop, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A3C3A), _deepNavy],
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromLTRB(0, groundTop, size.width, groundBottom)),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashBackdropPainter oldDelegate) => false;
}

/// V2 hotel illustration. Coordinates are kept in the source SVG's viewBox.
class SplashPainter extends CustomPainter {
  SplashPainter({required this.animation}) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 8.5;
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 390, 844));
    _sky(canvas);
    canvas.save();
    final zoom = 1 + .06 * _seg(t, 0, 6);
    canvas.translate(195, 560);
    canvas.scale(zoom);
    canvas.translate(-195, -560);
    _sun(canvas);
    _palm(canvas, 22);
    _palm(canvas, 368, mirrored: true);
    _hotel(canvas);
    _windows(canvas, t);
    _awning(canvas);
    _lobby(canvas, t);
    _awning(canvas);
    _diyas(canvas, t);
    _ground(canvas);
    _spill(canvas, t);
    _lamps(canvas);
    _guest(canvas, t);
    canvas.restore();
    _reveal(canvas, t);
    _logo(canvas, t);
    canvas.restore();
  }

  void _sky(Canvas c) {
    const r = Rect.fromLTWH(0, 0, 390, 844);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1B3D),
            Color(0xFF1D2F5E),
            Color(0xFF7A5C86),
            Color(0xFFE58F5A),
            Color(0xFFF7C77E),
          ],
          stops: [0, .28, .48, .62, .76],
        ).createShader(r),
    );
    const points = [
      Offset(40, 50),
      Offset(120, 95),
      Offset(300, 60),
      Offset(350, 130),
      Offset(230, 35),
      Offset(70, 150),
      Offset(270, 120),
      Offset(180, 70),
    ];
    for (var i = 0; i < points.length; i++) {
      c.drawCircle(
        points[i],
        1 + (i.isOdd ? .4 : 0),
        Paint()..color = Colors.white.withValues(alpha: .8),
      );
    }
    final cloud = Paint()
      ..color = const Color(0xFFF7C77E).withValues(alpha: .25);
    c.drawOval(const Rect.fromLTWH(0, 323, 120, 14), cloud);
    c.drawOval(const Rect.fromLTWH(285, 294, 100, 12), cloud);
  }

  void _sun(Canvas c) {
    final r = Rect.fromCircle(center: const Offset(195, 420), radius: 260);
    c.drawCircle(
      const Offset(195, 420),
      260,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF2C9), Color(0xCCFFC27A), Color(0x00FF9E5E)],
          stops: [0, .3, 1],
        ).createShader(r),
    );
  }

  void _hotel(Canvas c) {
    const wall = Rect.fromLTWH(55, 236, 280, 404);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFC9B28A), Color(0xFFE9D9B6), Color(0xFFBFA87F)],
          stops: [0, .5, 1],
        ).createShader(wall),
    );
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x592A1D0A)],
        ).createShader(wall),
    );
    final tower = Paint()..color = const Color(0xFFB9A27A);
    c.drawRect(const Rect.fromLTWH(40, 300, 22, 340), tower);
    c.drawRect(const Rect.fromLTWH(328, 300, 22, 340), tower);
    final trim = Paint()..color = _sand;
    c.drawRect(const Rect.fromLTWH(36, 292, 30, 10), trim);
    c.drawRect(const Rect.fromLTWH(324, 292, 30, 10), trim);
    c.drawRect(const Rect.fromLTWH(47, 224, 296, 14), trim);
    c.drawRect(
      const Rect.fromLTWH(47, 236, 296, 4),
      Paint()..color = const Color(0xFF9B865D),
    );
    c.drawRect(
      const Rect.fromLTWH(75, 208, 240, 16),
      Paint()..color = const Color(0xFFD9C79E),
    );
    c.drawRect(
      const Rect.fromLTWH(150, 194, 90, 14),
      Paint()..color = const Color(0xFFE6D5AE),
    );
    final roof = Path()
      ..moveTo(195, 170)
      ..lineTo(214, 194)
      ..lineTo(176, 194)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFFE6D5AE));
    c.drawCircle(const Offset(195, 168), 3, Paint()..color = _gold);
    for (final (y, h) in [
      (316.0, 3.0),
      (381.0, 3.0),
      (446.0, 3.0),
      (511.0, 4.0),
    ]) {
      c.drawRect(
        Rect.fromLTWH(55, y, 280, h),
        Paint()..color = _sand.withValues(alpha: .9),
      );
    }
    final pilaster = Paint()..color = const Color(0x8CF1E6C8);
    c.drawRect(const Rect.fromLTWH(55, 240, 8, 272), pilaster);
    c.drawRect(const Rect.fromLTWH(327, 240, 8, 272), pilaster);
    final sign = RRect.fromRectAndRadius(
      const Rect.fromLTWH(140, 246, 110, 26),
      const Radius.circular(13),
    );
    c.drawRRect(sign, Paint()..color = const Color(0xFF0B1A38));
    c.drawRRect(
      sign,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _gold,
    );
    _text(
      c,
      'ATITHI',
      const Offset(195, 264),
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 5,
        color: _gold,
      ),
    );
  }

  void _windows(Canvas c, double t) {
    const xs = [75.0, 120.6, 166.2, 211.8, 257.4, 303.0];
    const ys = [270.0, 335.0, 400.0, 465.0];
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 6; col++) {
        if (row == 0 && col >= 2 && col <= 3) continue;
        final delay = (row * .35 + col * .18) % 2;
        _window(
          c,
          xs[col],
          ys[row],
          .3 + .7 * _seg(t, delay, delay + 1.2),
          row.isOdd,
        );
      }
    }
    const lower = [75.0, 120.6, 257.4, 303.0];
    for (var i = 0; i < lower.length; i++) {
      final x = lower[i],
          opacity = .3 + .7 * _seg(t, .2 + i * .3, 1.4 + i * .3);
      c.saveLayer(
        Rect.fromLTWH(x - 20, 536, 68, 97),
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
      c.drawRect(
        Rect.fromLTWH(x - 4, 556, 36, 62),
        Paint()
          ..color = const Color(0x59FFD27A)
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      );
      final p = Path()
        ..moveTo(x, 612)
        ..lineTo(x, 570)
        ..arcTo(Rect.fromLTWH(x, 558, 28, 24), math.pi, math.pi, false)
        ..lineTo(x + 28, 612)
        ..close();
      c.drawPath(
        p,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0BC), Color(0xFFF2A93B)],
          ).createShader(Rect.fromLTWH(x, 558, 28, 54)),
      );
      c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF7A5A22),
      );
      c.drawLine(
        Offset(x + 14, 558),
        Offset(x + 14, 612),
        Paint()
          ..color = const Color(0xFF7A5A22).withValues(alpha: .6)
          ..strokeWidth = 1,
      );
      c.restore();
    }
  }

  void _window(Canvas c, double x, double y, double opacity, bool balcony) {
    c.saveLayer(
      Rect.fromLTWH(x - 20, y - 20, 68, 82),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    c.drawRect(
      Rect.fromLTWH(x - 5, y - 5, 38, 52),
      Paint()
        ..color = const Color(0x59FFD27A)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    );
    final p = Path()
      ..moveTo(x, y + 42)
      ..lineTo(x, y + 10)
      ..arcTo(Rect.fromLTWH(x, y, 28, 20), math.pi, math.pi, false)
      ..lineTo(x + 28, y + 42)
      ..close();
    c.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0BC), Color(0xFFF2A93B)],
        ).createShader(Rect.fromLTWH(x, y, 28, 42)),
    );
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF7A5A22),
    );
    final mullion = Paint()
      ..color = const Color(0xFF7A5A22).withValues(alpha: .6)
      ..strokeWidth = 1;
    c.drawLine(Offset(x + 14, y), Offset(x + 14, y + 42), mullion);
    c.drawLine(Offset(x, y + 24), Offset(x + 28, y + 24), mullion);
    c.drawRect(Rect.fromLTWH(x - 3, y + 42, 34, 4), Paint()..color = _sand);
    if (balcony) {
      final rail = Paint()
        ..color = const Color(0xFF6B5A3A)
        ..strokeWidth = 1;
      c.drawRect(Rect.fromLTWH(x - 5, y + 30, 38, 2), rail);
      for (var b = 0; b < 7; b++) {
        final bx = x - 3 + b * 5.6;
        c.drawLine(Offset(bx, y + 32), Offset(bx, y + 42), rail);
      }
    }
    c.restore();
  }

  void _awning(Canvas c) {
    final p = Path()
      ..moveTo(135, 524)
      ..lineTo(255, 524)
      ..lineTo(265, 548)
      ..lineTo(125, 548)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFF7A1523));
    for (var i = 0; i < 7; i++) {
      final x = 135 + i * 20.0, x1 = x + 10;
      final stripe = Path()
        ..moveTo(x, 524)
        ..lineTo(x1, 524)
        ..lineTo(x1 + (i - 3) * 1.6 + 1, 548)
        ..lineTo(x + (i - 3) * 1.6 - 1, 548)
        ..close();
      c.drawPath(stripe, Paint()..color = _gold.withValues(alpha: .9));
    }
    final scallop = Path()..moveTo(125, 548);
    for (var x = 132.0; x <= 265; x += 7) {
      scallop.quadraticBezierTo(x - 3.5, 556, x, 548);
    }
    c.drawPath(scallop, Paint()..color = _gold);
    c.drawRect(const Rect.fromLTWH(125, 522, 140, 4), Paint()..color = _gold);
    c.drawRect(const Rect.fromLTWH(143, 548, 7, 92), Paint()..color = _sand);
    c.drawRect(const Rect.fromLTWH(240, 548, 7, 92), Paint()..color = _sand);
  }

  void _lobby(Canvas c, double t) {
    const ent = Rect.fromLTWH(150, 548, 90, 92);
    c.drawRect(
      ent,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3CF), Color(0xFFF8C86A), Color(0xFFC98A2E)],
          stops: [0, .6, 1],
        ).createShader(ent),
    );
    c.save();
    c.clipRect(ent);
    c.drawCircle(
      const Offset(195, 562),
      9,
      Paint()..color = const Color(0xE6FFF8DD),
    );
    final fixture = Paint()
      ..color = const Color(0xFF8A5A1C)
      ..strokeWidth = 1.2;
    c.drawLine(const Offset(195, 548), const Offset(195, 556), fixture);
    c.drawLine(const Offset(184, 566), const Offset(206, 566), fixture);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(160, 604, 70, 36),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xD92A1A10),
    );
    c.drawRect(
      const Rect.fromLTWH(150, 620, 90, 20),
      Paint()..color = const Color(0x808A5A1C),
    );
    c.drawCircle(
      const Offset(168, 600),
      5,
      Paint()..color = const Color(0xFFFFE9A8),
    );
    c.drawCircle(
      const Offset(222, 600),
      5,
      Paint()..color = const Color(0xFFFFE9A8),
    );
    final d = _ease(_seg(t, 3.4, 4.5)), lx = 150 - 42 * d, rx = 195 + 42 * d;
    final glass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x8CBFD3F0), Color(0x33E2BF73)],
      ).createShader(ent);
    c.drawRect(Rect.fromLTWH(lx, 548, 45, 92), glass);
    c.drawRect(Rect.fromLTWH(rx, 548, 45, 92), glass);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _gold;
    c.drawRect(Rect.fromLTWH(lx, 548, 45, 92), edge);
    c.drawRect(Rect.fromLTWH(rx, 548, 45, 92), edge);
    c.restore();
  }

  void _ground(Canvas c) {
    const r = Rect.fromLTWH(-50, 640, 490, 250);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A3C3A), Color(0xFF1B1417)],
        ).createShader(r),
    );
    c.drawRect(const Rect.fromLTWH(120, 640, 150, 6), Paint()..color = _sand);
    final grid = Paint()
      ..color = const Color(0xFF8A7A6A).withValues(alpha: .25)
      ..strokeWidth = 1;
    for (final y in [668.0, 705.0, 755.0, 820.0]) {
      c.drawLine(Offset(-50, y), Offset(440, y), grid);
    }
    final carpet = Path()
      ..moveTo(150, 640)
      ..lineTo(240, 640)
      ..lineTo(330, 844)
      ..lineTo(60, 844)
      ..close();
    c.drawPath(
      carpet,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9B1B2C), Color(0xFF5E0E1B)],
        ).createShader(const Rect.fromLTWH(60, 640, 270, 204)),
    );
    final edge = Paint()
      ..color = _gold.withValues(alpha: .9)
      ..strokeWidth = 2.5;
    c.drawLine(const Offset(150, 640), const Offset(60, 844), edge);
    c.drawLine(const Offset(240, 640), const Offset(330, 844), edge);
    final seam = Paint()
      ..color = _gold.withValues(alpha: .25)
      ..strokeWidth = 1;
    c.drawLine(const Offset(195, 640), const Offset(195, 844), seam);
    c.drawLine(const Offset(172, 640), const Offset(128, 844), seam);
    c.drawLine(const Offset(218, 640), const Offset(262, 844), seam);
  }

  void _spill(Canvas c, double t) {
    final op = _seg(t, 3.4, 4.6),
        p = Path()
          ..moveTo(150, 640)
          ..lineTo(50, 844)
          ..lineTo(340, 844)
          ..lineTo(240, 640)
          ..close();
    c.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xE6FFE3A0).withValues(alpha: .9 * op),
            const Color(0x00FFE3A0),
          ],
        ).createShader(const Rect.fromLTWH(50, 640, 290, 204)),
    );
  }

  void _diyas(Canvas c, double t) {
    const points = [(150.0, 636.0), (240.0, 636.0)];
    for (var i = 0; i < 2; i++) {
      final (x, y) = points[i];
      final glow = Rect.fromCircle(center: Offset(x, y - 8), radius: 14);
      c.drawCircle(
        Offset(x, y - 8),
        14,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xE6FFE9A8), Color(0x00FFE9A8)],
          ).createShader(glow),
      );
      final bowl = Path()
        ..moveTo(x - 7, y)
        ..quadraticBezierTo(x, y + 6, x + 7, y)
        ..close();
      c.drawPath(bowl, Paint()..color = const Color(0xFFC88A3B));
      c.save();
      c.translate(x, y);
      c.scale(1 + .12 * math.sin(t * 11 + i * 2), 1 + .2 * math.sin(t * 9 + i));
      final flame = Path()
        ..moveTo(0, -1)
        ..quadraticBezierTo(-3.5, -6, 0, -13)
        ..quadraticBezierTo(3.5, -6, 0, -1)
        ..close();
      c.drawPath(flame, Paint()..color = const Color(0xFFFFD36B));
      c.restore();
    }
  }

  void _lamps(Canvas c) {
    const lamps = [
      (125.0, 652.0, 1.0),
      (265.0, 652.0, 1.0),
      (62.0, 735.0, 1.3),
      (328.0, 735.0, 1.3),
      (18.0, 825.0, 1.7),
      (372.0, 825.0, 1.7),
    ];
    for (final (x, y, s) in lamps) {
      c.save();
      c.translate(x, y);
      c.scale(s);
      c.drawRect(
        const Rect.fromLTWH(-1.5, -26, 3, 26),
        Paint()..color = const Color(0xFF1A1A22),
      );
      c.drawCircle(
        const Offset(0, -30),
        4,
        Paint()..color = const Color(0xFFFFE9A8),
      );
      final r = Rect.fromCircle(center: const Offset(0, -30), radius: 22);
      c.drawCircle(
        const Offset(0, -30),
        22,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xE6FFE9A8), Color(0x00FFE9A8)],
          ).createShader(r),
      );
      c.restore();
    }
  }

  void _palm(Canvas c, double x, {bool mirrored = false}) {
    c.save();
    c.translate(x, 640);
    if (mirrored) c.scale(-1, 1);
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-12, -80, 14, -165),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0xFF0A1A14),
    );
    for (final a in [0.0, -40, -85, -135, -180, 40, 85]) {
      c.save();
      c.translate(14, -165);
      c.rotate(a * math.pi / 180);
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(34, -18, 70, 8)
        ..quadraticBezierTo(34, -4, 0, 0)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFF0C2A1F));
      c.restore();
    }
    c.restore();
  }

  void _guest(Canvas c, double t) {
    final u = _seg(t, .3, 4.6),
        v = _seg(t, 4.6, 5.6),
        y = t < 4.6 ? 820 - 180 * u : 640 - 4 * v;
    final scale = t < 4.6 ? 1.45 - .95 * u : .5 - .12 * v,
        opacity = 1 - _seg(t, 4.9, 5.6);
    if (opacity <= 0) return;
    final phase = t * 6.5, sn = math.sin(phase);
    c.save();
    c.translate(195, y);
    c.scale(scale);
    final shadow = Rect.fromCenter(
      center: const Offset(0, 3),
      width: 72,
      height: 16,
    );
    c.drawOval(
      shadow,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x80000000), Color(0x00000000)],
        ).createShader(shadow),
    );
    c.save();
    c.translate(sn * 1.4, -sn.abs() * 2.6);
    _person(c, sn, opacity);
    c.restore();
    c.restore();
  }

  void _person(Canvas c, double sn, double opacity) {
    _leg(c, true, sn, opacity);
    _leg(c, false, -sn, opacity);
    c.save();
    c.translate(0, -86);
    c.rotate(sn * 1.6 * math.pi / 180);
    c.translate(0, 86);
    _torso(c, opacity);
    _backpack(c, opacity);
    c.restore();
    _arm(c, true, sn, opacity);
    _arm(c, false, sn, opacity);
    _head(c, opacity);
  }

  void _leg(Canvas c, bool left, double swing, double opacity) {
    final lift = math.max(0, swing);
    c.save();
    c.translate(0, -lift * 7);
    c.translate(0, -88);
    c.scale(1, 1 - lift * .1);
    c.translate(0, 88);
    final p = Path();
    if (left) {
      p
        ..moveTo(-18, -88)
        ..lineTo(-2, -88)
        ..lineTo(-4, -10)
        ..lineTo(-16, -10)
        ..close();
    } else {
      p
        ..moveTo(2, -88)
        ..lineTo(18, -88)
        ..lineTo(16, -10)
        ..lineTo(4, -10)
        ..close();
    }
    final rect = left
        ? const Rect.fromLTWH(-18, -88, 16, 78)
        : const Rect.fromLTWH(2, -88, 16, 78);
    c.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF171C2A), Color(0xFF2A3246), Color(0xFF151A27)],
        ).createShader(rect)
        ..color = Colors.white.withValues(alpha: opacity),
    );
    final shoe = Path();
    if (left) {
      shoe
        ..moveTo(-17, -10)
        ..lineTo(-3, -10)
        ..lineTo(-3, -4)
        ..quadraticBezierTo(-1, 3, -6, 3)
        ..lineTo(-16, 3)
        ..quadraticBezierTo(-20, 3, -17, -4)
        ..close();
    } else {
      shoe
        ..moveTo(3, -10)
        ..lineTo(17, -10)
        ..lineTo(17, -4)
        ..quadraticBezierTo(19, 3, 14, 3)
        ..lineTo(4, 3)
        ..quadraticBezierTo(0, 3, 3, -4)
        ..close();
    }
    c.drawPath(
      shoe,
      Paint()..color = const Color(0xFFF4F1EA).withValues(alpha: opacity),
    );
    final sx = left ? -18.5 : 2.5;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(sx, 0, 16, 3.5),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFFC6C1B5).withValues(alpha: opacity),
    );
    c.restore();
  }

  void _torso(Canvas c, double opacity) {
    final p = Path()
      ..moveTo(-24, -142)
      ..quadraticBezierTo(0, -151, 24, -142)
      ..lineTo(22, -124)
      ..lineTo(20, -84)
      ..quadraticBezierTo(0, -78, -20, -84)
      ..lineTo(-22, -124)
      ..close();
    c.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1C2A47), Color(0xFF2F4470), Color(0xFF1A2640)],
        ).createShader(const Rect.fromLTWH(-24, -151, 48, 73))
        ..color = Colors.white.withValues(alpha: opacity),
    );
    final hem = Path()
      ..moveTo(-20, -84)
      ..quadraticBezierTo(0, -78, 20, -84)
      ..lineTo(20, -90)
      ..quadraticBezierTo(0, -85, -20, -90)
      ..close();
    c.drawPath(
      hem,
      Paint()..color = const Color(0xFF101A30).withValues(alpha: .6 * opacity),
    );
  }

  void _backpack(Canvas c, double opacity) {
    final pack = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-19, -138, 38, 52),
      const Radius.circular(10),
    );
    c.drawRRect(
      pack,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC99555), Color(0xFF86592A)],
        ).createShader(const Rect.fromLTWH(-19, -138, 38, 52))
        ..color = Colors.white.withValues(alpha: opacity),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -108, 26, 22),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF7A4F22).withValues(alpha: .75 * opacity),
    );
    final gold = Paint()
      ..color = _gold.withValues(alpha: opacity)
      ..strokeWidth = 1.2;
    c.drawLine(const Offset(-13, -112), const Offset(13, -112), gold);
    c.drawLine(
      const Offset(0, -138),
      const Offset(0, -112),
      Paint()
        ..color = const Color(0xFF6A421B).withValues(alpha: .6 * opacity)
        ..strokeWidth = 1,
    );
    final straps = Paint()
      ..color = const Color(0xFF3B2610).withValues(alpha: .55 * opacity)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(-14, -142)
        ..quadraticBezierTo(-20, -122, -17, -100),
      straps,
    );
    c.drawPath(
      Path()
        ..moveTo(14, -142)
        ..quadraticBezierTo(20, -122, 17, -100),
      straps,
    );
  }

  void _arm(Canvas c, bool left, double sn, double opacity) {
    final pivot = left ? -23.0 : 23.0;
    c.save();
    c.translate(pivot, -140);
    c.scale(1, 1 + (left ? .06 : -.06) * sn);
    c.translate(-pivot, 140);
    final arm = Path();
    if (left) {
      arm
        ..moveTo(-23, -140)
        ..quadraticBezierTo(-34, -112, -31, -90);
    } else {
      arm
        ..moveTo(23, -140)
        ..quadraticBezierTo(34, -112, 31, -90);
    }
    c.drawPath(
      arm,
      Paint()
        ..color = const Color(0xFF243659).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(
      Offset(left ? -31 : 31, -84),
      4.8,
      Paint()..color = const Color(0xFFC4906A).withValues(alpha: opacity),
    );
    if (left) _duffel(c, sn, opacity);
    c.restore();
  }

  void _duffel(Canvas c, double sn, double opacity) {
    c.save();
    c.translate(-31, -84);
    c.rotate(sn * 4 * math.pi / 180);
    c.translate(31, 84);
    c.drawPath(
      Path()
        ..moveTo(-31, -82)
        ..quadraticBezierTo(-38, -92, -46, -82),
      Paint()
        ..color = const Color(0xFF2C1A0A).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    final bag = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-62, -84, 34, 22),
      const Radius.circular(8),
    );
    c.drawRRect(
      bag,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A5A2C), Color(0xFF5A3817)],
        ).createShader(const Rect.fromLTWH(-62, -84, 34, 22))
        ..color = Colors.white.withValues(alpha: opacity),
    );
    c.drawRRect(
      bag,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF2F1D0A).withValues(alpha: opacity),
    );
    c.drawRect(
      const Rect.fromLTWH(-62, -76, 34, 3),
      Paint()..color = _gold.withValues(alpha: .8 * opacity),
    );
    c.drawLine(
      const Offset(-45, -84),
      const Offset(-45, -62),
      Paint()
        ..color = const Color(0xFF2F1D0A).withValues(alpha: .6 * opacity)
        ..strokeWidth = 1,
    );
    c.drawCircle(
      const Offset(-45, -73),
      2.2,
      Paint()..color = _gold.withValues(alpha: opacity),
    );
    c.restore();
  }

  void _head(Canvas c, double opacity) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5.5, -153, 11, 12),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFA87858).withValues(alpha: opacity),
    );
    c.drawOval(
      const Rect.fromLTWH(-13.6, -168.2, 5.2, 8.4),
      Paint()..color = const Color(0xFFB98262).withValues(alpha: opacity),
    );
    c.drawOval(
      const Rect.fromLTWH(8.4, -168.2, 5.2, 8.4),
      Paint()..color = const Color(0xFFB98262).withValues(alpha: opacity),
    );
    c.drawOval(
      const Rect.fromLTWH(-11.5, -178.5, 23, 27),
      Paint()..color = const Color(0xFFC4906A).withValues(alpha: opacity),
    );
    final hair = Path()
      ..moveTo(-12, -167)
      ..quadraticBezierTo(-13.5, -183, 0, -183)
      ..quadraticBezierTo(13.5, -183, 12, -167)
      ..quadraticBezierTo(12.5, -158, 7, -154)
      ..quadraticBezierTo(0, -152, -7, -154)
      ..quadraticBezierTo(-12.5, -158, -12, -167)
      ..close();
    c.drawPath(
      hair,
      Paint()..color = const Color(0xFF1A120D).withValues(alpha: opacity),
    );
    c.drawPath(
      Path()
        ..moveTo(-8, -178)
        ..quadraticBezierTo(0, -184, 8, -178),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF4A3426).withValues(alpha: .7 * opacity),
    );
    c.drawPath(
      Path()
        ..moveTo(-11, -160)
        ..quadraticBezierTo(0, -150, 11, -160),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF0C0806).withValues(alpha: .5 * opacity),
    );
  }

  void _reveal(Canvas c, double t) {
    final a = _seg(t, 5.4, 6.8);
    if (a > 0) {
      c.drawCircle(const Offset(195, 560), 900 * a * a, Paint()..color = _gold);
    }
    final b = _seg(t, 5.6, 6.9);
    if (b > 0) {
      c.drawCircle(
        const Offset(195, 560),
        900 * b * b,
        Paint()..color = const Color(0xFFFBF6EC),
      );
    }
  }

  void _logo(Canvas c, double t) {}

  void _text(Canvas c, String text, Offset baseline, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final a = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(c, Offset(baseline.dx - tp.width / 2, baseline.dy - a));
  }

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();
  double _ease(double x) =>
      x < .5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;
  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) => false;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.currentUser, super.key});

  final Future<String?> Function() currentUser;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _reducedMotionDelay;
  bool _sessionChecked = false;
  bool _animationFinished = false;
  bool _didNavigate = false;
  bool _started = false;
  bool _fontsReady = false;
  bool _animationStarted = false;
  bool _reducedMotion = false;
  String? _user;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8500),
    )..addStatusListener(_onAnimationStatus);

    // The app remains portrait after leaving the splash.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );

    // Keep the existing session lookup and wait for both session and artwork.
    Future<String?>.sync(widget.currentUser).then(
      (user) {
        if (!mounted) return;
        _user = user;
        _sessionChecked = true;
        _navigateIfReady();
      },
      onError: (Object _) {
        if (!mounted) return;
        _user = null;
        _sessionChecked = true;
        _navigateIfReady();
      },
    );
    unawaited(_prepareFonts());
  }

  Future<void> _prepareFonts() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.playfairDisplay(
          fontSize: 54,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
        GoogleFonts.playfairDisplay(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
        ),
        GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500),
        GoogleFonts.notoSerifDevanagari(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Continue with the package's fallback if fonts are offline.
    }
    if (!mounted) return;
    _fontsReady = true;
    _startAnimationIfReady();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _hideSystemBars();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _startAnimationIfReady();
  }

  void _startAnimationIfReady() {
    if (!_started || !_fontsReady || _animationStarted || !mounted) return;
    _animationStarted = true;
    if (_reducedMotion) {
      _controller.value = 1;
      _reducedMotionDelay = Timer(const Duration(seconds: 1), _finishAnimation);
    } else {
      _controller.forward();
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_reducedMotion) {
      _finishAnimation();
    }
  }

  void _finishAnimation() {
    if (!mounted || _animationFinished) return;
    _animationFinished = true;
    _navigateIfReady();
  }

  void _navigateIfReady() {
    if (!_sessionChecked || !_animationFinished || _didNavigate || !mounted) {
      return;
    }
    _didNavigate = true;
    context.go(_user == null ? '/auth' : '/home');
  }

  void _hideSystemBars() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF08142B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0A1B3D),
    body: SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _SplashBackdropPainter(), size: Size.infinite),
          RepaintBoundary(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SizedBox(
                width: 390,
                height: 844,
                child: CustomPaint(
                  size: const Size(390, 844),
                  painter: SplashPainter(animation: _controller),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final fade = Curves.easeInOut.transform(
                ((_controller.value - .80) / .13).clamp(0.0, 1.0),
              );
              return IgnorePointer(
                child: Opacity(
                  opacity: fade,
                  child: Center(
                    child: AtithiLogo(
                      size: math.min(
                        MediaQuery.sizeOf(context).width * .62,
                        250,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _reducedMotionDelay?.cancel();
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0B2447),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }
}
