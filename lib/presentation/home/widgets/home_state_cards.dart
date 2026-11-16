import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

/// Tarjeta de análisis IA activo cuando el candidato ya tiene CV y sus recomendaciones
/// se están computando o están listas para sincronizarse.
class HomeAiAnalyzingCard extends StatelessWidget {
  final bool isSpanish;
  final String profileId;
  final VoidCallback onRefresh;

  const HomeAiAnalyzingCard({
    super.key,
    required this.isSpanish,
    required this.profileId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF93C5FD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono con indicador circular de carga y destello IA
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 66,
                height: 66,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  backgroundColor: Color(0xFFDBEAFE),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Pastilla indicadora de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isSpanish
                        ? 'Hoja de vida procesada por IA'
                        : 'Resume processed by AI',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E40AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Título principal
          Text(
            isSpanish
                ? 'Analizando vacantes compatibles...'
                : 'Matching vacancies with your profile...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Explicación detallada
          Text(
            isSpanish
                ? 'Nuestro modelo de Inteligencia Artificial está comparando tus habilidades técnicas y experiencia con las vacantes disponibles para calcular tu porcentaje de afinidad.'
                : 'Our AI model is comparing your skills and experience with open vacancies to compute your match affinity.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Barra de progreso elegante
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              minHeight: 6,
              color: Color(0xFF2563EB),
              backgroundColor: Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 20),

          // Botón: Actualizar recomendaciones
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRefresh();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                isSpanish
                    ? 'Ver recomendaciones analizadas'
                    : 'View matched recommendations',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de activación cuando el candidato aún no ha subido su CV o completado perfil.
class HomeAiEmptyStateCard extends StatelessWidget {
  final bool isSpanish;
  final VoidCallback onCompleteProfile;
  final VoidCallback onExplore;

  const HomeAiEmptyStateCard({
    super.key,
    required this.isSpanish,
    required this.onCompleteProfile,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono con degradado azul y morado
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Pastilla indicadora de IA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  size: 15,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Text(
                  isSpanish ? 'Motor de Inteligencia Artificial' : 'AI Matching Engine',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Título principal
          Text(
            isSpanish
                ? 'Activa tus recomendaciones con IA'
                : 'Activate your AI Recommendations',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Explicación
          Text(
            isSpanish
                ? 'Nuestro modelo de IA analiza tu perfil profesional, hoja de vida y habilidades técnicas para recomendarte únicamente las vacantes donde tienes alta afinidad. Completa tu información para desbloquear tus ofertas ideales.'
                : 'Our AI model evaluates your profile, resume, and technical skills to recommend only the jobs with high affinity. Complete your info to unlock your ideal job offers.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 22),

          // Botón 1: Completar perfil / Subir CV
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCompleteProfile,
              icon: const Icon(Icons.assignment_ind_outlined, size: 18),
              label: Text(
                isSpanish ? 'Completar perfil / Subir CV' : 'Complete Profile / Upload CV',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Botón 2: Explorar todas las vacantes
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: Text(
                isSpanish ? 'Explorar todas las vacantes' : 'Explore all vacancies',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío cuando los filtros no coinciden con ninguna vacante.
class HomeEmptyState extends StatelessWidget {
  final bool isSpanish;
  final VoidCallback onClearFilters;

  const HomeEmptyState({
    super.key,
    required this.isSpanish,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.work_outline_rounded,
            size: 44,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            isSpanish
                ? 'No se encontraron vacantes con los filtros seleccionados'
                : 'No vacancies found with selected filters',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClearFilters,
            child: Text(
              isSpanish ? 'Limpiar filtros' : 'Clear filters',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeletons de carga con Shimmer
class HomeLoadingSkeletons extends StatelessWidget {
  const HomeLoadingSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Shimmer.fromColors(
            baseColor: Colors.white.withValues(alpha: 0.6),
            highlightColor: Colors.white,
            child: Container(
              height: 155,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador Cupertino para pull-to-refresh
Widget buildHomeRefreshIndicator(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
  double refreshIndicatorExtent,
) {
  final double percentage =
      (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
  return Container(
    height: pulledExtent,
    alignment: Alignment.bottomCenter,
    padding: const EdgeInsets.only(bottom: 10),
    child: Opacity(
      opacity: percentage,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CupertinoActivityIndicator(
            radius: 10,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    ),
  );
}
