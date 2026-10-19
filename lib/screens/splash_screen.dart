import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_repository.dart';
import 'login_screen.dart';

const _deepNavy = Color(0xFF172B46);
const _warmGold = Color(0xFFC7A15A);
const _ivory = Color(0xFFFAF8F0);

class AtithiSplashScreen extends StatefulWidget {
  const AtithiSplashScreen({
    this.authRepository = const UnconfiguredAuthRepository(),
    super.key,
  });

  final AuthRepository authRepository;

  @override
  State<AtithiSplashScreen> createState() => _AtithiSplashScreenState();
}

class _AtithiSplashScreenState extends State<AtithiSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _sequenceDuration = Duration(milliseconds: 4300);

  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _rings;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _shine;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;
  late final Animation<double> _quoteOpacity;
  late final Animation<Offset> _quoteOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _sequenceDuration)
      ..addStatusListener(_onAnimationStatus);
    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _rings = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.58, curve: Curves.easeInOutCubic),
    );
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.57, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.64, curve: Curves.easeOutCubic),
      ),
    );
    _shine = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.54, 0.88, curve: Curves.easeInOut),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.73, curve: Curves.easeOut),
    );
    _taglineOffset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(_taglineOpacity);
    _quoteOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 0.9, curve: Curves.easeOut),
    );
    _quoteOffset = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(_quoteOpacity);
    _controller.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authRepository: widget.authRepository),
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: _deepNavy,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: _deepNavy,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: _deepNavy,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: Scaffold(
        backgroundColor: _deepNavy,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoSize = [
                constraints.maxWidth * 0.82,
                constraints.maxHeight * 0.43,
                380.0,
              ].reduce((a, b) => a < b ? a : b);
              final artworkSize = logoSize * 1.12;

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: artworkSize,
                      height: artworkSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) => CustomPaint(
                                painter: _HospitalityRingsPainter(
                                  progress: _rings.value,
                                  glow: _glow.value,
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) => Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: ShaderMask(
                                    blendMode: BlendMode.srcATop,
                                    shaderCallback: (bounds) {
                                      final sweepX =
                                          -2.0 + (_shine.value * 4.0);
                                      return LinearGradient(
                                        begin: Alignment(sweepX, -1),
                                        end: Alignment(sweepX + 0.8, 1),
                                        colors: [
                                          Colors.transparent,
                                          _warmGold.withValues(alpha: 0.16),
                                          _ivory.withValues(alpha: 0.42),
                                          Colors.transparent,
                                        ],
                                        stops: const [0, 0.42, 0.5, 0.62],
                                      ).createShader(bounds);
                                    },
                                    child: Image.asset(
                                      'assets/images/atithi_logo_transparent.png',
                                      fit: BoxFit.contain,
                                      semanticLabel: 'Atithi — Better Stays. Happier Guests.',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: SlideTransition(
                        position: _taglineOffset,
                        child: const Text(
                          'Better Stays. Happier Guests.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _warmGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.7,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _quoteOpacity,
                      child: SlideTransition(
                        position: _quoteOffset,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Every stay deserves a warm welcome.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ivory,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HospitalityRingsPainter extends CustomPainter {
  const _HospitalityRingsPainter({required this.progress, required this.glow});

  final double progress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.46;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _warmGold.withValues(alpha: 0.3 * glow),
          _warmGold.withValues(alpha: 0.16 * glow),
          _warmGold.withValues(alpha: 0.035 * glow),
          Colors.transparent,
        ],
        stops: const [0, 0.28, 0.72, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 0.22);
    canvas.translate(-center.dx, -center.dy);

    for (var index = 0; index < 3; index++) {
      final ringRadius = radius * (0.66 + index * 0.17);
      final trackPaint = Paint()
        ..color = _warmGold.withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = index == 2 ? 0.8 : 1.0;
      canvas.drawCircle(center, ringRadius, trackPaint);

      if (progress > 0) {
        final arcPaint = Paint()
          ..color = _warmGold.withValues(alpha: 0.78 - index * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = index == 2 ? 1.1 : 1.35;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: ringRadius),
          -1.5708 + index * 0.85,
          progress * (4.2 + index * 0.48),
          false,
          arcPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HospitalityRingsPainter oldDelegate) =>
      progress != oldDelegate.progress || glow != oldDelegate.glow;
}
