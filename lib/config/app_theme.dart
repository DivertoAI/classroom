import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color ink = Color(0xFF1C1A17);
  static const Color canvas = Color(0xFFF5F1EA);
  static const Color surface = Color(0xFFFFFBF4);
  static const Color wash = Color(0xFFE9F4F2);
  static const Color accent = Color(0xFF2F7A6B);
  static const Color accentWarm = Color(0xFFDF6B42);
  static const Color muted = Color(0xFF6F675D);
  static const Color border = Color(0xFFE3D2BF);
  static const Color shadow = Color(0x19000000);
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.accent,
        brightness: Brightness.light,
      ).copyWith(
        surface: AppPalette.surface,
        surfaceContainerHighest: AppPalette.wash,
        onSurface: AppPalette.ink,
        onSurfaceVariant: AppPalette.muted,
        secondary: AppPalette.accentWarm,
        outline: AppPalette.border,
        shadow: AppPalette.shadow,
      );

  final textTheme = GoogleFonts.spaceGroteskTextTheme().apply(
    bodyColor: AppPalette.ink,
    displayColor: AppPalette.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppPalette.canvas,
    iconTheme: const IconThemeData(color: AppPalette.ink),
  );
}
