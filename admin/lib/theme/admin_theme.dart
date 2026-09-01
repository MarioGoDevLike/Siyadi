import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin visual tokens — dark ops console, forest accents (not purple).
abstract final class AdminColors {
  static const Color bark = Color(0xFF101612);
  static const Color canopy = Color(0xFF2F5D3A);
  static const Color canopySoft = Color(0xFF4A7A55);
  static const Color brass = Color(0xFFB08D57);
  static const Color panel = Color(0xFF18201B);
  static const Color panelElevated = Color(0xFF212B24);
  static const Color mist = Color(0xFFD7DDD6);
  static const Color danger = Color(0xFFC45C5C);
  static const Color ok = Color(0xFF5B9A6A);
}

ThemeData buildAdminTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AdminColors.canopySoft,
      secondary: AdminColors.brass,
      surface: AdminColors.panel,
      error: AdminColors.danger,
      onPrimary: AdminColors.mist,
      onSurface: AdminColors.mist,
    ),
    scaffoldBackgroundColor: AdminColors.bark,
  );

  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansTextTheme(base.textTheme).apply(
      bodyColor: AdminColors.mist,
      displayColor: AdminColors.mist,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AdminColors.panel,
      foregroundColor: AdminColors.mist,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AdminColors.panelElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AdminColors.panelElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AdminColors.panel,
      selectedIconTheme: IconThemeData(color: AdminColors.brass),
      selectedLabelTextStyle: TextStyle(color: AdminColors.brass),
      unselectedIconTheme: IconThemeData(color: AdminColors.mist),
    ),
  );
}
