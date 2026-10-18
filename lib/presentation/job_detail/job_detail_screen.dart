import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../shared/providers/postulaciones_provider.dart';
import '../shared/widgets/match_badge.dart';
import '../shared/widgets/glass_card.dart';
import '../explore/map_screen.dart';

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
  bool _showOriginalText = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vacante = widget.vacante;
    final recomendacionML = widget.recomendacionML;
    final heroTagTitle = widget.heroTagTitle;

    final postsProvider = context.watch<PostulacionesProvider>();
    final session = context.read<AuthProvider>().session;
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
                                        Text(
                                          vacante.ubicacionLocalized(isEs),
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
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

                      // ML Match Card
                      if (recomendacionML != null) ...[
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kMatchBg.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: kGreen, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEs ? 'Análisis de Inteligencia Artificial' : 'Artificial Intelligence Analysis',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: kMatchText),
                                    ),
                                    const Spacer(),
                                    MatchBadge(percent: recomendacionML.scorePercent, compact: true, isSpanish: isEs),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  recomendacionML.explicacionLocalized(isEs),
                                  style: const TextStyle(fontSize: 13, color: kMatchText, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                              Text(
                                isEs ? 'Traducido por TalentMatch IA' : 'Translated by TalentMatch AI',
                                style: const TextStyle(fontSize: 11, color: kBlue, fontWeight: FontWeight.w600),
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
                            Text(
                              isEs ? 'Requisitos' : 'Requirements',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kNavy),
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
}

// ────────────────────────────────────────────────────────
// Widget: barra inferior de acción
// ────────────────────────────────────────────────────────

class _PostularseBar extends StatelessWidget {
  final Vacante vacante;
  final bool yaPostulado;
  final String candidatoId;
  final bool isSpanish;
  final VoidCallback onSuccess;

  const _PostularseBar({
    required this.vacante,
    required this.yaPostulado,
    required this.candidatoId,
    this.isSpanish = true,
    required this.onSuccess,
  });

  Future<void> _postularse(BuildContext context) async {
    if (candidatoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSpanish ? 'Completa tu perfil antes de postularte.' : 'Complete your profile before applying.')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            provider.error ?? (isSpanish ? 'Ya estás postulado a esta vacante.' : 'Already applied to this job.'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                : _applyButton(context),
          ),
        ),
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
                      await widget.onSwipe();
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

