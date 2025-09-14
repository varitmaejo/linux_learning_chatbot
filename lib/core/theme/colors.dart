import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - Thai-inspired blue
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep blue
  static const Color primaryLight = Color(0xFF3B82F6); // Light blue
  static const Color primaryDark = Color(0xFF1E40AF); // Darker blue

  // Accent Colors - Thai gold/orange
  static const Color accentColor = Color(0xFFFF6B35); // Thai orange
  static const Color accentLight = Color(0xFFFF8A65); // Light orange
  static const Color accentDark = Color(0xFFE55100); // Dark orange

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF10B981); // Green for success
  static const Color secondaryLight = Color(0xFF34D399); // Light green
  static const Color secondaryDark = Color(0xFF059669); // Dark green

  // Background Colors
  static const Color lightBackground = Color(0xFFF8FAFC); // Very light blue-gray
  static const Color darkBackground = Color(0xFF0F172A); // Very dark blue
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color darkSurface = Color(0xFF1E293B); // Dark blue-gray

  // Text Colors
  static const Color darkText = Color(0xFF1E293B); // Dark blue-gray for light theme
  static const Color lightText = Color(0xFFF1F5F9); // Light gray for dark theme
  static const Color mutedText = Color(0xFF64748B); // Muted gray

  // Status Colors
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // Terminal Colors (for virtual terminal)
  static const Color terminalBackground = Color(0xFF1A1B26); // Dark terminal bg
  static const Color terminalText = Color(0xFF9AA5CE); // Terminal text
  static const Color terminalCursor = Color(0xFF7AA2F7); // Terminal cursor
  static const Color terminalSelection = Color(0xFF364A82); // Selection

  // Linux Command Category Colors
  static const Color fileCommandColor = Color(0xFF8B5CF6); // Purple for file commands
  static const Color systemCommandColor = Color(0xFFEF4444); // Red for system commands
  static const Color networkCommandColor = Color(0xFF06B6D4); // Cyan for network commands
  static const Color textCommandColor = Color(0xFF10B981); // Green for text commands
  static const Color securityCommandColor = Color(0xFFF59E0B); // Orange for security commands

  // Difficulty Level Colors
  static const Color beginnerColor = Color(0xFF10B981); // Green
  static const Color intermediateColor = Color(0xFF3B82F6); // Blue
  static const Color advancedColor = Color(0xFFF59E0B); // Orange
  static const Color expertColor = Color(0xFFEF4444); // Red

  // Achievement Colors
  static const Color bronzeColor = Color(0xFFCD7F32); // Bronze
  static const Color silverColor = Color(0xFFC0C0C0); // Silver
  static const Color goldColor = Color(0xFFFFD700); // Gold
  static const Color diamondColor = Color(0xFFB9F2FF); // Diamond

  // Chat Message Colors
  static const Color userMessageColor = Color(0xFF3B82F6); // Blue for user messages
  static const Color botMessageColor = Color(0xFFF1F5F9); // Light gray for bot messages
  static const Color systemMessageColor = Color(0xFFF59E0B); // Orange for system messages

  // Progress Colors
  static const Color progressBackground = Color(0xFFE2E8F0); // Light gray
  static const Color progressFill = Color(0xFF3B82F6); // Blue

  // Border Colors
  static const Color lightBorder = Color(0xFFE2E8F0); // Light border
  static const Color darkBorder = Color(0xFF475569); // Dark border

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF1E3A8A),
    Color(0xFF3B82F6),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFFF6B35),
    Color(0xFFFF8A65),
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF34D399),
  ];

  static const List<Color> terminalGradient = [
    Color(0xFF1A1B26),
    Color(0xFF24283B),
  ];

  // Material Color Swatches
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF1E3A8A,
    <int, Color>{
      50: Color(0xFFEFF6FF),
      100: Color(0xFFDBEAFE),
      200: Color(0xFFBFDBFE),
      300: Color(0xFF93C5FD),
      400: Color(0xFF60A5FA),
      500: Color(0xFF3B82F6),
      600: Color(0xFF2563EB),
      700: Color(0xFF1D4ED8),
      800: Color(0xFF1E40AF),
      900: Color(0xFF1E3A8A),
    },
  );

  static const MaterialColor accentSwatch = MaterialColor(
    0xFFFF6B35,
    <int, Color>{
      50: Color(0xFFFFF3E0),
      100: Color(0xFFFFE0B2),
      200: Color(0xFFFFCC80),
      300: Color(0xFFFFB74D),
      400: Color(0xFFFFA726),
      500: Color(0xFFFF9800),
      600: Color(0xFFFF8F00),
      700: Color(0xFFFF8A65),
      800: Color(0xFFFF7043),
      900: Color(0xFFFF6B35),
    },
  );

  // Helper methods for color variations
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Get color by command category
  static Color getCommandCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'file_management':
        return fileCommandColor;
      case 'system_administration':
        return systemCommandColor;
      case 'networking':
        return networkCommandColor;
      case 'text_processing':
        return textCommandColor;
      case 'security':
        return securityCommandColor;
      case 'package_management':
        return primaryColor;
      case 'shell_scripting':
        return accentColor;
      default:
        return mutedText;
    }
  }

  // Get color by difficulty level
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return beginnerColor;
      case 'intermediate':
        return intermediateColor;
      case 'advanced':
        return advancedColor;
      case 'expert':
        return expertColor;
      default:
        return mutedText;
    }
  }

  // Get achievement color by level
  static Color getAchievementColor(String level) {
    switch (level.toLowerCase()) {
      case 'bronze':
        return bronzeColor;
      case 'silver':
        return silverColor;
      case 'gold':
        return goldColor;
      case 'diamond':
        return diamondColor;
      default:
        return mutedText;
    }
  }

  // Get gradient by type
  static List<Color> getGradient(String type) {
    switch (type.toLowerCase()) {
      case 'primary':
        return primaryGradient;
      case 'accent':
        return accentGradient;
      case 'success':
        return successGradient;
      case 'terminal':
        return terminalGradient;
      default:
        return primaryGradient;
    }
  }
}