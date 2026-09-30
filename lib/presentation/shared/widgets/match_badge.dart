import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Badge verde que muestra el porcentaje de compatibilidad IA.
/// Ejemplo: "✦ 87% compatible contigo"
class MatchBadge extends StatefulWidget {
  /// Porcentaje ya calculado (0–100).
  final int percent;

  /// Si [compact] es true muestra solo "✦ 87%", sin "compatible contigo".
  final bool compact;

  const MatchBadge({super.key, required this.percent, this.compact = false});

  @override
  State<MatchBadge> createState() => _MatchBadgeState();
}

class _MatchBadgeState extends State<MatchBadge> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // Controlador para el resplandor infinito
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder para animar el número del 0% al porcentaje real una sola vez
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.percent.toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final currentVal = value.toInt();
        final label = widget.compact ? '✦ $currentVal%' : '✦ $currentVal% compatible contigo';

        return AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kMatchBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kMatchText.withValues(alpha: 0.25),
                    blurRadius: _glowAnimation.value + 3,
                    spreadRadius: _glowAnimation.value * 0.4,
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: kMatchText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
