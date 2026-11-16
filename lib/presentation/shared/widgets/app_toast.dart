import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

enum ToastType { info, warning, error, success }

/// Mensaje flotante con auténtico diseño Glassmorphic (vidrio esmerilado translúcido, gema de color y borde de cristal).
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.warning,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color gradStart;
    Color gradEnd;
    Color glowColor;
    Color tintColor;
    IconData icon;

    switch (type) {
      case ToastType.warning:
        gradStart = const Color(0xFFF59E0B);
        gradEnd   = const Color(0xFFD97706);
        glowColor = const Color(0xFFF59E0B);
        tintColor = const Color(0xFFFEF3C7);
        icon      = Icons.warning_amber_rounded;
        break;
      case ToastType.error:
        gradStart = const Color(0xFFEF4444);
        gradEnd   = const Color(0xFFDC2626);
        glowColor = const Color(0xFFEF4444);
        tintColor = const Color(0xFFFEE2E2);
        icon      = Icons.error_outline_rounded;
        break;
      case ToastType.success:
        gradStart = const Color(0xFF10B981);
        gradEnd   = const Color(0xFF059669);
        glowColor = const Color(0xFF10B981);
        tintColor = const Color(0xFFD1FAE5);
        icon      = Icons.check_circle_outline_rounded;
        break;
      case ToastType.info:
        gradStart = const Color(0xFF0EA5E9);
        gradEnd   = const Color(0xFF0284C7);
        glowColor = const Color(0xFF0284C7);
        tintColor = const Color(0xFFE0F2FE);
        icon      = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              // Resplandor difuso suave de color (glow de alerta)
              BoxShadow(
                color: glowColor.withValues(alpha: 0.20),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
              // Sombra física profunda de elevación
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              // Reflejo especular superior blanco
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 6,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  // Degradado de cristal blanco translúcido con leve refracción de tinte
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.94),
                      tintColor.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.82),
                    ],
                  ),
                  // Borde biselado de cristal templado
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Gema de ícono circular con degradado vibrante
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [gradStart, gradEnd],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.38),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 12),
                    // Mensaje tipográfico en azul marino de alta fidelidad
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Botón de cierre suave en cristal
                    GestureDetector(
                      onTap: () => messenger.hideCurrentSnackBar(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.warning);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.error);

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.info, duration: const Duration(milliseconds: 2000));
}
