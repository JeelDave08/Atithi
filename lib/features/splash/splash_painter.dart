import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _navy = Color(0xFF0B2447);
const _deepNavy = Color(0xFF08142B);
const _gold = Color(0xFFE2BF73);
const _cream = Color(0xFFFBF6EC);
const _sand = Color(0xFFEBDDBB);
const _slate = Color(0xFF4A5A82);
const _grey = Color(0xFF6B6F7A);

/// Vector-only sunset hotel scene. The controller is also the painter's repaint
/// listenable, so the scene animates without scheduling widget rebuilds.
class SplashPainter extends CustomPainter {
  SplashPainter({required this.animation}) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 8;
    final scale = math.max(size.width / 390, size.height / 844);
    final dx = (size.width - 390 * scale) / 2;
    final dy = (size.height - 844 * scale) / 2;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    _drawSky(canvas, t);

    final zoom = 1 + .08 * _ease(0, 6, t);
    canvas.save();
    canvas.translate(195, 560);
    canvas.scale(zoom);
    canvas.translate(-195, -560);
    _drawSun(canvas);
    _drawHotel(canvas);
    _drawWindows(canvas, t);
    _drawGround(canvas);
    _drawEntrance(canvas, t);
    _drawLightSpill(canvas, t);
    _drawToran(canvas);
    _drawDiyas(canvas, t);
    _drawPathLamps(canvas, t);
    _drawPalm(canvas, 22, t, mirrored: false);
    _drawPalm(canvas, 368, t, mirrored: true);
    _drawGuest(canvas, t);
    canvas.restore();

    _drawBloom(canvas, t);
    _drawLogo(canvas, t);
    canvas.restore();
  }

  void _drawSky(Canvas canvas, double t) {
    final rect = const Rect.fromLTWH(0, 0, 390, 844);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071A36),
            _navy,
            _slate,
            Color(0xFFE2A957),
            Color(0xFFF3D9A0),
          ],
          stops: [0, .3, .5, .66, .8],
        ).createShader(rect),
    );
    const stars = <Offset>[
      Offset(24, 72),
      Offset(67, 112),
      Offset(115, 56),
      Offset(159, 91),
      Offset(228, 65),
      Offset(283, 119),
      Offset(341, 73),
      Offset(371, 153),
      Offset(45, 204),
      Offset(136, 169),
      Offset(250, 190),
      Offset(320, 223),
      Offset(87, 246),
      Offset(193, 150),
      Offset(365, 267),
    ];
    for (var i = 0; i < stars.length; i++) {
      final twinkle = .35 + .65 * ((math.sin(t * 4.1 + i * 1.7) + 1) / 2);
      canvas.drawCircle(
        stars[i],
        i % 4 == 0 ? 1.5 : 1,
        Paint()..color = Colors.white.withValues(alpha: twinkle),
      );
    }
    final cloud = Paint()..color = _gold.withValues(alpha: .075);
    canvas.drawOval(const Rect.fromLTWH(52, 374, 118, 23), cloud);
    canvas.drawOval(
      const Rect.fromLTWH(215, 389, 135, 18),
      cloud..color = _cream.withValues(alpha: .055),
    );
  }

  void _drawSun(Canvas canvas) {
    final glow = Rect.fromCircle(center: const Offset(195, 330), radius: 230);
    canvas.drawCircle(
      const Offset(195, 330),
      230,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _cream.withValues(alpha: .25),
            _gold.withValues(alpha: .18),
            _gold.withValues(alpha: .06),
            Colors.transparent,
          ],
          stops: const [0, .35, .65, 1],
        ).createShader(glow),
    );
    canvas.drawCircle(
      const Offset(195, 300),
      52,
      Paint()..color = _cream.withValues(alpha: .96),
    );
  }

  void _drawHotel(Canvas canvas) {
    final stone = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEADCBC), Color(0xFFB9A57C)],
      ).createShader(const Rect.fromLTWH(40, 330, 310, 290));
    canvas.drawRect(const Rect.fromLTWH(120, 340, 150, 280), stone);
    canvas.drawRect(const Rect.fromLTWH(40, 420, 110, 200), stone);
    canvas.drawRect(const Rect.fromLTWH(240, 420, 110, 200), stone);
    final cornice = Paint()..color = _sand;
    canvas.drawRect(const Rect.fromLTWH(112, 331, 166, 10), cornice);
    canvas.drawRect(const Rect.fromLTWH(34, 412, 122, 10), cornice);
    canvas.drawRect(const Rect.fromLTWH(234, 412, 122, 10), cornice);
    canvas.drawRect(
      const Rect.fromLTWH(119, 614, 152, 7),
      Paint()..color = const Color(0xFF9D8964),
    );

    final dome = Path()
      ..moveTo(165, 340)
      ..lineTo(165, 330)
      ..quadraticBezierTo(165, 318, 195, 318)
      ..quadraticBezierTo(225, 318, 225, 330)
      ..lineTo(225, 340)
      ..close();
    canvas.drawPath(dome, Paint()..color = _sand);
    canvas.drawCircle(const Offset(195, 330), 5, Paint()..color = _gold);

    final plaque = RRect.fromRectAndRadius(
      const Rect.fromLTWH(150, 366, 90, 24),
      const Radius.circular(5),
    );
    canvas.drawRRect(plaque, Paint()..color = _navy);
    canvas.drawRRect(
      plaque,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _gold,
    );
    _text(
      canvas,
      'ATITHI',
      const Offset(195, 383),
      GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 4,
        color: _gold,
      ),
    );
  }

  void _drawWindows(Canvas canvas, double t) {
    final points = <Offset>[
      const Offset(52, 440),
      const Offset(82, 440),
      const Offset(112, 440),
      const Offset(252, 440),
      const Offset(282, 440),
      const Offset(312, 440),
      const Offset(52, 520),
      const Offset(82, 520),
      const Offset(112, 520),
      const Offset(252, 520),
      const Offset(282, 520),
      const Offset(312, 520),
      const Offset(150, 402),
      const Offset(185, 402),
      const Offset(220, 402),
    ];
    for (var i = 0; i < points.length; i++) {
      final start = .2 + i * (3 / (points.length - 1));
      final light = .3 + .7 * _ease(start, start + 1.2, t);
      _drawArchWindow(canvas, points[i].dx, points[i].dy, light);
    }
  }

  void _drawArchWindow(Canvas canvas, double x, double y, double light) {
    const w = 20.0, h = 36.0;
    final path = Path()
      ..moveTo(x, y + h)
      ..lineTo(x, y + 10)
      ..quadraticBezierTo(x, y, x + w / 2, y)
      ..quadraticBezierTo(x + w, y, x + w, y + 10)
      ..lineTo(x + w, y + h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF563D27));
    canvas.drawPath(path, Paint()..color = _gold.withValues(alpha: light));
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFEFB8).withValues(alpha: light),
            const Color(0xFFE7A83A).withValues(alpha: light),
          ],
        ).createShader(Rect.fromLTWH(x, y, w, h)),
    );
    final cross = Paint()
      ..color = const Color(0xFF8C6940)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x + w / 2, y + 5), Offset(x + w / 2, y + h), cross);
    canvas.drawLine(Offset(x + 1, y + 21), Offset(x + w - 1, y + 21), cross);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF755734),
    );
  }

  void _drawGround(Canvas canvas) {
    const ground = Rect.fromLTWH(0, 620, 390, 224);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13244A), _deepNavy],
        ).createShader(ground),
    );
    canvas.drawRect(
      const Rect.fromLTWH(128, 620, 134, 14),
      Paint()..color = _sand,
    );
    final path = Path()
      ..moveTo(140, 634)
      ..lineTo(250, 634)
      ..lineTo(340, 844)
      ..lineTo(50, 844)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3D2A2), Color(0xFF7A6A4A)],
        ).createShader(const Rect.fromLTWH(50, 634, 290, 210)),
    );
    final lines = Paint()
      ..color = const Color(0xFF3D3529).withValues(alpha: .20)
      ..strokeWidth = 1;
    for (final y in [662.0, 698.0, 744.0, 800.0]) {
      final f = (y - 634) / 210;
      canvas.drawLine(Offset(140 - 90 * f, y), Offset(250 + 90 * f, y), lines);
    }
    for (final baseX in [50.0, 108, 166, 224, 282, 340]) {
      canvas.drawLine(
        const Offset(195, 634),
        Offset(baseX.toDouble(), 844),
        lines,
      );
    }
  }

  void _drawEntrance(Canvas canvas, double t) {
    final outer = _archDoorPath(195, 510, 60, 620);
    final inner = _archDoorPath(195, 510, 50, 620);
    canvas.drawPath(outer, Paint()..color = _sand);
    canvas.drawPath(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4D0), Color(0xFFF6CB72), Color(0xFFC58E36)],
        ).createShader(const Rect.fromLTWH(145, 460, 100, 160)),
    );

    // Warm lobby details remain visible as the two glass leaves slide open.
    canvas.drawRect(
      const Rect.fromLTWH(146, 585, 98, 35),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFA46B32), Color(0xFFD9A354)],
        ).createShader(const Rect.fromLTWH(146, 585, 98, 35)),
    );
    canvas.drawRect(
      const Rect.fromLTWH(161, 550, 68, 28),
      Paint()..color = _navy,
    );
    canvas.drawRect(
      const Rect.fromLTWH(157, 546, 76, 5),
      Paint()..color = const Color(0xFF5E4429),
    );
    _drawChandelier(canvas);

    final open = _ease(2.8, 4.0, t);
    canvas.save();
    canvas.clipPath(inner);
    final leftWidth = 50 * (1 - .95 * open);
    final rightWidth = leftWidth;
    final doorFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD8E7DB), Color(0xFFF6D893), Color(0xFF8DB4C0)],
      ).createShader(const Rect.fromLTWH(145, 455, 100, 165));
    canvas.drawRect(Rect.fromLTWH(145, 455, leftWidth, 165), doorFill);
    canvas.drawRect(
      Rect.fromLTWH(245 - rightWidth, 455, rightWidth, 165),
      doorFill,
    );
    final doorStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _gold;
    canvas.drawRect(Rect.fromLTWH(145, 455, leftWidth, 165), doorStroke);
    canvas.drawRect(
      Rect.fromLTWH(245 - rightWidth, 455, rightWidth, 165),
      doorStroke,
    );
    if (leftWidth > 12) {
      canvas.drawCircle(
        Offset(145 + leftWidth - 5, 540),
        1.5,
        Paint()..color = _gold,
      );
    }
    if (rightWidth > 12) {
      canvas.drawCircle(
        Offset(245 - rightWidth + 5, 540),
        1.5,
        Paint()..color = _gold,
      );
    }
    canvas.restore();

    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = _sand,
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = _gold,
    );
  }

  void _drawChandelier(Canvas canvas) {
    final wire = Paint()
      ..color = const Color(0xFFA87A34)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(195, 464), const Offset(195, 482), wire);
    canvas.drawCircle(const Offset(195, 485), 3, Paint()..color = _gold);
    for (final dx in [-9.0, 0.0, 9.0]) {
      canvas.drawLine(const Offset(195, 482), Offset(195 + dx, 489), wire);
      canvas.drawCircle(
        Offset(195 + dx, 491),
        2,
        Paint()..color = const Color(0xFFFFE7A0),
      );
    }
  }

  void _drawLightSpill(Canvas canvas, double t) {
    final progress = _ease(3.0, 4.2, t);
    final path = Path()
      ..moveTo(145, 634)
      ..lineTo(60, 844)
      ..lineTo(330, 844)
      ..lineTo(245, 634)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFE5A0).withValues(alpha: .62 * progress),
            const Color(0xFFFFE4A0).withValues(alpha: .18 * progress),
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(60, 634, 270, 210)),
    );
  }

  void _drawToran(Canvas canvas) {
    for (var degree = 190; degree <= 350; degree += 7) {
      final radians = degree * math.pi / 180;
      final point = Offset(
        195 + 57 * math.cos(radians),
        510 + 57 * math.sin(radians),
      );
      canvas.drawCircle(
        point,
        3.4,
        Paint()
          ..color = ((degree ~/ 7).isEven ? const Color(0xFFF4A62A) : _gold),
      );
      if ((degree ~/ 7) % 3 == 0) {
        final strand = 10 + ((degree ~/ 7) % 2) * 6.0;
        final thread = Paint()
          ..color = _gold
          ..strokeWidth = 1;
        canvas.drawLine(point, Offset(point.dx, point.dy + strand), thread);
        canvas.drawCircle(
          Offset(point.dx, point.dy + strand + 2),
          2.5,
          Paint()..color = const Color(0xFFF4A62A),
        );
      }
    }
  }

  void _drawDiyas(Canvas canvas, double t) {
    for (final x in [150.0, 240.0]) {
      final flicker = 1 + .12 * math.sin(t * 11 + x);
      final glowRect = Rect.fromCircle(center: Offset(x, 620), radius: 16);
      canvas.drawCircle(
        Offset(x, 620),
        16,
        Paint()
          ..shader = RadialGradient(
            colors: [_gold.withValues(alpha: .5), _gold.withValues(alpha: 0)],
          ).createShader(glowRect),
      );
      final bowl = Path()
        ..moveTo(x - 8, 625)
        ..quadraticBezierTo(x, 633, x + 8, 625)
        ..quadraticBezierTo(x, 628, x - 8, 625)
        ..close();
      canvas.drawPath(bowl, Paint()..color = const Color(0xFFC88A3B));
      canvas.save();
      canvas.translate(x, 619);
      canvas.scale(flicker, 1.2 - .2 * (flicker - 1));
      final flame = Path()
        ..moveTo(0, -2)
        ..cubicTo(-7, -10, 1, -15, 0, -21)
        ..cubicTo(10, -11, 6, -6, 0, -2)
        ..close();
      canvas.drawPath(flame, Paint()..color = const Color(0xFFFFD36B));
      canvas.restore();
    }
  }

  void _drawPathLamps(Canvas canvas, double t) {
    const lamps = <(double, double, double)>[
      (122, 650, 1),
      (268, 650, 1),
      (78, 725, 1.25),
      (312, 725, 1.25),
      (34, 815, 1.5),
      (356, 815, 1.5),
    ];
    for (var i = 0; i < lamps.length; i++) {
      final (x, y, scale) = lamps[i];
      final pulse = .85 + .15 * math.sin(t * 2.3 + i);
      final r = 16 * scale;
      canvas.drawCircle(
        Offset(x, y - 10 * scale),
        r,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  _gold.withValues(alpha: .55 * pulse),
                  _gold.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(x, y - 10 * scale), radius: r),
              ),
      );
      final pole = Paint()
        ..color = _navy
        ..strokeWidth = 2 * scale;
      canvas.drawLine(Offset(x, y), Offset(x, y - 13 * scale), pole);
      canvas.drawCircle(
        Offset(x, y - 14 * scale),
        3 * scale,
        Paint()..color = _gold.withValues(alpha: pulse),
      );
    }
  }

  void _drawPalm(Canvas canvas, double x, double t, {required bool mirrored}) {
    canvas.save();
    canvas.translate(x, 650);
    if (mirrored) canvas.scale(-1, 1);
    canvas.rotate((math.sin(t * .75 + (mirrored ? 1 : 0)) * math.pi / 180));
    final trunk = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-4, -42, 1, -92);
    canvas.drawPath(
      trunk,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF111E37),
    );
    const crown = Offset(1, -92);
    for (var i = 0; i < 7; i++) {
      final angle = (-160 + i * 28) * math.pi / 180;
      final end = Offset(
        crown.dx + 45 * math.cos(angle),
        crown.dy + 28 * math.sin(angle),
      );
      final control = Offset(
        crown.dx + 20 * math.cos(angle),
        crown.dy + 12 * math.sin(angle) + 9,
      );
      final frond = Path()
        ..moveTo(crown.dx, crown.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(
        frond,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF111E37),
      );
    }
    canvas.restore();
  }

  void _drawGuest(Canvas canvas, double t) {
    final approach = _ease(.3, 4.4, t);
    final stepIn = _ease(4.4, 5.3, t);
    final y = t < 4.4 ? _lerp(815, 634, approach) : _lerp(634, 622, stepIn);
    final scale = t < 4.4
        ? _lerp(1.55, .62, approach)
        : _lerp(.62, .52, stepIn);
    final opacity = 1 - _ease(4.7, 5.3, t);
    if (opacity <= 0) return;
    final phase = t * 6;
    final sn = math.sin(phase), cs = math.cos(phase);
    final bob = -sn.abs() * 2.2;

    canvas.save();
    canvas.translate(195, y);
    canvas.scale(scale);
    canvas.translate(0, bob);

    // Soft, long shadow stretching down the path toward the camera.
    final shadow = Path()
      ..moveTo(-16, 0)
      ..lineTo(-58, 130)
      ..lineTo(58, 130)
      ..lineTo(16, 0)
      ..close();
    canvas.drawPath(
      shadow,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: .45 * opacity),
            Colors.black.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(-58, 0, 116, 130)),
    );

    _drawSuitcase(canvas, sn, opacity);
    _drawLeg(canvas, left: true, legSin: sn, cosPhase: cs, opacity: opacity);
    _drawLeg(canvas, left: false, legSin: -sn, cosPhase: cs, opacity: opacity);
    _drawTorso(canvas, opacity);
    _drawArms(canvas, sn, opacity);
    _drawHead(canvas, opacity);
    canvas.restore();
  }

  void _drawSuitcase(Canvas canvas, double sn, double opacity) {
    canvas.save();
    canvas.translate(-23, -87);
    canvas.rotate(sn * .021);
    final caseRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-13, 8, 27, 56),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      caseRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF6B4420), Color(0xFFA5732F)],
        ).createShader(const Rect.fromLTWH(-13, 8, 27, 56)),
    );
    canvas.drawRRect(
      caseRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _gold.withValues(alpha: opacity),
    );
    canvas.drawLine(
      const Offset(0, 12),
      const Offset(0, 59),
      Paint()
        ..color = _gold
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(-5, 8),
      const Offset(-5, 0),
      Paint()
        ..color = const Color(0xFF553B23)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(5, 8),
      const Offset(5, 0),
      Paint()
        ..color = const Color(0xFF553B23)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(-5, 0),
      const Offset(5, 0),
      Paint()
        ..color = _gold
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      const Offset(-7, 65),
      3,
      Paint()..color = const Color(0xFF171922),
    );
    canvas.drawCircle(
      const Offset(8, 65),
      3,
      Paint()..color = const Color(0xFF171922),
    );
    canvas.restore();
  }

  void _drawLeg(
    Canvas canvas, {
    required bool left,
    required double legSin,
    required double cosPhase,
    required double opacity,
  }) {
    final lift = math.max(0, legSin) * 10;
    final factor = 1 - lift / 80 + math.max(0, -legSin) * .03;
    final centerX = left ? -8.0 : 8.0;
    canvas.save();
    canvas.translate(0, -82);
    canvas.scale(1, factor);
    canvas.translate(0, 82);
    final leg = Path()
      ..moveTo(centerX - 8, -88)
      ..lineTo(centerX + 7, -88)
      ..lineTo(centerX + 8, -12)
      ..lineTo(centerX + 5, -2)
      ..lineTo(centerX - 7, -2)
      ..lineTo(centerX - 9, -13)
      ..close();
    canvas.drawPath(
      leg,
      Paint()
        ..color = (left ? const Color(0xFF1B2D52) : const Color(0xFF22407A))
            .withValues(alpha: opacity),
    );
    final shoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 10, -6, 20, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      shoe,
      Paint()..color = const Color(0xFF11141B).withValues(alpha: opacity),
    );
    final showSole = legSin > 0 && cosPhase > 0;
    if (showSole) {
      canvas.drawLine(
        Offset(centerX - 7, 0),
        Offset(centerX + 7, 0),
        Paint()
          ..color = _cream.withValues(
            alpha: (legSin * 1.5).clamp(0, 1) * opacity,
          )
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();
  }

  void _drawTorso(Canvas canvas, double opacity) {
    final jacket = Path()
      ..moveTo(-11, -132)
      ..lineTo(-19, -130)
      ..quadraticBezierTo(-25, -127, -27, -119)
      ..lineTo(-23, -87)
      ..quadraticBezierTo(0, -78, 23, -87)
      ..lineTo(27, -119)
      ..quadraticBezierTo(25, -127, 19, -130)
      ..lineTo(11, -132)
      ..close();
    canvas.drawPath(
      jacket,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF2E4F8A)],
        ).createShader(const Rect.fromLTWH(-27, -132, 54, 54))
        ..color = Colors.white.withValues(alpha: opacity),
    );
    final collar = Path()
      ..moveTo(-12, -132)
      ..lineTo(0, -122)
      ..lineTo(12, -132)
      ..lineTo(7, -137)
      ..lineTo(-7, -137)
      ..close();
    canvas.drawPath(collar, Paint()..color = _cream.withValues(alpha: opacity));
    canvas.drawLine(
      const Offset(0, -119),
      const Offset(0, -82),
      Paint()
        ..color = _gold.withValues(alpha: .55 * opacity)
        ..strokeWidth = .8,
    );
    final rim = Paint()
      ..color = _gold.withValues(alpha: .85 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(
      Path()
        ..moveTo(-25, -119)
        ..quadraticBezierTo(-20, -132, -9, -131),
      rim,
    );
    canvas.drawPath(
      Path()
        ..moveTo(25, -119)
        ..quadraticBezierTo(20, -132, 9, -131),
      rim,
    );
  }

  void _drawArms(Canvas canvas, double sn, double opacity) {
    final armPaint = Paint()
      ..color = const Color(0xFF1B3564).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final leftArm = Path()
      ..moveTo(-20, -126)
      ..quadraticBezierTo(-29, -110, -25, -91)
      ..lineTo(-22, -84);
    canvas.drawPath(leftArm, armPaint);

    canvas.save();
    canvas.translate(20, -131);
    canvas.scale(1, 1 - .04 * sn);
    canvas.translate(-20, 131);
    final rightArm = Path()
      ..moveTo(20, -126)
      ..quadraticBezierTo(29, -108, 25, -92)
      ..lineTo(23, -84);
    canvas.drawPath(rightArm, armPaint);
    canvas.drawCircle(
      const Offset(23, -83),
      4,
      Paint()..color = const Color(0xFFC4906A).withValues(alpha: opacity),
    );
    canvas.restore();
    canvas.drawCircle(
      const Offset(-22, -83),
      4,
      Paint()..color = const Color(0xFFC4906A).withValues(alpha: opacity),
    );
  }

  void _drawHead(Canvas canvas, double opacity) {
    canvas.drawRect(
      const Rect.fromLTWH(-5, -142, 10, 12),
      Paint()..color = const Color(0xFFC4906A).withValues(alpha: opacity),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-17, -151, 5, 8),
      Paint()..color = const Color(0xFFC4906A).withValues(alpha: opacity),
    );
    canvas.drawOval(
      const Rect.fromLTWH(12, -151, 5, 8),
      Paint()..color = const Color(0xFFC4906A).withValues(alpha: opacity),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-14, -164, 28, 30),
      Paint()..color = const Color(0xFFB9815E).withValues(alpha: opacity),
    );
    final hair = Path()
      ..moveTo(-15, -150)
      ..quadraticBezierTo(-18, -168, 0, -168)
      ..quadraticBezierTo(18, -167, 15, -150)
      ..quadraticBezierTo(4, -157, -15, -150)
      ..close();
    canvas.drawPath(
      hair,
      Paint()..color = const Color(0xFF10131A).withValues(alpha: opacity),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, -164)
        ..quadraticBezierTo(0, -171, 10, -164),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = _gold.withValues(alpha: .8 * opacity),
    );
  }

  void _drawBloom(Canvas canvas, double t) {
    final goldProgress = _ease(5, 6.5, t);
    if (goldProgress > 0) {
      canvas.drawCircle(
        const Offset(195, 560),
        900 * goldProgress * goldProgress,
        Paint()..color = _gold,
      );
    }
    final creamProgress = _ease(5.2, 6.6, t);
    if (creamProgress > 0) {
      canvas.drawCircle(
        const Offset(195, 560),
        900 * creamProgress * creamProgress,
        Paint()..color = const Color(0xFFFBF6EC),
      );
    }
  }

  void _drawLogo(Canvas canvas, double t) {
    final fade = _ease(6.5, 7.6, t);
    if (fade <= 0) return;
    canvas.save();
    canvas.translate(0, 14 * (1 - fade));
    final alpha = fade.clamp(0.0, 1.0).toDouble();
    final arch = Path()
      ..moveTo(165, 440)
      ..lineTo(165, 395)
      ..arcTo(const Rect.fromLTWH(165, 365, 60, 60), math.pi, math.pi, false)
      ..lineTo(225, 440);
    final metric = arch.computeMetrics().first;
    final draw = _ease(6.6, 7.8, t);
    canvas.drawPath(
      metric.extractPath(0, metric.length * draw),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = _navy.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      const Offset(195, 412),
      9 * draw,
      Paint()..color = _gold.withValues(alpha: alpha),
    );
    final wave = Path()
      ..moveTo(184, 430)
      ..quadraticBezierTo(195, 435, 206, 430);
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = _navy.withValues(alpha: alpha * draw),
    );

    _text(
      canvas,
      'Atithi',
      const Offset(195, 506),
      GoogleFonts.playfairDisplay(
        fontSize: 54,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: _navy.withValues(alpha: alpha),
      ),
    );
    _text(
      canvas,
      'अतिथि',
      const Offset(195, 540),
      GoogleFonts.notoSerifDevanagari(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFA8802F).withValues(alpha: alpha),
      ),
    );
    _text(
      canvas,
      'Atithi Devo Bhava',
      const Offset(195, 584),
      GoogleFonts.playfairDisplay(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        color: _navy.withValues(alpha: alpha),
      ),
    );
    _text(
      canvas,
      'Stays that welcome you like family',
      const Offset(195, 606),
      GoogleFonts.dmSans(fontSize: 11, color: _grey.withValues(alpha: alpha)),
    );
    final pulse = .75 + .25 * math.sin(t * 4);
    for (final x in [183.0, 195.0, 207.0]) {
      canvas.drawCircle(
        Offset(x, 760),
        2.5,
        Paint()..color = _gold.withValues(alpha: alpha * pulse),
      );
    }
    canvas.restore();
  }

  Path _archDoorPath(
    double centerX,
    double springY,
    double radius,
    double bottomY,
  ) => Path()
    ..moveTo(centerX - radius, bottomY)
    ..lineTo(centerX - radius, springY)
    ..arcTo(
      Rect.fromCircle(center: Offset(centerX, springY), radius: radius),
      math.pi,
      math.pi,
      false,
    )
    ..lineTo(centerX + radius, bottomY)
    ..close();

  void _text(Canvas canvas, String value, Offset baseline, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final ascent = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(
      canvas,
      Offset(baseline.dx - painter.width / 2, baseline.dy - ascent),
    );
  }

  double _ease(double start, double end, double value) {
    final x = ((value - start) / (end - start)).clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) => false;
}
