import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Fondo ambientado estilo Glassmorphism de alto rendimiento (Zero-Lag).
///
/// Utiliza gradientes radiales nativos de una sola pasada (single-pass) para simular
/// la iluminación de orbes de neón difusos sin requerir `BackdropFilter(sigma: 100)`,
/// eliminando por completo el sobrecalentamiento y la pérdida de FPS en smartphones.
class GlassBackground extends StatelessWidget {
  final Widget? child;

  const GlassBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Fondo base suave
        Positioned.fill(
          child: Container(
            color: const Color(0xFFF2F5FA),
          ),
        ),

        // 2. Orbe Superior Izquierdo (Cyan / Azul Eléctrico)
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kCyan.withValues(alpha: 0.22),
                  kBlue.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // 3. Orbe Central Derecho (Azul Profundo / Navy)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.32,
          right: -120,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kBlue.withValues(alpha: 0.15),
                  kNavy.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
        ),

        // 4. Orbe Inferior Izquierdo (Celeste Brillante)
        Positioned(
          bottom: -80,
          left: -60,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF38BDF8).withValues(alpha: 0.18),
                  kBlue.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.40, 1.0],
              ),
            ),
          ),
        ),

        // 5. Contenido de la pantalla (opcional si se usa como fondo directo en un Stack)
        if (child != null)
          Positioned.fill(
            child: child!,
          ),
      ],
    );
  }
}
