import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../widgets/atithi_logo.dart';

const Color atithiNavy = Color(0xFF1B2A4A);
const Color atithiGold = Color(0xFFC8924B);
const Color atithiCream = Color(0xFFF5F0E4);
const Color atithiWindowGlow = Color(0xFFFFE2A8);
const Color atithiSkin = Color(0xFFF2C29B);
const Color atithiBagBrown = Color(0xFF7A4B2A);
const bool kShowLogoAtEnd = true;

class AtithiSplashScreen extends StatefulWidget {
  const AtithiSplashScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<AtithiSplashScreen> createState() => _AtithiSplashScreenState();
}

class _AtithiSplashScreenState extends State<AtithiSplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(seconds: 5);

  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _controller = AnimationController(vsync: this, duration: _animationDuration)
      ..addListener(_onAnimationProgress);
    if (kShowLogoAtEnd) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) _finishAfterPause();
      });
    }
    _controller.forward();
  }

  void _onAnimationProgress() {
    if (kShowLogoAtEnd || _finished || _controller.value < .78) return;
    _finished = true;
    if (mounted) widget.onFinished();
  }

  Future<void> _finishAfterPause() async {
    if (_finished) return;
    _finished = true;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: atithiCream,
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final sceneOpacity = kShowLogoAtEnd
              ? 1 - _interval(t, .78, .90)
              : 1.0;
          final logoOpacity = kShowLogoAtEnd ? _interval(t, .82, 1) : 0.0;
          final logoScale = .85 + .15 * _interval(t, .82, 1);
          final logoSize = math.min(
            MediaQuery.sizeOf(context).width * .62,
            260.0,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: sceneOpacity,
                child: CustomPaint(painter: _ScenePainter(t: t)),
              ),
              if (kShowLogoAtEnd)
                Center(
                  child: Transform.scale(
                    scale: logoScale,
                    child: Opacity(
                      opacity: logoOpacity,
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: atithiCream,
                          boxShadow: [
                            BoxShadow(
                              color: atithiNavy.withValues(alpha: .10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AtithiLogo(size: logoSize),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

double _interval(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);
double _ease(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(atithiCream, BlendMode.src);
    final sceneFade = kShowLogoAtEnd ? 1 - _interval(t, .78, .90) : 1.0;
    if (sceneFade <= 0) return;
    final sc = math.min(size.width / 360, size.height / 600);
    final offX = (size.width - 360 * sc) / 2;
    final offY = size.height * .47 - 280 * sc;
    canvas.save();
    canvas.translate(offX, offY);
    canvas.scale(sc);
    canvas.saveLayer(
      Rect.fromLTWH(-offX / sc, 0, size.width / sc, size.height / sc),
      Paint()..color = Colors.white.withValues(alpha: sceneFade),
    );
    const groundY = 400.0;
    final groundStart = -offX / sc;
    final groundEnd = (size.width - offX) / sc;
    canvas.drawLine(
      Offset(groundStart, groundY),
      Offset(groundEnd, groundY),
      Paint()
        ..color = atithiNavy.withValues(alpha: .15)
        ..strokeWidth = 3,
    );
    _drawHotel(canvas, t);

    final approach = _ease(_interval(t, .02, .55));
    final enter = _ease(_interval(t, .64, .80));
    final startX = (-offX / sc) - 50;
    final boyX = startX + (180 - startX) * approach;
    final bob = math.sin(t * math.pi * 10) * 2.5 * (1 - enter);
    final boyOpacity = 1 - _interval(t, .70, .80);
    if (boyOpacity > 0) {
      canvas.save();
      canvas.translate(boyX, groundY + bob);
      canvas.scale(.8 * (1 - .4 * enter));
      canvas.saveLayer(
        const Rect.fromLTWH(-65, -145, 140, 155),
        Paint()..color = Colors.white.withValues(alpha: boyOpacity),
      );
      _drawBoy(canvas, t, approach, enter);
      canvas.restore();
      canvas.restore();
    }
    canvas.restore();
    canvas.restore();
  }

  void _drawHotel(Canvas canvas, double t) {
    final body = Path()
      ..moveTo(62, 236)
      ..lineTo(298, 236)
      ..quadraticBezierTo(310, 236, 310, 248)
      ..lineTo(310, 400)
      ..lineTo(50, 400)
      ..lineTo(50, 248)
      ..quadraticBezierTo(50, 236, 62, 236)
      ..close();
    canvas.drawPath(body, Paint()..color = atithiNavy);

    final roof = Path()
      ..moveTo(36, 216)
      ..lineTo(180, 148)
      ..lineTo(324, 216);
    canvas.drawPath(
      roof,
      Paint()
        ..color = atithiNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final glow = _interval(t, .30, .60);
    for (final x in const <double>[66, 108, 222, 264]) {
      final rect = Rect.fromLTWH(x, 286, 30, 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF3A4A6B),
            atithiWindowGlow,
            glow,
          )!,
      );
    }

    final sign = RRect.fromRectAndRadius(
      const Rect.fromLTWH(142, 250, 76, 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(sign, Paint()..color = atithiGold);
    _hotelSign(canvas);

    final door = RRect.fromRectAndRadius(
      const Rect.fromLTWH(154, 304, 52, 96),
      const Radius.circular(26),
    );
    canvas.drawRRect(door, Paint()..color = atithiWindowGlow);
    final open = _interval(t, .52, .66);
    final panelWidth = 52 * (1 - .85 * open);
    canvas.save();
    canvas.clipRRect(door);
    canvas.drawRect(
      Rect.fromLTWH(154, 304, panelWidth, 96),
      Paint()..color = atithiGold,
    );
    canvas.drawCircle(
      Offset(154 + panelWidth - 7, 354),
      2,
      Paint()..color = atithiCream,
    );
    canvas.restore();
  }

  void _hotelSign(Canvas canvas) {
    final painter = TextPainter(
      text: const TextSpan(
        text: 'HOTEL',
        style: TextStyle(
          color: atithiNavy,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(180 - painter.width / 2, 255));
  }

  void _drawBoy(Canvas canvas, double t, double walk, double enter) {
    canvas.save();
    canvas.translate(0, 12);
    canvas.scale(.714);
    final phase = t * math.pi * 10;
    final leg = math.sin(phase) * 9 * (1 - enter);
    final leftLift = math.max(0.0, math.cos(phase)) * 5 * (1 - enter);
    final rightLift = math.max(0.0, -math.cos(phase)) * 5 * (1 - enter);
    final arm = math.sin(phase + math.pi) * 7 * (1 - enter);
    final ink = Paint()
      ..color = atithiNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // legs and shoes
    canvas.drawLine(
      const Offset(-7, -48),
      Offset(-13 + leg, -20 - leftLift),
      ink,
    );
    canvas.drawLine(
      const Offset(8, -48),
      Offset(10 - leg, -20 - rightLift),
      ink,
    );
    _shoe(canvas, Offset(-13 + leg, -17 - leftLift));
    _shoe(canvas, Offset(10 - leg, -17 - rightLift));
    // backpack behind body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-34, -104, 25, 48),
        const Radius.circular(10),
      ),
      Paint()..color = atithiNavy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-32, -97, 21, 27),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF33476B),
    );
    // swinging arm
    canvas.drawLine(const Offset(11, -91), Offset(24 + arm, -61), ink);
    canvas.drawCircle(Offset(24 + arm, -60), 5, Paint()..color = atithiSkin);
    // duffel on forward hand
    final bagX = 31 + arm;
    canvas.drawLine(Offset(14, -94), Offset(bagX, -77), ink);
    canvas.drawCircle(Offset(bagX, -76), 5, Paint()..color = atithiSkin);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bagX - 9, -72, 42, 27),
        const Radius.circular(9),
      ),
      Paint()..color = atithiBagBrown,
    );
    canvas.drawArc(
      Rect.fromLTWH(bagX + 1, -80, 21, 17),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = atithiNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(bagX - 5, -59),
      Offset(bagX + 27, -59),
      Paint()
        ..color = atithiGold
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bagX + 25, -67, 7, 10),
        const Radius.circular(2),
      ),
      Paint()..color = atithiGold,
    );
    // body, shirt, collar, stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -105, 31, 59),
        const Radius.circular(11),
      ),
      Paint()..color = atithiGold,
    );
    canvas.drawLine(
      const Offset(-11, -79),
      const Offset(14, -79),
      Paint()
        ..color = const Color(0xFFE7B66F)
        ..strokeWidth = 4,
    );
    final collar = Path()
      ..moveTo(-6, -103)
      ..lineTo(0, -94)
      ..lineTo(6, -103)
      ..close();
    canvas.drawPath(collar, Paint()..color = atithiCream);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -52, 28, 18),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF4773A8),
    );
    // bag arm and hand detail on body
    canvas.drawLine(const Offset(-12, -92), Offset(-23 + arm, -69), ink);
    // head and neck
    canvas.drawRect(
      const Rect.fromLTWH(-4, -119, 11, 15),
      Paint()..color = atithiSkin,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-16, -151, 35, 38),
      Paint()..color = atithiSkin,
    );
    canvas.drawCircle(const Offset(17, -133), 5, Paint()..color = atithiSkin);
    canvas.drawCircle(
      const Offset(16, -133),
      2.3,
      Paint()..color = const Color(0xFFD89D77),
    );
    // hair tuft and cap
    final tuft = Path()
      ..moveTo(-11, -146)
      ..quadraticBezierTo(-10, -157, -3, -151)
      ..quadraticBezierTo(1, -160, 5, -150)
      ..lineTo(8, -145)
      ..close();
    canvas.drawPath(tuft, Paint()..color = const Color(0xFF49362C));
    canvas.drawArc(
      const Rect.fromLTWH(-17, -159, 37, 25),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = atithiNavy
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-22, -140, 47, 5),
        const Radius.circular(3),
      ),
      Paint()..color = atithiGold,
    );
    canvas.drawCircle(const Offset(1, -159), 3, Paint()..color = atithiGold);
    // brow, eye highlight, smile and blush
    canvas.drawLine(
      const Offset(6, -139),
      const Offset(13, -140),
      Paint()
        ..color = const Color(0xFF49362C)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(10, -134), 2, Paint()..color = atithiNavy);
    canvas.drawCircle(
      const Offset(10.6, -134.7),
      .7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(4, -126),
      3.4,
      Paint()..color = const Color(0xFFE99C8D).withValues(alpha: .65),
    );
    canvas.drawArc(
      const Rect.fromLTWH(8, -130, 11, 8),
      .15,
      1.4,
      false,
      Paint()
        ..color = atithiNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.restore();
  }

  void _shoe(Canvas c, Offset p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx - 8, p.dy - 3, 17, 8),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx - 8, p.dy - 3, 17, 8),
        const Radius.circular(4),
      ),
      Paint()
        ..color = atithiNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => oldDelegate.t != t;
}
