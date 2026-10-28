import 'package:flutter/material.dart';
import 'app_constants.dart';

class AppTheme {
  // Main Theme (Modern Dark Safety Aesthetic)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.bgDark,
      primaryColor: AppConstants.primaryViolet,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryViolet,
        secondary: AppConstants.safeGreen,
        error: AppConstants.emergencyRed,
        surface: AppConstants.bgCard,
        onPrimary: Colors.white,
        onSurface: AppConstants.textLight,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.bgDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppConstants.textLight),
        titleTextStyle: TextStyle(
          color: AppConstants.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.bgCard,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        prefixIconColor: AppConstants.primaryLight,
        suffixIconColor: AppConstants.primaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppConstants.primaryViolet, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppConstants.emergencyRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppConstants.emergencyRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryViolet,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryLight,
          side: const BorderSide(color: AppConstants.primaryViolet, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.bgCardLight,
        contentTextStyle: const TextStyle(color: AppConstants.textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Custom reusable BoxDecorations (demonstrating syllabus styling requirements)
  static BoxDecoration glassCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: AppConstants.bgCard.withOpacity(0.92),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: borderColor ?? const Color(0xFF334155),
        width: 1.2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration gradientButtonDecoration({
    required List<Color> colors,
    double radius = 16,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: colors.first.withOpacity(0.4),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration sosButtonDecoration({bool isPressed = false}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [
          Color(0xFFFB7185),
          AppConstants.emergencyRed,
          Color(0xFF9F1239),
        ],
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
      ),
      boxShadow: [
        BoxShadow(
          color: AppConstants.emergencyRed.withOpacity(isPressed ? 0.8 : 0.45),
          blurRadius: isPressed ? 36 : 24,
          spreadRadius: isPressed ? 8 : 4,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
