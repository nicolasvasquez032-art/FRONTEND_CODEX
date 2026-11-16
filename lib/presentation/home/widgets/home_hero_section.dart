import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hero Section principal de la pantalla de inicio idéntica al diseño de Figma.
/// A la izquierda: Subtítulo "TU TALENTO, MÁS LEJOS" y Titular "Tu próximo reto empieza aquí."
/// A la derecha: Ilustración 3D interactiva del maletín flotante con animaciones de apertura y destellos.
class HomeHeroSection extends StatelessWidget {
  final bool isSpanish;

  const HomeHeroSection({
    super.key,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Columna de texto izquierda
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSpanish ? 'TU TALENTO, MÁS LEJOS' : 'YOUR TALENT, FURTHER',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isSpanish
                          ? 'Tu próximo reto\n'
                          : 'Your next challenge\n',
                      style: GoogleFonts.inter(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: isSpanish ? 'empieza aquí.' : 'starts here.',
                      style: GoogleFonts.inter(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Ilustración 3D del maletero con animación física flotante y apertura/cierre
        const Expanded(
          flex: 4,
          child: AnimatedBriefcaseHero(),
        ),
      ],
    );
  }
}

/// Maletín 3D interactivo con física de levitación, apertura/cierre suave al tocar
/// y destellos mágicos de partículas.
class AnimatedBriefcaseHero extends StatefulWidget {
  const AnimatedBriefcaseHero({super.key});

  @override
  State<AnimatedBriefcaseHero> createState() => _AnimatedBriefcaseHeroState();
}

class _AnimatedBriefcaseHeroState extends State<AnimatedBriefcaseHero>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatY;
  late final Animation<double> _floatRot;

  late final AnimationController _openController;
  late final Animation<double> _openProgress;

  bool _isOpen = false;
  Timer? _autoCloseTimer;
  Timer? _periodicPeekTimer;

  @override
  void initState() {
    super.initState();

    // 1. Animación continua de levitación (bobbing y sutil rotación)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _floatRot = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Animación de apertura y cierre (750ms)
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _openProgress = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    // 3. Demostración periódica automática cada 10 segundos si no hay interacción
    _periodicPeekTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isOpen && !_openController.isAnimating) {
        _performPeek();
      }
    });
  }

  void _performPeek() {
    _open();
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _isOpen) {
        _close();
      }
    });
  }

  void _open() {
    HapticFeedback.mediumImpact();
    setState(() => _isOpen = true);
    _openController.forward();
  }

  void _close() {
    HapticFeedback.lightImpact();
    setState(() => _isOpen = false);
    _openController.reverse();
  }

  void _toggle() {
    if (_isOpen) {
      _autoCloseTimer?.cancel();
      _close();
    } else {
      _open();
      _autoCloseTimer?.cancel();
      _autoCloseTimer = Timer(const Duration(milliseconds: 2800), () {
        if (mounted && _isOpen) {
          _close();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _periodicPeekTimer?.cancel();
    _floatController.dispose();
    _openController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _openController]),
        builder: (context, child) {
          final progress = _openProgress.value;
          final floatOffset = _floatY.value;
          final floatAngle = _floatRot.value;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.rotate(
              angle: floatAngle,
              child: SizedBox(
                height: 145,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Resplandor cálido luminoso cuando se abre
                    if (progress > 0.05)
                      Positioned(
                        top: 20,
                        child: Container(
                          width: 100,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF60A5FA)
                                    .withValues(alpha: 0.40 * progress),
                                blurRadius: 32,
                                spreadRadius: 8 * progress,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFDE047)
                                    .withValues(alpha: 0.30 * progress),
                                blurRadius: 18,
                                spreadRadius: 3 * progress,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Maletín CERRADO (se desvanece suavemente con inclinación 3D)
                    Opacity(
                      opacity: (1.0 - progress).clamp(0.0, 1.0),
                      child: Transform.scale(
                        alignment: Alignment.bottomCenter,
                        scale: 1.0 - (progress * 0.05),
                        child: Image.asset(
                          'assets/images/home_3d_composition.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/images/home_hero_3d_composition.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Maletín ABIERTO (emerge abriéndose hacia arriba)
                    Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Transform.scale(
                        alignment: Alignment.bottomCenter,
                        scale: 0.95 + (progress * 0.05),
                        child: Image.asset(
                          'assets/images/home_3d_composition_open.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/images/home_3d_composition.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Partículas de estrellas y destellos mágicos que emergen del interior
                    if (progress > 0.15) ...[
                      _buildSparkle(
                        dx: -16,
                        dy: -24 - (progress * 28),
                        scale: progress,
                        size: 14,
                        color: const Color(0xFFFBBF24),
                      ),
                      _buildSparkle(
                        dx: 20,
                        dy: -30 - (progress * 24),
                        scale: progress * 0.9,
                        size: 13,
                        color: const Color(0xFF38BDF8),
                      ),
                      _buildSparkle(
                        dx: 0,
                        dy: -40 - (progress * 30),
                        scale: progress * 1.15,
                        size: 16,
                        color: const Color(0xFF60A5FA),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSparkle({
    required double dx,
    required double dy,
    required double scale,
    required double size,
    required Color color,
  }) {
    return Positioned(
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: Icon(
            Icons.auto_awesome,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }
}
