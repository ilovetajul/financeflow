import 'package:flutter/material.dart';

class AppColors {
  static const bg          = Color(0xFF0A0E1A);
  static const surface     = Color(0xFF111827);
  static const card        = Color(0xFF141C2E);
  static const border      = Color(0x0FFFFFFF);
  static const gold        = Color(0xFFF4C55A);
  static const teal        = Color(0xFF38D9C0);
  static const rose        = Color(0xFFF4617A);
  static const purple      = Color(0xFF8B6FE8);
  static const blue        = Color(0xFF60A5FA);
  static const textPrimary = Color(0xFFF0F4FF);
  static const textMuted   = Color(0xFF8892A4);
  static const textDim     = Color(0xFF4A5568);

  static const gradGold = LinearGradient(
    colors: [Color(0xFFF4C55A), Color(0xFFE8A020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradTeal = LinearGradient(
    colors: [Color(0xFF38D9C0), Color(0xFF1BA8A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradRose = LinearGradient(
    colors: [Color(0xFFF4617A), Color(0xFFC0394F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradBalance = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF0D1B3E), Color(0xFF1A1040)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.teal,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, fontFamily: 'Syne',
      ),
      displayMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, fontFamily: 'Syne',
      ),
      titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, fontFamily: 'Syne',
      ),
      titleMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, fontFamily: 'Syne',
      ),
      bodyLarge: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 13, color: AppColors.textMuted),
      bodySmall: TextStyle(fontSize: 11, color: AppColors.textDim),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
