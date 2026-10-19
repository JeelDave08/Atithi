import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'splash_painter.dart';

/// Plays the vector hotel arrival scene while checking the existing session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.currentUser, super.key});

  final Future<String?> Function() currentUser;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _completionDelay;
  bool _sessionChecked = false;
  bool _animationFinished = false;
  bool _didNavigate = false;
  bool _started = false;
  bool _reducedMotion = false;
  bool _showStatusBar = false;
  String? _user;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addStatusListener(_onAnimationStatus);

    // Start session lookup at the same time as the entrance animation.
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _hideStatusBar();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _controller.value = 1;
      _completionDelay = Timer(const Duration(milliseconds: 1200), () {
        _finishAnimation();
      });
    } else {
      _controller.forward();
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _animationFinished ||
        _reducedMotion) {
      return;
    }
    // The full logo settles by t=7.8s; leave it visible for roughly 0.8s.
    _completionDelay = Timer(
      const Duration(milliseconds: 800),
      _finishAnimation,
    );
  }

  void _finishAnimation() {
    if (!mounted || _animationFinished) return;
    _animationFinished = true;
    _navigateIfReady();
  }

  void _skip() {
    if (_animationFinished) return;
    _completionDelay?.cancel();
    _controller.stop();
    _controller.value = 1;
    _finishAnimation();
  }

  void _navigateIfReady() {
    if (!_sessionChecked || !_animationFinished || _didNavigate || !mounted) {
      return;
    }
    _didNavigate = true;
    context.go(_user == null ? '/auth' : '/home');
  }

  void _hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0B2447),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _showLogoStatusBar() {
    if (_showStatusBar) return;
    _showStatusBar = true;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFBF6EC),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFBF6EC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B2447),
    body: LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: SplashPainter(animation: _controller),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          ),
          builder: (context, scene) {
            if (_controller.value >= .65) _showLogoStatusBar();
            final skipVisible =
                _controller.value >= .125 && !_animationFinished;
            return Stack(
              fit: StackFit.expand,
              children: [
                scene!,
                if (skipVisible)
                  Positioned(
                    top: 12,
                    right: 14,
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: .6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Skip', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
  );

  @override
  void dispose() {
    _completionDelay?.cancel();
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
