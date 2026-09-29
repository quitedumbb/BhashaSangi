import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassroomColors {
  ClassroomColors._();

  // Primary warm palette
  static const Color creamBackground = Color(0xFFFBF8F2);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color warmParchment = Color(0xFFF4ECE1);
  static const Color lightSandalwood = Color(0xFFEFE4D3);

  // Brand accents
  static const Color terracotta = Color(0xFFB44B2C);
  static const Color terracottaDark = Color(0xFF8E371E);
  static const Color terracottaLight = Color(0xFFFBECE7);

  static const Color marigold = Color(0xFFD97706);
  static const Color marigoldLight = Color(0xFFFEF3C7);
  static const Color marigoldDark = Color(0xFFB45309);

  static const Color earthySage = Color(0xFF386641);
  static const Color sageLight = Color(0xFFE7F0E9);
  static const Color sageDark = Color(0xFF24442B);

  // Typography
  static const Color textDark = Color(0xFF2C1E17);
  static const Color textMuted = Color(0xFF6B584E);
  static const Color textSubtle = Color(0xFF968379);

  // Borders & Dividers
  static const Color borderWarm = Color(0xFFE5DACD);
  static const Color borderSubtle = Color(0xFFEFE6DB);

  // Chalkboard accent (for classroom notes & badges)
  static const Color slateChalkboard = Color(0xFF2E3E37);
  static const Color chalkWhite = Color(0xFFF6F8F6);

  // Status colors
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color errorRust = Color(0xFFC53030);
  static const Color infoBlue = Color(0xFF2563EB);
}

class ClassroomTheme {
  /// Distinctive typeface for highlighted elements: badges, pills, callouts, and key tags
  static TextStyle highlightFont({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.lexend(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.notoSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ClassroomColors.creamBackground,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: ClassroomColors.terracotta,
        onPrimary: Colors.white,
        primaryContainer: ClassroomColors.terracottaLight,
        onPrimaryContainer: ClassroomColors.terracottaDark,
        secondary: ClassroomColors.marigold,
        onSecondary: Colors.white,
        secondaryContainer: ClassroomColors.marigoldLight,
        onSecondaryContainer: ClassroomColors.marigoldDark,
        tertiary: ClassroomColors.earthySage,
        onTertiary: Colors.white,
        tertiaryContainer: ClassroomColors.sageLight,
        onTertiaryContainer: ClassroomColors.sageDark,
        surface: ClassroomColors.cardSurface,
        onSurface: ClassroomColors.textDark,
        error: ClassroomColors.errorRust,
        onError: Colors.white,
        outline: ClassroomColors.borderWarm,
        outlineVariant: ClassroomColors.borderSubtle,
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: ClassroomColors.textDark,
          height: 1.25,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: ClassroomColors.textDark,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ClassroomColors.textDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ClassroomColors.textDark,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          color: ClassroomColors.textDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          color: ClassroomColors.textMuted,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12,
          color: ClassroomColors.textSubtle,
        ),
        labelLarge: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: ClassroomColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ClassroomColors.borderWarm, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ClassroomColors.creamBackground,
        foregroundColor: ClassroomColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: ClassroomColors.textDark,
        ),
        iconTheme: const IconThemeData(color: ClassroomColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ClassroomColors.terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ClassroomColors.terracottaDark,
          side: const BorderSide(color: ClassroomColors.terracotta, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClassroomColors.borderWarm, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClassroomColors.borderWarm, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClassroomColors.terracotta, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClassroomColors.errorRust, width: 1.5),
        ),
        hintStyle: GoogleFonts.notoSans(
          color: ClassroomColors.textSubtle,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ClassroomColors.borderWarm,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
