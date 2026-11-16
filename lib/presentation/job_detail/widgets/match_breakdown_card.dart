import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/recomendacion.dart';
import '../../../domain/entities/vacante.dart';
import '../../shared/widgets/match_badge.dart';

/// Modelo de datos que representa el desglose detallado del match entre candidato y vacante.
class MatchBreakdownData {
  final int matchPercent;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final bool meetsExperience;
  final int candidateYears;
  final String advice;
  final String? mlExplanation;

  const MatchBreakdownData({
    required this.matchPercent,
    required this.matchingSkills,
    required this.missingSkills,
    required this.meetsExperience,
    required this.candidateYears,
    required this.advice,
    this.mlExplanation,
  });

  /// Analiza de forma heurística y semántica el perfil y la vacante para derivar el desglose.
  factory MatchBreakdownData.calculate({
    required Vacante vacante,
    required Profile? profile,
    Recomendacion? recomendacionML,
    required bool isSpanish,
  }) {
    if (profile == null) {
      return MatchBreakdownData(
        matchPercent: recomendacionML?.scorePercent ?? 70,
        matchingSkills: [],
        missingSkills: vacante.requisitos.take(4).toList(),
        meetsExperience: false,
        candidateYears: 0,
        advice: isSpanish
            ? 'Inicia sesión o completa tu perfil para ver tu desglose personalizado.'
            : 'Sign in or complete your profile to view your personalized match breakdown.',
        mlExplanation: recomendacionML?.explicacionLocalized(isSpanish),
      );
    }

    final candSkills = profile.skills.map((s) => s.trim().toLowerCase()).toList();
    final candText = '${profile.fullName} ${profile.jobTitle ?? ''} ${profile.aboutMe ?? ''} ${profile.education ?? ''} ${candSkills.join(' ')} ${profile.cvText ?? ''}'.toLowerCase();

    final List<String> matching = [];
    final List<String> missing = [];

    // 1. Evaluar requisitos formales de la vacante
    for (final req in vacante.requisitos) {
      final reqLower = req.trim().toLowerCase();
      final hasDirectMatch = candSkills.any((s) => s.contains(reqLower) || reqLower.contains(s)) ||
          candText.contains(reqLower);

      if (hasDirectMatch) {
        if (!matching.contains(req)) matching.add(req);
      } else {
        if (!missing.contains(req)) missing.add(req);
      }
    }

    // 2. Si hay pocos requisitos explícitos, escanear el catálogo técnico estándar
    if (matching.isEmpty && missing.isEmpty) {
      const catalog = [
        'Flutter', 'Dart', 'Python', 'FastAPI', 'Django', 'React', 'TypeScript',
        'JavaScript', 'Node.js', 'PostgreSQL', 'SQL', 'Docker', 'AWS', 'Git', 'Linux',
      ];
      final descLower = '${vacante.titulo} ${vacante.descripcion}'.toLowerCase();
      for (final tech in catalog) {
        final tLower = tech.toLowerCase();
        if (descLower.contains(tLower)) {
          if (candText.contains(tLower)) {
            matching.add(tech);
          } else {
            missing.add(tech);
          }
        }
      }
    }

    // 3. Evaluar experiencia
    final candidateYears = profile.experienceYears;
    final meetsExperience = candidateYears >= 2; // base standard

    // 4. Calcular porcentaje
    int percent;
    if (recomendacionML != null) {
      percent = recomendacionML.scorePercent;
    } else {
      final total = matching.length + missing.length;
      if (total > 0) {
        final ratio = matching.length / total;
        percent = (50 + (ratio * 45)).round().clamp(45, 96);
      } else {
        percent = 75;
      }
    }

    // 5. Construir consejo de carrera contextualizado
    final String advice;
    if (percent >= 85) {
      advice = isSpanish
          ? '¡Excelente compatibilidad! Cumples con las competencias prioritarias de la vacante. Postúlate ahora para destacar ante el equipo de contratación.'
          : 'Outstanding match! You meet key core competencies for this role. Apply now to stand out to the hiring team.';
    } else if (percent >= 65) {
      final topMissing = missing.take(2).join(', ');
      advice = isSpanish
          ? (topMissing.isNotEmpty
              ? 'Buen perfil técnico. Si destacas proyectos o bases en $topMissing, aumentarás tus probabilidades de contratación al 95%.'
              : 'Buen ajuste técnico con las responsabilidades del puesto. Destaca tus proyectos en tu postulación.')
          : (topMissing.isNotEmpty
              ? 'Strong technical profile. Highlighting experience or foundations in $topMissing will raise your match to 95%.'
              : 'Good technical fit with position requirements. Showcase your projects when applying.');
    } else {
      final topMissing = missing.take(3).join(', ');
      advice = isSpanish
          ? (topMissing.isNotEmpty
              ? 'Esta posición requiere conocimientos en $topMissing. Desarrollar estas habilidades te preparará idealmente para este cargo.'
              : 'Tu perfil tiene afinidad general. Fortalece tus habilidades clave para alcanzar la máxima compatibilidad.')
          : (topMissing.isNotEmpty
              ? 'This role demands skills in $topMissing. Developing these areas will position you well for this role.'
              : 'Your profile has general alignment. Strengthening key requirements will boost your compatibility.');
    }

    return MatchBreakdownData(
      matchPercent: percent,
      matchingSkills: matching,
      missingSkills: missing,
      meetsExperience: meetsExperience,
      candidateYears: candidateYears,
      advice: advice,
      mlExplanation: recomendacionML?.explicacionLocalized(isSpanish),
    );
  }
}

/// Tarjeta moderna tipo Glassmorphism que desglosa visualmente qué cumple el candidato y qué puede mejorar.
class MatchBreakdownCard extends StatefulWidget {
  final Vacante vacante;
  final Recomendacion? recomendacionML;
  final Profile? profile;
  final bool isSpanish;

  const MatchBreakdownCard({
    super.key,
    required this.vacante,
    this.recomendacionML,
    this.profile,
    required this.isSpanish,
  });

  @override
  State<MatchBreakdownCard> createState() => _MatchBreakdownCardState();
}

class _MatchBreakdownCardState extends State<MatchBreakdownCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isEs = widget.isSpanish;
    final data = MatchBreakdownData.calculate(
      vacante: widget.vacante,
      profile: widget.profile,
      recomendacionML: widget.recomendacionML,
      isSpanish: isEs,
    );

    final isHighMatch = data.matchPercent >= 80;
    final themeColor = isHighMatch ? kGreen : kBlue;

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header con Gradiente Sutil ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColor.withValues(alpha: 0.08),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.auto_awesome, color: themeColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEs ? 'Desglose de Compatibilidad IA' : 'AI Match Breakdown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kNavy,
                            ),
                          ),
                          Text(
                            isEs ? 'Análisis semántico en tiempo real' : 'Real-time semantic analysis',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MatchBadge(
                      percent: data.matchPercent,
                      compact: true,
                      isSpanish: isEs,
                    ),
                    IconButton(
                      icon: Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: kNavy,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      tooltip: _expanded
                          ? (isEs ? 'Contraer' : 'Collapse')
                          : (isEs ? 'Expandir' : 'Expand'),
                    ),
                  ],
                ),
              ),

              // ── Contenido Expandible ──
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de compatibilidad visual
                      _buildProgressBar(data, isEs),
                      const SizedBox(height: 16),

                      // Explicación textual ML si está disponible
                      if (data.mlExplanation != null && data.mlExplanation!.isNotEmpty) ...[
                        Text(
                          data.mlExplanation!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── SECCIÓN 1: CUMPLES CON ──
                      _buildSectionHeader(
                        icon: Icons.check_circle_rounded,
                        iconColor: kGreen,
                        title: isEs ? 'Cumples con tu perfil' : 'You match with your profile',
                        count: data.matchingSkills.length + (data.meetsExperience ? 1 : 0),
                        badgeColor: const Color(0xFFE8F5E9),
                        textColor: const Color(0xFF15803D),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (data.meetsExperience && data.candidateYears > 0)
                            _buildSkillChip(
                              label: isEs
                                  ? '${data.candidateYears} años de experiencia'
                                  : '${data.candidateYears} yrs experience',
                              isMatch: true,
                              icon: Icons.timeline,
                            ),
                          if (data.matchingSkills.isEmpty && !data.meetsExperience)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                isEs
                                    ? 'Añade más habilidades a tu perfil para validar afinidad.'
                                    : 'Add more skills to your profile to validate affinity.',
                                style: const TextStyle(fontSize: 12, color: kMuted),
                              ),
                            )
                          else
                            ...data.matchingSkills.map(
                              (s) => _buildSkillChip(label: s, isMatch: true),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── SECCIÓN 2: POR POTENCIAR ──
                      _buildSectionHeader(
                        icon: Icons.lightbulb_outline_rounded,
                        iconColor: const Color(0xFFD97706),
                        title: isEs ? 'Por potenciar / Para aprender' : 'Growth opportunities / To learn',
                        count: data.missingSkills.length,
                        badgeColor: const Color(0xFFFEF3C7),
                        textColor: const Color(0xFFB45309),
                      ),
                      const SizedBox(height: 8),
                      if (data.missingSkills.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFD97706), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                isEs ? '¡Cubres todos los requisitos clave!' : 'You cover all key requirements!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: data.missingSkills.map(
                            (s) => _buildSkillChip(label: s, isMatch: false),
                          ).toList(),
                        ),
                      const SizedBox(height: 16),

                      // ── SECCIÓN 3: CONSEJO DE LA IA ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.tips_and_updates_outlined,
                              size: 18,
                              color: kBlue,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEs ? 'Consejo de la IA' : 'AI Career Tip',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: kNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data.advice,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(MatchBreakdownData data, bool isEs) {
    final total = data.matchingSkills.length + data.missingSkills.length;
    final matchRatio = total > 0 ? (data.matchingSkills.length / total) : (data.matchPercent / 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEs
                  ? '${data.matchingSkills.length} de $total requisitos cubiertos'
                  : '${data.matchingSkills.length} of $total requirements met',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kNavy),
            ),
            Text(
              '${(matchRatio * 100).round()}%',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kGreen),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: matchRatio.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              matchRatio >= 0.75 ? kGreen : (matchRatio >= 0.5 ? kBlue : Colors.orange),
            ),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip({
    required String label,
    required bool isMatch,
    IconData? icon,
  }) {
    final bg = isMatch ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final border = isMatch ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final text = isMatch ? const Color(0xFF166534) : const Color(0xFF92400E);
    final iconColor = isMatch ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    final iconData = icon ?? (isMatch ? Icons.check_circle_rounded : Icons.lightbulb_outline_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
