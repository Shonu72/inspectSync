import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tactical Architect Colors
  static const Color primary = Color(0xFF005BBF);
  static const Color primaryContainer = Color(0xFF1A73E8);
  
  static const Color background = Color(0xFFF8FAFB); // surface
  static const Color surfaceContainer = Color(0xFFECEEEF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFD8DADB);
  static const Color surfaceBright = Color(0xFFF8FAFB);
  
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF414754);
  
  static const Color tertiary = Color(0xFF006D2A); // Success
  static const Color error = Color(0xFFBA1A1A); // Conflict
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const Color outlineVariant = Color(0xFFC1C6D6); // Ghost Border

  // Common Typography
  static TextTheme _buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayMedium: GoogleFonts.manrope(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.02,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
        letterSpacing: 0.05,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
    );
  }

  // ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      // Baseline color scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: Color(0xFF5B5F64),
        surface: background,
        surfaceContainer: surfaceContainer,
        surfaceContainerLowest: surfaceContainerLowest,
        error: error,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      ),
      scaffoldBackgroundColor: background,
      // Typography
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant),

      // Tactical Architect: No 1px lines rule / Tonal Layering
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer, // "surface_container_high" equivalent
        floatingLabelStyle: GoogleFonts.inter(color: primary, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // Explicitly no line
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // Explicitly no line
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // Explicitly no line
        ),
        errorStyle: const TextStyle(color: error),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, 
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48), // Large Touch Targets min 48dp
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // "radius lg (0.5rem)"
          ),
          elevation: 0, // Shadows removed in favor of color separation
        ),
      ),
    );
  }

  // Tactical Architect - The Obsidian Command
  static ThemeData get darkTheme {
    const Color darkPrimary = Color(0xFF6B92ED); // Softened from #85ADFF
    const Color darkPrimaryContainer = Color(0xFF5A84E6); // Softened from #6E9FFF
    const Color darkOnPrimary = Color(0xFF001B40); // Deepen text on button
    
    const Color darkSurface = Color(0xFF060E20);
    const Color darkSurfaceContainerLow = Color(0xFF091328);
    const Color darkSurfaceContainer = Color(0xFF0F1930);
    const Color darkSurfaceContainerHighest = Color(0xFF192540);
    const Color darkSurfaceContainerLowest = Color(0xFF0B1426); // Softened from #000000
    
    const Color darkOnSurface = Color(0xFFC0CAE3); // Softened from #DEE5FF
    const Color darkOutlineVariant = Color(0xFF40485D);

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: darkPrimaryContainer,
        secondary: Color(0xFF40485D),
        surface: darkSurface,
        surfaceContainerLow: darkSurfaceContainerLow,
        surfaceContainer: darkSurfaceContainer,
        surfaceContainerHighest: darkSurfaceContainerHighest,
        surfaceContainerLowest: darkSurfaceContainerLowest,
        error: error,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOutlineVariant, // Using outline variant as secondary text tone
        outlineVariant: darkOutlineVariant,
        surfaceTint: darkPrimary,
      ),
      scaffoldBackgroundColor: darkSurface,

      textTheme: _buildTextTheme(darkOnSurface, darkOutlineVariant),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainerLow, // Default state input
        floatingLabelStyle: GoogleFonts.inter(color: darkPrimary, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // Explicitly no line
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
          // Box shadow glow requirement will be handled at the widget level or globally via container since InputDecoration doesn't support boxShadow natively
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: error),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary, 
          foregroundColor: darkOnPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // md (0.375rem)
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
