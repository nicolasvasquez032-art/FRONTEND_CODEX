import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Extensión para manejar los colores dinámicamente según el modo (Claro/Oscuro)
/// sin romper las pantallas que aún usan colores estáticos.
extension ThemeColorsExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Fondos
  Color get bg => isDark ? const Color(0xFF0B1120) : kBg;
  Color get surface => isDark ? const Color(0xFF1E293B) : Colors.white;
  
  // Textos
  Color get text => isDark ? Colors.white : kNavy;
  Color get textMuted => isDark ? const Color(0xFF94A3B8) : kMuted;
  
  // Bordes
  Color get line => isDark ? const Color(0xFF334155) : kLine;
  
  // Especiales
  Color get matchBg => isDark ? const Color(0xFF064E3B) : kMatchBg;
  Color get matchText => isDark ? const Color(0xFF34D399) : kMatchText;
}
