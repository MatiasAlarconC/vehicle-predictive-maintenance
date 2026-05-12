import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores principal
  static const Color background = Color(0xFF080C18);
  static const Color backgroundSecondary = Color(0xFF0D1220);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF161E2E);
  static const Color primaryColor = Color(0xFF00D4FF);
  static const Color primaryDim = Color(0xFF0099BB);
  static const Color successColor = Color(0xFF00E676);
  static const Color warningColor = Color(0xFFFFAB00);
  static const Color dangerColor = Color(0xFFFF1744);
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color borderColor = Color(0xFF1E2A3A);

  // Gradientes reutilizables
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0070FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFAB00), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF080C18), Color(0xFF0D1525)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sombras con glow
  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 20,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.4),
          blurRadius: 40,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.05),
          blurRadius: 30,
          spreadRadius: 0,
        ),
      ];

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: warningColor,
      surface: surface,
      error: dangerColor,
      onPrimary: Colors.black,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.rajdhani(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.copyWith(
            bodyLarge: const TextStyle(color: textPrimary, fontSize: 16),
            bodyMedium: const TextStyle(color: textSecondary, fontSize: 14),
            bodySmall: const TextStyle(color: textSecondary, fontSize: 12),
          ),
    ).copyWith(
      displayLarge: GoogleFonts.rajdhani(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.rajdhani(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.rajdhani(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.3,
      ),
      titleMedium: GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
      labelLarge: GoogleFonts.rajdhani(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor.withValues(alpha: 0.8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryColor : textSecondary),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? primaryColor.withValues(alpha: 0.3)
              : surfaceElevated),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: GoogleFonts.inter(color: textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
