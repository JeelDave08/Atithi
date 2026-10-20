// lib/splash/atithi_splash.dart
// Flutter port of "Atithi-Splash-v2.html"
// Same class + constructor as before: AtithiSplashScreen(onFinished: ...)
// pubspec.yaml ma add karo:  google_fonts: ^6.2.1

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'auth/auth_repository.dart';
import 'splash/atithi_splash.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const AtithiApp());
}

class AtithiApp extends StatelessWidget {
  const AtithiApp({
    this.authRepository = const UnconfiguredAuthRepository(),
    super.key,
  });

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Atithi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.gold,
          surface: AppColors.cream,
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
      home: AtithiSplashScreen(
        onFinished: () {
          _navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => LoginScreen(authRepository: authRepository),
            ),
          );
        },
      ),
    );
  }
}
