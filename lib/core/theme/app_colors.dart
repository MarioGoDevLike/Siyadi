import 'package:flutter/material.dart';

/// SIYADI visual tokens — forest field / dawn mist direction.
/// Deep olive structure, brass accents, cool mist surfaces.
abstract final class AppColors {
  static const Color mist = Color(0xFFEEF1EC);
  static const Color mistDeep = Color(0xFFE2E7DF);
  static const Color canopy = Color(0xFF1F3A2F);
  static const Color canopySoft = Color(0xFF2F5342);
  static const Color bark = Color(0xFF141A16);
  static const Color brass = Color(0xFFB08D4F);
  static const Color brassLight = Color(0xFFC9A96A);
  static const Color clay = Color(0xFF6B5A45);
  static const Color fog = Color(0xFFF7F8F5);
  static const Color snow = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFA63D3D);
  static const Color success = Color(0xFF3D6B4F);

  static const LinearGradient dawnWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF4F6F2),
      Color(0xFFE8EDE6),
      Color(0xFFDFE6DC),
    ],
  );

  static const LinearGradient canopyFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1F3A2F),
      Color(0xFF173028),
    ],
  );
}
