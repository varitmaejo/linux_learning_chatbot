import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.light,
    ),
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.lightBackground,

    // Typography
    textTheme: GoogleFonts.promptTextTheme().copyWith(
      displayLarge: GoogleFonts.prompt(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      displayMedium: GoogleFonts.prompt(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      displaySmall: GoogleFonts.prompt(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      headlineLarge: GoogleFonts.prompt(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      headlineMedium: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      headlineSmall: GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      titleLarge: GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      titleMedium: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      titleSmall: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      bodyLarge: GoogleFonts.prompt(
        fontSize: 16,
        color: AppColors.darkText,
      ),
      bodyMedium: GoogleFonts.prompt(
        fontSize: 14,
        color: AppColors.darkText,
      ),
      bodySmall: GoogleFonts.prompt(
        fontSize: 12,
        color: AppColors.darkText.withOpacity(0.7),
      ),
      labelLarge: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      labelMedium: GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      labelSmall: GoogleFonts.prompt(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText.withOpacity(0.7),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.prompt(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        textStyle: GoogleFonts.prompt(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: BorderSide(color: AppColors.primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.prompt(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: GoogleFonts.prompt(
        color: Colors.grey.shade600,
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentColor,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.dark,
    ),
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // Typography
    textTheme: GoogleFonts.promptTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.prompt(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      displayMedium: GoogleFonts.prompt(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      displaySmall: GoogleFonts.prompt(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      headlineLarge: GoogleFonts.prompt(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      headlineMedium: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
      headlineSmall: GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
      titleLarge: GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
      titleMedium: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
      titleSmall: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
      bodyLarge: GoogleFonts.prompt(
        fontSize: 16,
        color: AppColors.lightText,
      ),
      bodyMedium: GoogleFonts.prompt(
        fontSize: 14,
        color: AppColors.lightText,
      ),
      bodySmall: GoogleFonts.prompt(
        fontSize: 12,
        color: AppColors.lightText.withOpacity(0.7),
      ),
      labelLarge: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
      labelMedium: GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
      labelSmall: GoogleFonts.prompt(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText.withOpacity(0.7),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.darkSurface,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.prompt(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentColor,
        textStyle: GoogleFonts.prompt(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentColor,
        side: BorderSide(color: AppColors.accentColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.prompt(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: GoogleFonts.prompt(
        color: Colors.grey.shade400,
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentColor,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
  );
}