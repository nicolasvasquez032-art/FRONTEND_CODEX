import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/locale_provider.dart';

/// Badge verde que muestra el porcentaje de compatibilidad IA.
/// Ejemplo: "✦ 87% compatible contigo"
class MatchBadge extends StatefulWidget {
  /// Porcentaje ya calculado (0–100).
  final int percent;

  /// Si [compact] es true muestra solo "✦ 87%", sin "compatible contigo".
  final bool compact;

  /// Idioma (opcional, si es null toma el del LocaleProvider global)
  final bool? isSpanish;

  const MatchBadge({super.key, required this.percent, this.compact = false, this.isSpanish});

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
      duration: const Duration(milliseconds: 1200),
    );

    final isHighMatch = widget.percent >= 85;
    
    if (isHighMatch) {
      _glowController.repeat(reverse: true);
    }

    _glowAnimation = Tween<double>(begin: 2.0, end: isHighMatch ? 16.0 : 2.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHighMatch = widget.percent >= 85;
    final isEs = widget.isSpanish ?? (context.watch<LocaleProvider>().isSpanish);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.percent.toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final currentVal = value.toInt();
        final label = widget.compact
            ? '✦ $currentVal%'
            : (isEs ? '✦ $currentVal% compatible contigo' : '✦ $currentVal% match for you');

        return AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isHighMatch ? const Color(0xFFE8F5E9) : kMatchBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHighMatch 
                      ? const Color(0xFF22C55E).withValues(alpha: 0.5) 
                      : Colors.transparent,
                  width: 1,
                ),
                boxShadow: isHighMatch ? [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value * 0.3,
                  ),
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    blurRadius: _glowAnimation.value + 8,
                    spreadRadius: _glowAnimation.value * 0.5,
                  ),
                ] : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isHighMatch ? const Color(0xFF15803D) : kMatchText,
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
