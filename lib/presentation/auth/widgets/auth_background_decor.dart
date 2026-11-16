import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Hero decorativo con la escultura 3D y elementos flotantes independientes.
class FloatingHeroDecor extends StatelessWidget {
  final Animation<double> floatAnimation;
  final bool disableAnimations;

  const FloatingHeroDecor({
    super.key,
    required this.floatAnimation,
    required this.disableAnimations,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      width: double.infinity,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: floatAnimation,
          builder: (context, child) {
            // Valor normalizado t entre 0.0 y 1.0
            final double t = disableAnimations ? 0.0 : floatAnimation.value;

            // Oscilación armónica suave compacta
            final double mainFloatY = disableAnimations
                ? 0.0
                : math.sin(t * math.pi * 2) * 6.0;
            final double mainDriftX = disableAnimations
                ? 0.0
                : math.cos(t * math.pi * 2) * 2.5;
            final double mainRotate = disableAnimations
                ? 0.0
                : math.sin(t * math.pi * 2) * 0.035; // ~2 grados

            // Desfase para los elementos secundarios
            final double userFloatY = disableAnimations
                ? 0.0
                : math.sin((t + 0.25) * math.pi * 2) * 5.0;
            final double userRotate = disableAnimations
                ? 0.0
                : math.cos((t + 0.25) * math.pi * 2) * 0.035;

            final double workFloatY = disableAnimations
                ? 0.0
                : math.sin((t + 0.60) * math.pi * 2) * 5.5;
            final double workRotate = disableAnimations
                ? 0.0
                : -math.sin((t + 0.60) * math.pi * 2) * 0.035;

            final double sphereFloatY = disableAnimations
                ? 0.0
                : math.cos((t + 0.80) * math.pi * 2) * 4.5;

            final double sparkleFloatY = disableAnimations
                ? 0.0
                : math.sin((t + 0.40) * math.pi * 2) * 3.5;
            final double sparkleOpacity = disableAnimations
                ? 0.9
                : (0.7 + (math.sin(t * math.pi * 2).abs() * 0.3)).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── Resplandor ambiental cian/azul detrás de la escultura ──
                Positioned(
                  child: Container(
                    width: 175,
                    height: 125,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kCyan.withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: kBlue.withValues(alpha: 0.16),
                          blurRadius: 55,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 1. Escultura 3D Central (Eslabones Azul Glaciar & Marino) ──
                Transform.translate(
                  offset: Offset(mainDriftX, mainFloatY),
                  child: Transform.rotate(
                    angle: mainRotate,
                    child: Image.asset(
                      'assets/images/talent_match_3d_chains.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),

                // ── 2. Tarjeta Flotante Izquierda: Avatar de Usuario ──
                Positioned(
                  left: 20,
                  top: 10,
                  child: Transform.translate(
                    offset: Offset(0, userFloatY),
                    child: Transform.rotate(
                      angle: userRotate,
                      child: const FloatingFrostedTile(
                        size: 44,
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: kBlue,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 3. Tarjeta Flotante Derecha: Maletín de Empleo ──
                Positioned(
                  right: 20,
                  bottom: 10,
                  child: Transform.translate(
                    offset: Offset(0, workFloatY),
                    child: Transform.rotate(
                      angle: workRotate,
                      child: const FloatingFrostedTile(
                        size: 44,
                        child: Icon(
                          Icons.business_center_outlined,
                          color: kBlue,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 4. Esfera Iridiscente Flotante Azul / Celeste ──
                Positioned(
                  right: 48,
                  top: 8,
                  child: Transform.translate(
                    offset: Offset(0, sphereFloatY),
                    child: const FloatingSphere(size: 15),
                  ),
                ),

                // ── 5. Destello 4 Puntas en Azul Cian ──
                Positioned(
                  left: 42,
                  bottom: 22,
                  child: Transform.translate(
                    offset: Offset(0, sparkleFloatY),
                    child: Opacity(
                      opacity: sparkleOpacity,
                      child: const SparkleStar(
                        size: 14,
                        color: kCyan,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tarjeta translúcida flotante para los íconos de usuario y maletín.
class FloatingFrostedTile extends StatelessWidget {
  final Widget child;
  final double size;

  const FloatingFrostedTile({
    super.key,
    required this.child,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 1,
            offset: const Offset(-0.5, -0.5),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

/// Esfera perlada decorativa iridiscente en tonos azules oficiales TalentMatch.
class FloatingSphere extends StatelessWidget {
  final double size;

  const FloatingSphere({super.key, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 0.8,
          colors: [
            Colors.white,
            Color(0xFFE0F2FE),
            Color(0xFF7DD3FC),
            kBlue,
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(1, 4),
          ),
        ],
      ),
    );
  }
}

/// Destello o estrella de 4 puntas en tonos cian/azul.
class SparkleStar extends StatelessWidget {
  final double size;
  final Color color;

  const SparkleStar({
    super.key,
    this.size = 14,
    this.color = kCyan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SparklePainter(color),
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  final Color color;
  SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fondo ambiental con orbes luminosos estilo Glassmorphic moderno.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradiente base suave
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFF5FE),
                  Color(0xFFF3F6FD),
                  Color(0xFFFFF7F2),
                ],
              ),
            ),
          ),
        ),

        // Orbe superior izquierdo (Azul cian suave TalentMatch)
        Positioned(
          top: -60,
          left: -40,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBAE6FD).withValues(alpha: 0.35),
                  const Color(0xFFE0F2FE).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Orbe medio derecho (Brillo cálido melocotón suave)
        Positioned(
          top: 140,
          right: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFED7AA).withValues(alpha: 0.38),
                  const Color(0xFFFFEDD5).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Orbe inferior (Azul hielo difuso)
        Positioned(
          bottom: -100,
          left: 20,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBAE6FD).withValues(alpha: 0.25),
                  const Color(0xFFE0F2FE).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
