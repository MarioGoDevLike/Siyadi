import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final baseText = GoogleFonts.figtreeTextTheme();
    final display = GoogleFonts.syne;

    final colorScheme = ColorScheme.light(
      primary: AppColors.canopy,
      onPrimary: AppColors.snow,
      primaryContainer: AppColors.canopySoft,
      onPrimaryContainer: AppColors.fog,
      secondary: AppColors.brass,
      onSecondary: AppColors.bark,
      secondaryContainer: AppColors.brassLight.withValues(alpha: 0.28),
      onSecondaryContainer: AppColors.bark,
      tertiary: AppColors.clay,
      surface: AppColors.fog,
      onSurface: AppColors.bark,
      onSurfaceVariant: AppColors.clay,
      outline: AppColors.mistDeep,
      error: AppColors.danger,
      onError: AppColors.snow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.mist,
      textTheme: baseText
          .copyWith(
            displayLarge: display(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: AppColors.bark,
              height: 1.05,
            ),
            displayMedium: display(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: AppColors.bark,
            ),
            headlineLarge: display(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.bark,
            ),
            headlineMedium: display(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.bark,
            ),
            titleLarge: display(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.bark,
            ),
            titleMedium: GoogleFonts.figtree(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.bark,
            ),
            bodyLarge: GoogleFonts.figtree(
              fontSize: 16,
              height: 1.45,
              color: AppColors.bark,
            ),
            bodyMedium: GoogleFonts.figtree(
              fontSize: 14,
              height: 1.4,
              color: AppColors.bark,
            ),
            labelLarge: GoogleFonts.figtree(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          )
          .apply(
            bodyColor: AppColors.bark,
            displayColor: AppColors.bark,
          ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.bark,
        titleTextStyle: display(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.bark,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.snow.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.mistDeep.withValues(alpha: 0.8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.canopy,
          foregroundColor: AppColors.snow,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.figtree(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.canopy,
          side: const BorderSide(color: AppColors.canopySoft, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brass,
        foregroundColor: AppColors.bark,
        elevation: 2,
        focusElevation: 3,
        highlightElevation: 3,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.fog,
        selectedItemColor: AppColors.canopy,
        unselectedItemColor: AppColors.clay,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.fog,
        indicatorColor: AppColors.canopy.withValues(alpha: 0.12),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.figtree(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.canopy : AppColors.clay,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.canopy : AppColors.clay,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.mistDeep.withValues(alpha: 0.9),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.snow.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mistDeep),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mistDeep),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.canopy, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bark,
        contentTextStyle: GoogleFonts.figtree(color: AppColors.fog),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
