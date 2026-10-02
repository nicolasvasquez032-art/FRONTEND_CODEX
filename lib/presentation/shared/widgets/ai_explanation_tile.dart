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
          border: Border.all(color: kCyan.withValues(alpha: 0.2), width: 1.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kCyan.withValues(alpha: 0.06),
              blurRadius: 20,
              spreadRadius: 2,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kCyan.withValues(alpha: 0.05), kPurple.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kCyan.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [kCyan, kPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recomendacion.explicacion,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: kNavy,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlue.withValues(alpha: 0.8), kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: kBlue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}
