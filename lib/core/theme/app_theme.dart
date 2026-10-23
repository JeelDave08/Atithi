import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

abstract final class Palette {
  static const navy = AppColors.navy,
      gold = AppColors.gold,
      darkGold = AppColors.darkGold;
  static const cream = AppColors.surface,
      sand = Color(0xFFE8D6AE),
      mutedBlue = AppColors.secondaryText;
  static const slate = AppColors.navy,
      grey = AppColors.secondaryText,
      body = AppColors.secondaryText;
}

abstract final class AppTheme {
  static ThemeData get light {
    final body = GoogleFonts.dmSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.gold,
        tertiary: AppColors.gold,
        surface: AppColors.surface,
        onSurface: AppColors.navy,
        onPrimary: AppColors.cream,
        onSecondary: AppColors.navy,
      ),
      textTheme: body.copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          textStyle: body.headlineLarge,
          color: AppColors.navy,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          textStyle: body.headlineMedium,
          color: AppColors.navy,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          textStyle: body.titleLarge,
          color: AppColors.navy,
        ),
        bodyMedium: body.bodyMedium?.copyWith(color: AppColors.secondaryText),
        bodyLarge: body.bodyLarge?.copyWith(color: AppColors.secondaryText),
        bodySmall: body.bodySmall?.copyWith(color: AppColors.secondaryText),
        titleMedium: body.titleMedium?.copyWith(color: AppColors.navy),
      ),
    );
  }
}
