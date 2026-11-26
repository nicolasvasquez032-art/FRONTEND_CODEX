import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/vacante.dart';
import '../../domain/entities/recomendacion.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/perfil_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/app_toast.dart';
import '../shared/widgets/glass_card.dart';
import '../explore/map_screen.dart';
import '../simulator/interview_simulator_screen.dart';
import 'widgets/match_breakdown_card.dart';

class JobDetailScreen extends StatefulWidget {
  final Vacante vacante;
  final String? heroTagTitle;
  final Recomendacion? recomendacionML;

  const JobDetailScreen({
    super.key,
    required this.vacante,
    this.heroTagTitle,
    this.recomendacionML,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late ConfettiController _confettiController;
  Vacante? _loadedVacante;
  bool _showOriginalText = false;

  Vacante get _currentVacante => _loadedVacante ?? widget.vacante;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFullVacanteDetails());
  }

  Future<void> _ensureFullVacanteDetails() async {
    final cur = _currentVacante;
    final hasProperDesc = cur.descripcion.isNotEmpty &&
        cur.descripcion != widget.recomendacionML?.explicacion;
    final hasReqs = cur.requisitos.isNotEmpty;
    if (hasProperDesc && hasReqs) return;

    final vProvider = Provider.of<VacantesProvider?>(context, listen: false);
    if (vProvider != null) {
      final full = await vProvider.getVacanteDetalle(cur.id);
      if (full != null && mounted) {
        setState(() {
          _loadedVacante = full;
        });
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vacante = _currentVacante;
    final recomendacionML = widget.recomendacionML;
    final heroTagTitle = widget.heroTagTitle;

    final postsProvider = context.watch<PostulacionesProvider>();
    final session = context.read<AuthProvider>().session;
    final candidateProfile = context.watch<PerfilProvider>().profile;
    final yaPostulado = postsProvider.yaPostulado(vacante.id);
    final isEs = context.watch<LocaleProvider>().isSpanish;

    // Control de traducción en tiempo real (LinkedIn / Airbnb pattern)
    final bool isActuallyTranslated = isEs ? _showOriginalText : !_showOriginalText;
    final String activeDescription = isActuallyTranslated
        ? vacante.descripcionLocalized(false)
        : vacante.descripcion;
    final List<String> activeRequisitos = isActuallyTranslated
        ? vacante.requisitosLocalized(false)
        : vacante.requisitos;

    final String toggleButtonLabel;
    if (isEs) {
      toggleButtonLabel = _showOriginalText ? 'Ver original' : 'Traducir al inglés';
    } else {
      toggleButtonLabel = _showOriginalText ? 'Translate to English' : 'See original';
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── App Bar con gradiente ──
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            stretch: true, // Efecto elástico al tirar hacia abajo
            backgroundColor: kBlue,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax, // Parallax al hacer scroll
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Container(
                decoration: const BoxDecoration(gradient: kBannerGradient),
                child: Stack(
                  children: [
                    // Efectos de fondo limpios (solo arriba/derecha para no estorbar el texto)
                    Positioned(
                      top: -60,
                      right: -40,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabecera: Logo de empresa y Nombre
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.business_center, color: kBlue, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEs ? 'Empresa Confidencial' : 'Confidential Company',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.white70, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            vacante.ubicacionLocalized(isEs),
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          if (vacante.categoria != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                vacante.categoriaLocalized(isEs) ?? vacante.categoria!,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Hero(
                            tag: heroTagTitle ?? 'title_${vacante.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                vacante.tituloLocalized(isEs),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ], // end Column children
                      ), // end Column
                    ), // end Padding
                  ], // end Stack children
                ), // end Stack
              ), // end Container
            ), // end FlexibleSpaceBar
          ), // end SliverAppBar

          // ── Contenido ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Info rápida
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadatos clave
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(Icons.location_on_outlined, vacante.ubicacionLocalized(isEs)),
                          _InfoChip(Icons.calendar_today_outlined, vacante.fechaPublicacionLocalized(isEs)),
                          _InfoChip(Icons.access_time_outlined, vacante.tiempoRelativoLocalized(isEs)),
                          _InfoChip(Icons.attach_money_outlined, vacante.salarioDisplayLocalized(isEs), accent: true),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // AI Match Breakdown (Cumples vs Por Mejorar)
                      if (session?.role != 'company' && (recomendacionML != null || candidateProfile != null)) ...[
                        MatchBreakdownCard(
                          vacante: vacante,
                          recomendacionML: recomendacionML,
                          profile: candidateProfile,
                          isSpanish: isEs,
                        ),
                      ],

                      // Tarjeta interactiva del Simulador de Entrevista IA
                      if (session?.role != 'company') ...[
                        const SizedBox(height: 16),
                        _buildInterviewSimulatorCard(context, vacante, isEs),
                      ],

                      // Mini Map
                      if (vacante.ubicacion.toLowerCase() != 'remoto') ...[
                        Builder(
                          builder: (context) {
                            LatLng getCoordinates() {
                              if (vacante.latitud != null && vacante.longitud != null) {
                                return LatLng(vacante.latitud!, vacante.longitud!);
                              }
                              final loc = vacante.ubicacion.toLowerCase();
                              if (loc.contains('fusagasugá') || loc.contains('fusagasuga')) return const LatLng(4.33646, -74.36378);
                              if (loc.contains('bogotá') || loc.contains('bogota')) return const LatLng(4.60971, -74.08175);
                              if (loc.contains('medellín') || loc.contains('medellin')) return const LatLng(6.2442, -75.5812);
                              if (loc.contains('cali')) return const LatLng(3.4516, -76.5320);
                              if (loc.contains('barranquilla')) return const LatLng(10.9639, -74.7964);
                              // Fallback default: Centro de Colombia (Bogotá)
                              return const LatLng(4.60971, -74.08175);
                            }

                            final mapCenter = getCoordinates();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEs ? 'Ubicación' : 'Location',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kNavy),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                          options: MapOptions(
                                            initialCenter: mapCenter,
                                            initialZoom: 14.0,
                                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName: 'co.talentmatch.talentmatch',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: mapCenter,
                                                  child: const Icon(Icons.location_on, color: kBlue, size: 40),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => MapScreen(focusedVacante: vacante),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Descripción
                      FadeIn(
                        duration: const Duration(milliseconds: 600),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.description_outlined, color: kBlue, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEs ? 'Descripción del cargo' : 'Job Description',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kNavy),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _showOriginalText = !_showOriginalText);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isActuallyTranslated ? kBlue.withValues(alpha: 0.08) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActuallyTranslated ? kBlue.withValues(alpha: 0.3) : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.g_translate_rounded, 
                                      size: 13, 
                                      color: isActuallyTranslated ? kBlue : kMuted,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      toggleButtonLabel,
                                      style: TextStyle(
                                        fontSize: 11, 
                                        fontWeight: FontWeight.w700, 
                                        color: isActuallyTranslated ? kBlue : kNavy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isActuallyTranslated)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 12, color: kBlue),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  isEs ? 'Traducido por TalentMatch IA' : 'Translated by TalentMatch AI',
                                  style: const TextStyle(fontSize: 11, color: kBlue, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          activeDescription,
                          key: ValueKey('desc_$isActuallyTranslated'),
                          style: const TextStyle(
                            color: Color(0xFF475569), 
                            fontSize: 14, 
                            height: 1.7, 
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      // Requisitos
                      if (vacante.requisitos.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.star_outline_rounded, color: kBlue, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEs ? 'Requisitos' : 'Requirements',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kNavy),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: activeRequisitos.asMap().entries.map(
                            (entry) => FadeInLeft(
                              delay: Duration(milliseconds: 200 + (50 * entry.key)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: kBlue.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBlue.withValues(alpha: 0.15), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: kBlue, size: 16),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          color: kNavy, 
                                          fontSize: 13, 
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                      ],

                      const SizedBox(height: 100), // espacio para el botón flotante
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Botón flotante de postulación ──
      bottomNavigationBar: session?.role == 'company' ? null : _PostularseBar(
        vacante: vacante,
        yaPostulado: yaPostulado,
        candidatoId: session?.profileId ?? '',
        isSpanish: isEs,
        matchScore: MatchBreakdownData.calculate(
          vacante: vacante,
          profile: candidateProfile,
          recomendacionML: recomendacionML,
          isSpanish: isEs,
        ).matchPercent,
        onSuccess: () => _confettiController.play(),
      ),
    ),
    Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [kBlue, kGreen, Colors.orange, Colors.pink],
        gravity: 0.2,
      ),
    ),
  ],
);
  }

  Widget _buildInterviewSimulatorCard(BuildContext context, Vacante vacante, bool isEs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF0F7FF).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: kBlue.withValues(alpha: 0.22),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kCyan, kBlue]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEs ? 'Simulador de entrevistas' : 'Interview practice',
                          style: const TextStyle(
                            color: kNavy,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: kBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBlue.withValues(alpha: 0.2), width: 0.8),
                          ),
                          child: const Text(
                            'NUEVO',
                            style: TextStyle(
                              color: kBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEs
                          ? 'Entrena tus respuestas técnicas y conductuales con Sophia antes de la entrevista real.'
                          : 'Practice your technical and behavioral answers with Sophia before the real interview.',
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                final profile = context.read<PerfilProvider>().profile;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InterviewSimulatorScreen(
                      jobTitle: vacante.titulo,
                      requiredSkills: vacante.requisitos,
                      jobDescription: vacante.descripcion,
                      candidateSkills: profile?.skills ?? const [],
                      experienceYears: profile?.experienceYears ?? 0,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                isEs ? 'Practicar entrevista' : 'Practice interviewing',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Widget: barra inferior de acción
// ────────────────────────────────────────────────────────

class _PostularseBar extends StatelessWidget {
  final Vacante vacante;
  final bool yaPostulado;
  final String candidatoId;
  final bool isSpanish;
  final int matchScore;
  final VoidCallback onSuccess;

  const _PostularseBar({
    required this.vacante,
    required this.yaPostulado,
    required this.candidatoId,
    this.isSpanish = true,
    this.matchScore = 75,
    required this.onSuccess,
  });

  Future<void> _postularse(BuildContext context) async {
    // 0. Validar afinidad mínima generada por IA (mínimo 50%, no se puede postular si es <= 49%)
    if (matchScore <= 49) {
      _mostrarDialogoAfinidadBaja(context);
      return;
    }

    if (candidatoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSpanish ? 'Completa tu perfil antes de postularte.' : 'Complete your profile before applying.')),
      );
      return;
    }

    // 1. Verificar si el candidato tiene hoja de vida (CV) cargada
    final perfilProv = context.read<PerfilProvider>();
    if (perfilProv.profile == null && candidatoId.isNotEmpty) {
      await perfilProv.cargar(candidatoId);
    }

    final hasCv = perfilProv.profile?.cvText != null && perfilProv.profile!.cvText!.trim().isNotEmpty;
    if (!hasCv) {
      if (context.mounted) {
        _mostrarDialogoRequiereCv(context);
      }
      return;
    }

    if (!context.mounted) return;
    final provider = context.read<PostulacionesProvider>();
    final ok = await provider.postularse(
      candidatoId: candidatoId,
      vacanteId: vacante.id,
    );

    if (!context.mounted) return;

    if (ok) {
      HapticFeedback.heavyImpact();
      onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF22C55E),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSpanish ? '¡Te postulaste a "${vacante.titulo}"!' : 'Applied to "${vacante.tituloLocalized(false)}"!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final isAlreadyApplied = provider.error?.toLowerCase().contains('ya existe') == true ||
          provider.error?.toLowerCase().contains('already exists') == true;

      if (isAlreadyApplied && candidatoId.isNotEmpty) {
        await provider.cargar(candidatoId);
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isAlreadyApplied ? const Color(0xFF2563EB) : Colors.red.shade700,
          content: Text(
            isAlreadyApplied
                ? (isSpanish ? 'Ya estás postulado a esta vacante.' : 'You have already applied to this job.')
                : (provider.error ?? (isSpanish ? 'Ya estás postulado a esta vacante.' : 'Already applied to this job.')),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  void _mostrarDialogoRequiereCv(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: Color(0xFF2563EB),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSpanish ? 'Hoja de Vida Requerida' : 'Resume Required',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isSpanish
                  ? 'Para postularte a esta vacante y que la empresa evalúe tu compatibilidad real con Inteligencia Artificial, necesitas subir tu hoja de vida primero.'
                  : 'To apply for this job and allow the company to evaluate your real compatibility with Artificial Intelligence, you need to upload your resume first.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  await _subirCvDesdeDetalle(context);
                },
                icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                label: Text(
                  isSpanish ? 'Subir Hoja de Vida ahora' : 'Upload Resume now',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: Text(
                  isSpanish ? 'Cancelar' : 'Cancel',
                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subirCvDesdeDetalle(BuildContext context) async {
    final perfilProv = context.read<PerfilProvider>();
    final profileId = candidatoId;
    if (profileId.isEmpty) return;

    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, isSpanish ? 'No se pudo abrir el selector de archivos.' : 'Could not open file picker.');
      }
      return;
    }

    if (picked == null) return;

    final bytes = (await picked.readAsBytes()).toList();
    final fileName = picked.name;
    final ext = picked.extension?.toLowerCase() ?? 'pdf';
    final mimeType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';

    if (!context.mounted) return;
    AppToast.info(context, isSpanish ? 'Subiendo y analizando hoja de vida...' : 'Uploading and analyzing resume...');

    final ok = await perfilProv.subirCv(
      profileId: profileId,
      fileBytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );

    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, isSpanish ? '¡Hoja de vida subida con éxito! Ahora puedes postularte.' : 'Resume uploaded successfully! You can now apply.');
    } else {
      AppToast.error(context, perfilProv.cvError ?? (isSpanish ? 'Error al subir la hoja de vida.' : 'Error uploading resume.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canApply = matchScore >= 50;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: GlassCard(
          useBackdropFilter: true,
          blurSigma: 8.0,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: yaPostulado
                ? _doneButton()
                : (canApply ? _applyButton(context) : _insufficientMatchButton(context)),
          ),
        ),
      ),
    );
  }

  Widget _insufficientMatchButton(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        key: const ValueKey('insufficient_match'),
        child: InkWell(
          onTap: () => _mostrarDialogoAfinidadBaja(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock_outlined, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isSpanish
                          ? 'Afinidad insuficiente ($matchScore%) • Mínimo 50%'
                          : 'Insufficient AI Match ($matchScore%) • Min 50%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.info_outline, color: Colors.amber, size: 17),
              ],
            ),
          ),
        ),
      );

  void _mostrarDialogoAfinidadBaja(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSpanish ? 'Afinidad Mínima Requerida' : 'Minimum Match Required',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpanish
                  ? 'Tu compatibilidad calculada por IA para esta vacante es del $matchScore%.\n\nLa empresa requiere un mínimo de 50% de afinidad técnica para recibir postulaciones.\n\nTe sugerimos revisar las competencias en la sección "Por potenciar" de esta vacante y agregarlas a tu perfil una vez las adquieras.'
                  : 'Your AI compatibility for this job is $matchScore%.\n\nThe company requires at least 50% match to apply.\n\nPlease review the missing skills in the "To Improve" section and add them to your profile.',
              style: const TextStyle(fontSize: 13.5, color: kMuted, height: 1.45),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: kNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isSpanish ? 'Entendido' : 'Understood'),
          ),
        ],
      ),
    );
  }

  Widget _applyButton(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        key: const ValueKey('apply'),
        child: SwipeToApplyButton(
          isSpanish: isSpanish,
          onSwipe: () async => await _postularse(context),
        ),
      );

  Widget _doneButton() => SizedBox(
        width: double.infinity,
        height: 52,
        key: const ValueKey('done'),
        child: FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            disabledBackgroundColor: const Color(0xFF22C55E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                isSpanish ? 'Ya estás postulado' : 'Already applied',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      );
}

// ────────────────────────────────────────────────────────
// Widget: chip de información
// ────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;
  const _InfoChip(this.icon, this.label, {this.accent = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: accent ? const Color(0xFFEDF7EE) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent ? const Color(0xFF22C55E) : kMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent ? const Color(0xFF16A34A) : kMuted,
              ),
            ),
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────
// Widget Custom: Swipe to Apply
// ────────────────────────────────────────────────────────

class SwipeToApplyButton extends StatefulWidget {
  final Future<void> Function() onSwipe;
  final bool isSpanish;

  const SwipeToApplyButton({super.key, required this.onSwipe, this.isSpanish = true});

  @override
  State<SwipeToApplyButton> createState() => _SwipeToApplyButtonState();
}

class _SwipeToApplyButtonState extends State<SwipeToApplyButton> {
  double _dragPosition = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 56; // width of the thumb
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: kBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBlue.withValues(alpha: 0.15)),
          ),
          child: Stack(
            children: [
              // Barra de relleno que crece al arrastrar
              AnimatedContainer(
                duration: _dragPosition == 0 ? const Duration(milliseconds: 300) : Duration.zero,
                width: _dragPosition + 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Texto de fondo con Shimmer para invitar a deslizar
              Center(
                child: Shimmer.fromColors(
                  baseColor: _dragPosition > 20 ? Colors.white.withValues(alpha: 0.8) : kBlue.withValues(alpha: 0.7),
                  highlightColor: _dragPosition > 20 ? Colors.white : kBlue,
                  child: Text(
                    _isFinished
                        ? (widget.isSpanish ? 'Enviando...' : 'Submitting...')
                        : (widget.isSpanish ? 'Desliza para postularte  ➔' : 'Swipe to apply  ➔'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
              // Thumb deslizable
              AnimatedPositioned(
                duration: _dragPosition == 0 ? const Duration(milliseconds: 300) : Duration.zero,
                curve: Curves.easeOutBack,
                left: _dragPosition,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) async {
                    if (_isFinished) return;
                    if (_dragPosition > maxDrag * 0.75) {
                      // Trigger success
                      setState(() {
                        _dragPosition = maxDrag;
                        _isFinished = true;
                      });
                      HapticFeedback.mediumImpact();
                      try {
                        await widget.onSwipe();
                      } finally {
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0.0;
                            _isFinished = false;
                          });
                        }
                      }
                    } else {
                      // Return to start
                      setState(() => _dragPosition = 0.0);
                      HapticFeedback.vibrate();
                    }
                  },
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: kBlue,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: kBlue.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

