import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2E7D32); // Green สำหรับ Linux theme
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF1976D2); // Blue for terminal
  static const Color secondaryLight = Color(0xFF63A4FF);
  static const Color secondaryDark = Color(0xFF004BA0);

  // Accent Colors
  static const Color accentColor = Color(0xFFFF9800); // Orange for highlights
  static const Color accentLight = Color(0xFFFFC947);
  static const Color accentDark = Color(0xFFC66900);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF333333);

  // Text Colors
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);
  static const Color mutedText = Color(0xFFBDBDBD);
  static const Color darkText = Color(0xFFE0E0E0);

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Terminal Colors (Linux theme)
  static const Color terminalBackground = Color(0xFF000000);
  static const Color terminalGreen = Color(0xFF00FF00);
  static const Color terminalText = Color(0xFFFFFFFF);
  static const Color terminalPrompt = Color(0xFF00FF00);
  static const Color terminalCommand = Color(0xFF87CEEB);
  static const Color terminalError = Color(0xFFFF6B6B);
  static const Color terminalSuccess = Color(0xFF4ECDC4);

  // Chat Bubble Colors
  static const Color userBubble = Color(0xFF2E7D32);
  static const Color botBubble = Color(0xFFE8F5E8);
  static const Color userBubbleText = Color(0xFFFFFFFF);
  static const Color botBubbleText = Color(0xFF2E7D32);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x1F000000);
  static const Color shadowDark = Color(0x3F000000);

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFBDBDBD);

  // Chip Colors
  static const Color chipBackground = Color(0xFFE8F5E8);
  static const Color chipBorder = Color(0xFF81C784);

  // Progress Colors
  static const Color progressBackground = Color(0xFFE0E0E0);
  static const Color progressActive = Color(0xFF4CAF50);

  // Achievement Colors
  static const Color goldColor = Color(0xFFFFD700);
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color bronzeColor = Color(0xFFCD7F32);

  // Difficulty Level Colors
  static const Color beginnerColor = Color(0xFF4CAF50);
  static const Color intermediateColor = Color(0xFFFF9800);
  static const Color advancedColor = Color(0xFFF44336);
  static const Color expertColor = Color(0xFF9C27B0);

  // Command Category Colors
  static const Color fileSystemColor = Color(0xFF2196F3);
  static const Color textProcessingColor = Color(0xFF4CAF50);
  static const Color systemInfoColor = Color(0xFFFF9800);
  static const Color networkColor = Color(0xFF9C27B0);
  static const Color processColor = Color(0xFF607D8B);
  static const Color permissionColor = Color(0xFFE91E63);

  // Learning Path Colors
  static const Color pathBeginnerColor = Color(0xFFE8F5E8);
  static const Color pathIntermediateColor = Color(0xFFFFF3E0);
  static const Color pathAdvancedColor = Color(0xFFFFEBEE);

  // Voice/Audio Colors
  static const Color recordingColor = Color(0xFFE53935);
  static const Color playingColor = Color(0xFF1E88E5);
  static const Color pausedColor = Color(0xFFFB8C00);

  // Shimmer Colors
  static Color shimmerBase = Colors.grey[300]!;
  static Color shimmerHighlight = Colors.grey[100]!;

  // Utility Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  // Theme-specific color getters
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : primaryText;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : backgroundColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : surfaceColor;
  }
}