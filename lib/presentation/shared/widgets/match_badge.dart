import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Badge verde que muestra el porcentaje de compatibilidad IA.
/// Ejemplo: "✦ 87% compatible contigo"
class MatchBadge extends StatelessWidget {
  /// Porcentaje ya calculado (0–100).
  final int percent;

  /// Si [compact] es true muestra solo "✦ 87%", sin "compatible contigo".
  final bool compact;

  const MatchBadge({super.key, required this.percent, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final label = compact ? '✦ $percent%' : '✦ $percent% compatible contigo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: kMatchBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kMatchText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
