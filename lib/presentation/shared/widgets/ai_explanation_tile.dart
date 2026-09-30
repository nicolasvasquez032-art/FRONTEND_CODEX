import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/recomendacion.dart';
import 'bouncing_card.dart';
import 'match_badge.dart';

/// Tarjeta que muestra una recomendación IA con título, badge de compatibilidad
/// y la explicación textual del motor semántico.
class AiExplanationTile extends StatelessWidget {
  final Recomendacion recomendacion;

  /// Callback al tocar la tarjeta (navegar al detalle de la vacante).
  final VoidCallback? onTap;

  const AiExplanationTile({
    super.key,
    required this.recomendacion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingCard(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kNavy.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila superior: logo empresa + título + chevron ──
            Row(
              children: [
                _CompanyAvatar(recomendacion.titulo),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'ml_title_${recomendacion.vacanteId}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            recomendacion.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: kNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MatchBadge(percent: recomendacion.scorePercent),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: kMuted, size: 18),
              ],
            ),

            // ── Divider ──
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: kLine),
            ),

            // ── Explicación del ML ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: kGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recomendacion.explicacion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kMuted,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar circular de empresa ──────────────────────────────────────

class _CompanyAvatar extends StatelessWidget {
  final String titulo;
  const _CompanyAvatar(this.titulo);

  @override
  Widget build(BuildContext context) {
    final letter = titulo.trim().isNotEmpty ? titulo.trim()[0].toUpperCase() : '?';
    return Container(
      width: 44, height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: kBlue,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
    );
  }
}
