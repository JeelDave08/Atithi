import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class Palette {
  static const navy = Color(0xFF0B2447),
      gold = Color(0xFFE2BF73),
      darkGold = Color(0xFFA8802F);
  static const cream = Color(0xFFFBF6EC),
      sand = Color(0xFFEBDDBB),
      mutedBlue = Color(0xFF7C8BA8);
  static const slate = Color(0xFF3A4F73),
      grey = Color(0xFF6B6F7A),
      body = Color(0xFF4A4F5C);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Palette.navy,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.navy,
      primary: Palette.navy,
      secondary: Palette.gold,
      surface: Palette.cream,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(),
  );
}
