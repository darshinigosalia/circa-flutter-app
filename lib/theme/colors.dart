import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CircaColors {
  static const Color bg = Color(0xFFF4F3F0);
  static const Color paper = Color(0xFFFFFEFB);
  static const Color ink = Color(0xFF2C2C29);
  static const Color muted = Color(0xFF8C8C85);
  static const Color line = Color(0xFFDCDBD4);
  static const Color accent = Color(0xFF5B7C6F);
  static const Color accentDeep = Color(0xFF37534A);
  static const Color accentSoft = Color(0xFFE7ECE8);
  static const Color clay = Color(0xFF8A5A3C);
  static const Color apricot = Color(0xFFF4E7D3);

  // Typography - Hanken Grotesk ONLY
  static TextStyle eyebrow = GoogleFonts.getFont('Hanken Grotesk',
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 1.6,
    color: accent,
  );

  static TextStyle title = GoogleFonts.getFont('Hanken Grotesk',
    fontWeight: FontWeight.w600,
    fontSize: 27,
    letterSpacing: -0.3,
    color: ink,
    height: 1.18,
  );

  static TextStyle helpText = GoogleFonts.getFont('Hanken Grotesk',
    fontWeight: FontWeight.w400,
    fontSize: 15,
    color: muted,
    height: 1.55,
  );

  static TextStyle button = GoogleFonts.getFont('Hanken Grotesk',
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.getTextTheme('Hanken Grotesk');
    return ThemeData(
      primaryColor: accent,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: clay,
        surface: paper,
        onPrimary: Colors.white,
        onSurface: ink,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: title,
        bodyLarge: helpText.copyWith(color: ink),
        bodyMedium: helpText,
        labelSmall: eyebrow,
        labelLarge: button,
      ),
      useMaterial3: true,
    );
  }
}
