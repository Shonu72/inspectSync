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
      
      // Typography: Manrope for display/headlines, Inter for body/labels
      textTheme: TextTheme(
        displayMedium: GoogleFonts.manrope(
          fontSize: 44, // 2.75rem
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: 0.5,
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
          fontSize: 14, // 0.875rem
          fontWeight: FontWeight.w400,
          color: onSurface, // Keep contrast high for outdoor use
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, // 0.6875rem
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
      ),

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
}
