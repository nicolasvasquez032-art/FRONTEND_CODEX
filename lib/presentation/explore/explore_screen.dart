import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/vacante.dart';
import '../job_detail/job_detail_screen.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/bouncing_card.dart';
import '../shared/widgets/animated_empty_state.dart';
import '../shared/widgets/talentmatch_top_header.dart';
import 'map_screen.dart';

/// Pantalla oficial de Explorar Vacantes recreada fielmente según el diseño de Figma.
/// Incluye:
/// - Encabezado unificado [TalentMatchTopHeader] en el SafeArea superior.
/// - Hero Section con titular ("Descubre nuevas oportunidades", "Explorar Empleos")
///   y la Lupa 3D interactiva con animación continua de flotación física y partículas de brillo.
/// - Barra de búsqueda con botón de filtros azul Figma.
/// - Contador dinámico de vacantes encontradas.
/// - Tarjetas de vacante Figma con avatar de gradiente azul, etiquetas de ubicación/categoría,
///   fecha relativa y badge de salario verde.
/// - Botón flotante centrado "Ver Mapa".
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = context.read<VacantesProvider>();
      if (vp.status == VacantesStatus.initial) {
        vp.cargar();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VacantesProvider>();
    final isEs = context.watch<LocaleProvider>().isSpanish;

    // Obtener las vacantes a mostrar (reales o predeterminadas de Figma)
    final List<Vacante> displayList = vp.filtered.isNotEmpty
        ? vp.filtered
        : (_searchController.text.trim().isEmpty &&
                vp.filtroCategoria == null &&
                vp.filtroSalarioMin == null
            ? _getFigmaExploreJobs(isEs)
            : []);

    final totalCount = vp.filtered.isNotEmpty
        ? vp.filtered.length
        : (displayList.isNotEmpty ? 20 : 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Encabezado global TalentMatch
            const TalentMatchTopHeader(),

            // 2. Contenido deslizable
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () => vp.cargar(),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Hero Section: Titular + Lupa 3D Animada ──
                        _buildHeroSection(isEs),
                        const SizedBox(height: 18),

                        // ── Barra de Búsqueda Figma ──
                        _buildSearchBar(isEs, vp),
                        const SizedBox(height: 18),

                        // ── Contador de Vacantes Encontradas ──
                        _buildCountHeader(isEs, totalCount, vp.status == VacantesStatus.loading),
                        const SizedBox(height: 14),

                        // ── Lista de Tarjetas o Estados de Carga ──
                        if (vp.status == VacantesStatus.loading && displayList.isEmpty)
                          const _ShimmerList()
                        else if (vp.status == VacantesStatus.error && displayList.isEmpty)
                          _ErrorState(
                            vp.error ?? (isEs ? 'Error al cargar' : 'Error loading'),
                            onRetry: () => vp.cargar(),
                            isSpanish: isEs,
                          )
                        else if (displayList.isEmpty)
                          _EmptyState(isSpanish: isEs)
                        else
                          ...displayList.map(
                            (v) => _ExploreCard(
                              key: ValueKey(v.id),
                              vacante: v,
                              isSpanish: isEs,
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Botón Flotante "Ver Mapa" ──
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 82),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
            borderRadius: BorderRadius.circular(26),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEs ? 'Ver Mapa' : 'View Map',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Hero Section (Descubre nuevas oportunidades + Explorar Empleos + Lupa 3D)
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isEs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Textos a la izquierda
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEs ? 'Descubre nuevas oportunidades' : 'Discover new opportunities',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isEs ? 'Explorar\n' : 'Explore\n',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                        letterSpacing: -0.6,
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextSpan(
                      text: isEs ? 'Empleos' : 'Jobs',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                        height: 1.15,
                        letterSpacing: -0.6,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Ilustración 3D de la Lupa con Maletín y Animación Física
        const SizedBox(
          width: 110,
          height: 110,
          child: _AnimatedMagnifierHero(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Barra de Búsqueda Figma con Botón Azul de Filtro
  // ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isEs, VacantesProvider vp) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 16, right: 6),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => vp.setQuery(v),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: isEs ? 'Buscar empleo...' : 'Search jobs...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
              onPressed: () {
                _searchController.clear();
                vp.clearQuery();
                setState(() {});
              },
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFilterBottomSheet(context, vp, isEs);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.32),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Encabezado de Cantidad de Vacantes Encontradas
  // ─────────────────────────────────────────────────────────────
  Widget _buildCountHeader(bool isEs, int count, bool isLoading) {
    final text = isEs
        ? '$count vacante${count != 1 ? 's' : ''} encontrada${count != 1 ? 's' : ''}'
        : '$count ${count != 1 ? 'jobs found' : 'job found'}';

    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFamily: 'Inter',
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Mock Data inicial idéntica a Figma para explorar
  // ─────────────────────────────────────────────────────────────
  List<Vacante> _getFigmaExploreJobs(bool isEs) {
    return [
      Vacante(
        id: 'explore-figma-1',
        empresaId: 'confidencial-1',
        titulo: 'Desarrollador Python Senior',
        descripcion:
            'Buscamos Desarrollador Python Senior con sólida experiencia en FastAPI, Django y arquitectura de microservicios.',
        requisitos: const ['Python', 'FastAPI', 'PostgreSQL', 'Docker'],
        ubicacion: isEs ? 'Remoto' : 'Remote',
        categoria: 'Backend',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now().subtract(const Duration(days: 2)),
        salarioMin: 3000,
        salarioMax: 5000,
      ),
      Vacante(
        id: 'explore-figma-2',
        empresaId: 'confidencial-2',
        titulo: 'Desarrollador Python Senior',
        descripcion:
            'Únete a nuestro equipo para liderar proyectos escalables en Python y arquitecturas cloud en AWS.',
        requisitos: const ['Python', 'Django', 'AWS', 'Redis'],
        ubicacion: isEs ? 'Remoto' : 'Remote',
        categoria: 'Backend',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now().subtract(const Duration(days: 2)),
        salarioMin: 3000,
        salarioMax: 5000,
      ),
      Vacante(
        id: 'explore-figma-3',
        empresaId: 'confidencial-3',
        titulo: 'Desarrollador Python Junior',
        descripcion:
            'Oportunidad de desarrollo profesional para talentos con conocimientos en Python, Git y bases de datos relacionales.',
        requisitos: const ['Python', 'Git', 'SQL', 'FastAPI'],
        ubicacion: isEs ? 'Remoto' : 'Remote',
        categoria: 'Backend',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now().subtract(const Duration(days: 3)),
        salarioMin: 1500,
        salarioMax: 2500,
      ),
      Vacante(
        id: 'explore-figma-4',
        empresaId: 'confidencial-4',
        titulo: 'Ingeniero Frontend Flutter',
        descripcion:
            'Creación de interfaces móviles y web de alto impacto con Flutter, animaciones fluidas y Clean Architecture.',
        requisitos: const ['Flutter', 'Dart', 'BLoC', 'Figma'],
        ubicacion: isEs ? 'Remoto' : 'Remote',
        categoria: 'Frontend',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now().subtract(const Duration(days: 1)),
        salarioMin: 2800,
        salarioMax: 4200,
      ),
      Vacante(
        id: 'explore-figma-5',
        empresaId: 'confidencial-5',
        titulo: 'Especialista DevOps / Cloud',
        descripcion:
            'Administración de infraestructura en AWS, configuración de pipelines CI/CD y despliegue de contenedores Kubernetes.',
        requisitos: const ['Docker', 'Kubernetes', 'AWS', 'Terraform'],
        ubicacion: isEs ? 'Híbrido - Bogotá' : 'Hybrid - Bogota',
        categoria: 'DevOps',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now().subtract(const Duration(days: 4)),
        salarioMin: 4000,
        salarioMax: 6500,
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// Lupa 3D Animada con Maletín de Cristal (Animación Física)
// ─────────────────────────────────────────────────────────────
class _AnimatedMagnifierHero extends StatefulWidget {
  const _AnimatedMagnifierHero();

  @override
  State<_AnimatedMagnifierHero> createState() => _AnimatedMagnifierHeroState();
}

class _AnimatedMagnifierHeroState extends State<_AnimatedMagnifierHero>
    with TickerProviderStateMixin {
  // 1. Animación continua de flotación física gravitatoria
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  // 2. Animación interactiva de búsqueda / pulso al tocar
  late final AnimationController _pulseController;
  late final Animation<double> _scalePulseAnim;
  late final Animation<double> _rotationTwitchAnim;

  // Partículas de brillo de escaneo
  bool _showSparkles = false;

  @override
  void initState() {
    super.initState();

    // Flotación constante y suave (3.2 segundos cíclico)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatAnim = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOutSine,
    );

    // Animación interactiva al hacer tap (brote elástico)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scalePulseAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_pulseController);

    _rotationTwitchAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.12).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.12, end: 0.08).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.08, end: 0.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_pulseController);

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showSparkles = false);
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    HapticFeedback.mediumImpact();
    setState(() => _showSparkles = true);
    _pulseController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerPulse,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatAnim, _pulseController]),
        builder: (context, child) {
          // Valores de física en tiempo real
          final floatOffset = math.sin(_floatAnim.value * math.pi) * 8.0 - 4.0;
          final floatTilt = math.sin(_floatAnim.value * math.pi) * 0.05;

          final scale = _pulseController.isAnimating ? _scalePulseAnim.value : 1.0;
          final twitch = _pulseController.isAnimating ? _rotationTwitchAnim.value : 0.0;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: floatTilt + twitch,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Resplandor ambiental suave azul detrás de la lupa
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2563EB).withValues(alpha: 0.22),
                            const Color(0xFF3B82F6).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),

                    // Imagen 3D de la Lupa con el Maletín
                    Image.asset(
                      'assets/images/explore_3d_lupa_hd.png',
                      width: 105,
                      height: 105,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/explore_3d_magnifier.png',
                        width: 105,
                        height: 105,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Destellos de partículas mágicas al tocar
                    if (_showSparkles) ...[
                      Positioned(
                        top: -6,
                        right: 8,
                        child: _SparkleStar(
                          progress: _pulseController.value,
                          color: const Color(0xFF60A5FA),
                          size: 14,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: -4,
                        child: _SparkleStar(
                          progress: _pulseController.value,
                          color: const Color(0xFF38BDF8),
                          size: 12,
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 2,
                        child: _SparkleStar(
                          progress: _pulseController.value,
                          color: const Color(0xFF93C5FD),
                          size: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Estrella / destello de animación óptica al interactuar con la lupa
class _SparkleStar extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;

  const _SparkleStar({
    required this.progress,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final scale = math.sin(progress * math.pi);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Icon(
          Icons.auto_awesome,
          color: color,
          size: size,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tarjeta de Vacante idéntica a Figma
// ─────────────────────────────────────────────────────────────
class _ExploreCard extends StatefulWidget {
  final Vacante vacante;
  final bool isSpanish;

  const _ExploreCard({
    super.key,
    required this.vacante,
    this.isSpanish = true,
  });

  @override
  State<_ExploreCard> createState() => _ExploreCardState();
}

class _ExploreCardState extends State<_ExploreCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.vacante;
    final isEs = widget.isSpanish;
    final initial = v.titulo.trim().isNotEmpty ? v.titulo.trim()[0].toUpperCase() : 'R';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BouncingCard(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(
                vacante: v,
                heroTagTitle: 'explore_title_${v.id}',
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFEDF2F7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila Superior: Avatar + Título + Empresa + Guardar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar cuadrado con gradiente azul y letra inicial
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F80FF), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Título y Empresa
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'explore_title_${v.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              v.tituloLocalized(isEs),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                height: 1.2,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isEs ? 'Empresa Confidencial' : 'Confidential Company',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botón Guardar / Bookmark
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isSaved = !_isSaved);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 6),
                      child: Icon(
                        _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _isSaved ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Fila de Chips / Tags (Ubicación / Modalidad y Categoría)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Tag 1: Ubicación / Remoto
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          v.ubicacionLocalized(isEs),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tag 2: Categoría / Backend
                  if (v.categoria != null && v.categoria!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hub_outlined,
                            size: 13,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            v.categoriaLocalized(isEs) ?? v.categoria!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Fila Inferior: Tiempo Relativo y Salario Verde Figma
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            v.tiempoRelativoLocalized(isEs),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFBBF7D0).withValues(alpha: 0.7),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      v.salarioDisplayLocalized(isEs),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Modal de Filtros
// ─────────────────────────────────────────────────────────────
void _showFilterBottomSheet(BuildContext context, VacantesProvider vp, bool isEs) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: kNavy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEs ? 'Especialidad' : 'Specialty',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Backend', 'Frontend', 'Fullstack', 'DevOps', 'Mobile', 'Data', 'Design']
                    .map((cat) => _FilterChip(
                          label: cat,
                          isSelected: vp.filtroCategoria == cat,
                          onTap: () {
                            vp.setCategoriaFiltro(vp.filtroCategoria == cat ? '' : cat);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
              Text(
                isEs ? 'Salario Mínimo' : 'Minimum Salary',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [3000, 5000, 8000, 10000]
                    .map((sal) => _FilterChip(
                          label: '+\$$sal',
                          isSelected: vp.filtroSalarioMin == sal.toDouble(),
                          onTap: () {
                            vp.setSalarioFiltro(
                              vp.filtroSalarioMin == sal.toDouble() ? 0 : sal.toDouble(),
                            );
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    vp.clearQuery();
                    vp.setCategoriaFiltro('');
                    vp.setSalarioFiltro(0);
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: kNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    isEs ? 'Limpiar todos los filtros' : 'Clear all filters',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                  : const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Estados de Carga, Error y Vacío
// ─────────────────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 12, color: Colors.white),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(width: 70, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                            const SizedBox(width: 8),
                            Container(width: 70, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  final bool isSpanish;

  const _ErrorState(this.msg, {required this.onRetry, this.isSpanish = true});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_outlined, size: 44, color: kMuted),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: Text(isSpanish ? 'Reintentar' : 'Retry')),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final bool isSpanish;
  const _EmptyState({this.isSpanish = true});

  @override
  Widget build(BuildContext context) => AnimatedEmptyState(
        icon: Icons.search_off_rounded,
        title: isSpanish ? AppStrings.noResults : 'No jobs found',
        subtitle: isSpanish
            ? 'Intenta ajustar tus filtros o buscar con otros\ntérminos para encontrar más vacantes.'
            : 'Try adjusting your filters or search terms\nto find more jobs.',
      );
}
