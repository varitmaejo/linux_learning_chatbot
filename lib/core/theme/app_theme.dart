import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  // Color Schemes
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: Color(0xFF2E7D32), // เขียวเข้ม (Linux green)
    primaryVariant: Color(0xFF1B5E20),
    secondary: Color(0xFF4CAF50), // เขียวสว่าง
    secondaryVariant: Color(0xFF388E3C),
    surface: Color(0xFFFAFAFA),
    background: Color(0xFFFFFFFF),
    error: Color(0xFFD32F2F),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF212121),
    onBackground: Color(0xFF212121),
    onError: Color(0xFFFFFFFF),
    brightness: Brightness.light,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF4CAF50),
    primaryVariant: Color(0xFF2E7D32),
    secondary: Color(0xFF81C784),
    secondaryVariant: Color(0xFF4CAF50),
    surface: Color(0xFF121212),
    background: Color(0xFF000000),
    error: Color(0xFFCF6679),
    onPrimary: Color(0xFF000000),
    onSecondary: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
    brightness: Brightness.dark,
  );

  // Custom Colors
  static const Color terminalBackground = Color(0xFF0D1117);
  static const Color terminalText = Color(0xFF58a6ff);
  static const Color terminalPrompt = Color(0xFF7c3aed);
  static const Color commandColor = Color(0xFF79dafa);
  static const Color successColor = Color(0xFF00C851);
  static const Color warningColor = Color(0xFFffbb33);
  static const Color infoColor = Color(0xFF33b5e5);

  // Thai-friendly TextTheme
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: GoogleFonts.sarabun(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        color: colorScheme.onBackground,
      ),
      displayMedium: GoogleFonts.sarabun(
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        color: colorScheme.onBackground,
      ),
      displaySmall: GoogleFonts.sarabun(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: colorScheme.onBackground,
      ),
      headlineMedium: GoogleFonts.sarabun(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onBackground,
      ),
      headlineSmall: GoogleFonts.sarabun(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: colorScheme.onBackground,
      ),
      titleLarge: GoogleFonts.sarabun(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onBackground,
      ),
      titleMedium: GoogleFonts.sarabun(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onBackground,
      ),
      titleSmall: GoogleFonts.sarabun(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onBackground,
      ),
      bodyLarge: GoogleFonts.sarabun(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onBackground,
      ),
      bodyMedium: GoogleFonts.sarabun(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onBackground,
      ),
      labelLarge: GoogleFonts.sarabun(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
        color: colorScheme.onBackground,
      ),
      bodySmall: GoogleFonts.sarabun(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onBackground,
      ),
      labelSmall: GoogleFonts.sarabun(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        color: colorScheme.onBackground,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: _lightColorScheme,
      textTheme: _buildTextTheme(_lightColorScheme),
      useMaterial3: true,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.sarabun(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _lightColorScheme.onPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: AppConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(0, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _lightColorScheme.surface,
        selectedItemColor: _lightColorScheme.primary,
        unselectedItemColor: _lightColorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.sarabun(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.sarabun(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColorScheme.secondary,
        foregroundColor: _lightColorScheme.onSecondary,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _lightColorScheme.surface,
        brightness: Brightness.light,
        labelStyle: GoogleFonts.sarabun(
          fontSize: 14,
          color: _lightColorScheme.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.sarabun(
          fontSize: 14,
          color: _lightColorScheme.onSecondary,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        titleTextStyle: GoogleFonts.sarabun(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _lightColorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.sarabun(
          fontSize: 16,
          color: _lightColorScheme.onSurface,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _lightColorScheme.primary,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: _darkColorScheme,
      textTheme: _buildTextTheme(_darkColorScheme),
      useMaterial3: true,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.sarabun(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _darkColorScheme.onSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: AppConstants.cardElevation,
        color: _darkColorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(0, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _darkColorScheme.surface,
        selectedItemColor: _darkColorScheme.primary,
        unselectedItemColor: _darkColorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.sarabun(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.sarabun(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColorScheme.secondary,
        foregroundColor: _darkColorScheme.onSecondary,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _darkColorScheme.surface,
        brightness: Brightness.dark,
        labelStyle: GoogleFonts.sarabun(
          fontSize: 14,
          color: _darkColorScheme.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.sarabun(
          fontSize: 14,
          color: _darkColorScheme.onSecondary,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: _darkColorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        titleTextStyle: GoogleFonts.sarabun(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _darkColorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.sarabun(
          fontSize: 16,
          color: _darkColorScheme.onSurface,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _darkColorScheme.primary,
      ),
    );
  }

  // Terminal Theme
  static ThemeData get terminalTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: terminalBackground,
      textTheme: TextTheme(
        bodyMedium: GoogleFonts.firaCode(
          fontSize: 14,
          color: terminalText,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // Custom Text Styles
  static TextStyle get terminalTextStyle => GoogleFonts.firaCode(
    fontSize: 14,
    color: terminalText,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get terminalPromptStyle => GoogleFonts.firaCode(
    fontSize: 14,
    color: terminalPrompt,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get commandStyle => GoogleFonts.firaCode(
    fontSize: 14,
    color: commandColor,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get successTextStyle => GoogleFonts.sarabun(
    fontSize: 16,
    color: successColor,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get warningTextStyle => GoogleFonts.sarabun(
    fontSize: 16,
    color: warningColor,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get errorTextStyle => GoogleFonts.sarabun(
    fontSize: 16,
    color: Colors.red,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get infoTextStyle => GoogleFonts.sarabun(
    fontSize: 16,
    color: infoColor,
    fontWeight: FontWeight.w500,
  );

  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF4CAF50),
    ],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4CAF50),
      Color(0xFF81C784),
    ],
  );

  // Shadow Styles
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}