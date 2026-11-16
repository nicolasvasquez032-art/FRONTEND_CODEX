import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Encabezado de sección "Recomendadas para ti" con botón "Ver todas →".
class HomeSectionHeader extends StatelessWidget {
  final bool isSpanish;
  final VoidCallback onSeeAll;

  const HomeSectionHeader({
    super.key,
    required this.isSpanish,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish ? 'Recomendadas para ti' : 'Recommended for you',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isSpanish
                    ? 'Oportunidades que conectan con tu perfil'
                    : 'Opportunities that match your profile',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onSeeAll();
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSpanish ? 'Ver todas ' : 'See all ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF2563EB),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
