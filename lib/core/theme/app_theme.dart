import 'package:flutter/material.dart';

/// App-inspired theme with modern Material 3 design
/// Updated color scheme for light and dark modes
class AppTheme {
  // Light Mode Colors
  static const Color primaryBackgroundLight = Color(
    0xFFF5F5F5,
  ); // Light Gray (keep)
  static const Color secondaryBackgroundLight = Color(
    0xFFFFFFFF,
  ); // White (keep)
  static const Color primaryTextLight = Color(
    0xFF1E1E1E,
  ); // Deep Charcoal (Locus)
  static const Color secondaryTextLight = Color(
    0xFF757575,
  ); // Medium Gray (unchanged)
  static const Color accentLight = Color(
    0xFFF3742D,
  ); // PrimaryAccent (Bright Orange - Locus)
  static const Color actionLight = Color(
    0xFFF3742D,
  ); // ActionColor (Bright Orange - Locus)

  // Dark Mode Colors
  static const Color primaryBackgroundDark = Color(
    0xFF1E1E1E,
  ); // Deep Charcoal (Locus)
  static const Color secondaryBackgroundDark = Color(
    0xFF363636,
  ); // Derived Shade for card surfaces (dark)
  static const Color primaryTextDark = Color(0xFFFFFFFF); // Pure White (keep)
  static const Color secondaryTextDark = Color(
    0xFFBDBDBD,
  ); // Light Gray (unchanged)
  static const Color accentDark = Color(
    0xFFF3742D,
  ); // PrimaryAccent (Bright Orange - Locus)
  static const Color actionDark = Color(
    0xFFF3742D,
  ); // ActionColor (Bright Orange - Locus)

  // Error Color (same for both)
  static const Color errorColor = Color(0xFFD32F2F);

  // Surface Colors (can be adjusted)
  static const Color surfaceLight = primaryBackgroundLight;
  static const Color surfaceCard = secondaryBackgroundLight;
  static const Color surfaceDark = primaryBackgroundDark;

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: actionLight,
      onPrimary: primaryTextDark,
      secondary: accentLight,
      onSecondary: primaryTextLight,
      tertiary: accentLight,
      onTertiary: primaryTextLight,
      error: errorColor,
      onError: primaryTextLight,
      surface: primaryBackgroundLight,
      onSurface: primaryTextLight,
      surfaceContainerHighest: secondaryBackgroundLight,
      onSurfaceVariant: secondaryTextLight,
      outline: secondaryTextLight,
      outlineVariant: secondaryTextLight,
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: primaryTextLight,
      onInverseSurface: primaryBackgroundLight,
      inversePrimary: actionDark,
      surfaceTint: actionLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'System', // Using system font for compatibility
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: actionLight,
        foregroundColor: primaryTextDark,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: primaryTextDark, size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: secondaryBackgroundLight,
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: actionLight,
          foregroundColor: primaryTextLight,
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: actionLight,
          side: BorderSide(color: actionLight, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: actionLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: secondaryBackgroundLight,
        selectedItemColor: actionLight,
        unselectedItemColor: secondaryTextLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryBackgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryTextLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryTextLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: actionLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: secondaryTextLight, fontSize: 16),
        labelStyle: TextStyle(color: secondaryTextLight, fontSize: 16),
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: actionLight,
        foregroundColor: primaryTextLight,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: primaryTextLight, size: 24),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primaryTextLight,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryTextLight,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryTextLight,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryTextLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextLight,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextLight,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextLight,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryTextLight,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextLight,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryTextLight,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primaryTextLight,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryTextLight,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextLight,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextLight,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: secondaryTextLight,
          letterSpacing: 0.5,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryBackgroundLight,
        selectedColor: actionLight.withOpacity(0.12),
        labelStyle: TextStyle(color: primaryTextLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: secondaryTextLight,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: actionDark,
      onPrimary: primaryTextDark,
      secondary: accentDark,
      onSecondary: primaryTextDark,
      tertiary: accentDark,
      onTertiary: primaryTextDark,
      error: errorColor,
      onError: primaryTextDark,
      surface: primaryBackgroundDark,
      onSurface: primaryTextDark,
      surfaceContainerHighest: secondaryBackgroundDark,
      onSurfaceVariant: secondaryTextDark,
      outline: secondaryTextDark,
      outlineVariant: secondaryTextDark,
      shadow: Colors.black54,
      scrim: Colors.black87,
      inverseSurface: primaryTextDark,
      onInverseSurface: primaryBackgroundDark,
      inversePrimary: actionLight,
      surfaceTint: actionDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'System', // Using system font for compatibility
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBackgroundDark,
        foregroundColor: primaryTextDark,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: primaryTextDark, size: 24),
      ),
      cardTheme: CardThemeData(
        color: secondaryBackgroundDark,
        elevation: 3,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: actionDark,
          foregroundColor: primaryTextDark,
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: actionDark,
          side: BorderSide(color: actionDark, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: actionDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: secondaryBackgroundDark,
        selectedItemColor: actionDark,
        unselectedItemColor: secondaryTextDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryBackgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryTextDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryTextDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: actionDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: secondaryTextDark, fontSize: 16),
        labelStyle: TextStyle(color: secondaryTextDark, fontSize: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: actionDark,
        foregroundColor: primaryTextDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      iconTheme: IconThemeData(color: primaryTextDark, size: 24),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primaryTextDark,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextDark,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryTextDark,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextDark,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryTextDark,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primaryTextDark,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryTextDark,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextDark,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextDark,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: secondaryTextDark,
          letterSpacing: 0.5,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryBackgroundDark,
        selectedColor: actionDark.withOpacity(0.12),
        labelStyle: TextStyle(color: primaryTextDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: secondaryTextDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  /// Custom gradient for backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [actionLight, actionDark],
  );

  /// Custom gradient for cards
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondaryBackgroundLight, primaryBackgroundLight],
  );

  /// Success color palette
  static const Color successColor = accentLight;
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color successDark = Color(0xFF2E7D32);

  /// Warning color palette
  static const Color warningColor = accentLight;
  static const Color warningLight = Color(0xFFFFF3C4);
  static const Color warningDark = Color(0xFFE65100);

  /// Info color palette
  static const Color infoColor = actionLight;
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF0277BD);

  // Legacy color constants (updated to new values)
  static const Color appBlue = actionLight; // Bright Teal
  static const Color appLightBlue = actionDark; // Lighter Teal
  static const Color appAccent = accentLight; // Warm Gold
  static const Color appGold = accentDark; // Bright Gold
  static const Color appGrey = secondaryTextLight; // Medium Gray
  static const Color appLightGrey = primaryBackgroundLight; // Light Gray
  static const Color appDarkGrey = primaryTextLight; // Dark Slate
  static const Color appWhite = primaryTextDark; // Pure White
  static const Color appError = errorColor;
}
