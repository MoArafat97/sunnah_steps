// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Islamic-inspired color palette
  static const Color primaryTeal = Color(0xFF009688);
  static const Color goldenAccent = Color(0xFFF5C518);
  static const Color deepTeal = Color(0xFF00695C);
  static const Color lightTeal = Color(0xFF4DB6AC);

  // Priority colors (from user preferences)
  static const Color fardGreen = Color(0xFF4CAF50);
  static const Color recommendedPurple = Color(0xFF9C27B0);
  static const Color optionalOrange = Color(0xFFFF9800);

  // Background and surface colors
  static const Color backgroundOverlay = Color(0x4D000000); // 30% black overlay
  static const Color cardBackground = Color(0xFFFAFAFA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Text colors
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);
  static const Color lightText = Color(0xFFFFFFFF);

  // Asset paths removed to fix black screen issues

  // Border radius
  static const double cardRadius = 12.0;
  static const double buttonRadius = 12.0;
  static const double containerRadius = 16.0;

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // Golden border
  static Border get goldenBorder => Border.all(
    color: goldenAccent,
    width: 1.5,
  );

  // Theme data
  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.teal,
    primaryColor: primaryTeal,
    useMaterial3: true,

    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryTeal,
      foregroundColor: lightText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      color: cardBackground,
      shadowColor: Colors.black.withOpacity(0.1),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: lightText,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Drawer theme
    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceWhite,
      elevation: 8,
    ),

    // Text theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: primaryText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondaryText,
      ),
    ),
  );

  // Simple background container without images
  static Widget backgroundContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.shade50,
            Colors.white,
            Colors.teal.shade50,
          ],
        ),
      ),
      child: child,
    );
  }

  // Enhanced card decoration
  static BoxDecoration get enhancedCardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(cardRadius),
    border: goldenBorder,
    boxShadow: cardShadow,
  );

  // Simple card decoration without gold border (for habit library)
  static BoxDecoration get simpleCardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(
      color: Colors.grey.shade300,
      width: 1.0,
    ),
    boxShadow: cardShadow,
  );

  // Greeting text style (Islamic greeting)
  static const TextStyle greetingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );

  // Section header style
  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );
}
