import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/vacante.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/notificaciones_provider.dart';
import '../shared/providers/perfil_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/recomendaciones_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/talentmatch_top_header.dart';
import 'models/display_job.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/home_job_card.dart';
import 'widgets/home_search_and_filters.dart';
import 'widgets/home_section_header.dart';
import 'widgets/home_state_cards.dart';

/// Pantalla Home modularizada de TalentMatch reproduciendo fielmente el diseño de Figma.
///
/// Arquitectura desacoplada:
/// - Cabecera superior unificada: [TalentMatchTopHeader]
/// - Hero Section interactivo con maletín 3D animado: [HomeHeroSection]
/// - Barra de búsqueda y chips de filtro rápido: [HomeSearchBar], [HomeFilterChipsRow]
/// - Encabezado de sección: [HomeSectionHeader]
/// - Tarjetas de vacante con anti-overflow y match score IA: [HomeJobCard]
/// - Estados dinámicos (análisis IA, sin CV, vacío, skeletons): [HomeStateCards]
class HomeScreen extends StatefulWidget {
  final VoidCallback onExplore;
  final VoidCallback? onGoToProfile;

  const HomeScreen({
    super.key,
    required this.onExplore,
    this.onGoToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _filterRemote = false;
  String? _selectedCategory;
  String? _selectedLocation;
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final session = context.read<AuthProvider>().session;
    final vProvider = context.read<VacantesProvider>();
    final pProvider = context.read<PostulacionesProvider>();
    final rProvider = context.read<RecomendacionesProvider>();
    final nProvider = context.read<NotificacionesProvider>();
    final perfilProvider = Provider.of<PerfilProvider?>(context, listen: false);

    // 1. Cargar vacantes activas
    if (vProvider.status == VacantesStatus.initial) {
      await vProvider.cargar();
    } else {
      vProvider.cargar();
    }

    // 2. Cargar notificaciones del usuario si hay sesión
    if (session != null && session.userId.isNotEmpty) {
      nProvider.cargar(session.userId);
    }

    // 3. Cargar perfil y postulaciones del candidato si hay sesión
    if (session != null && session.profileId.isNotEmpty) {
      perfilProvider?.cargar(session.profileId);
      if (pProvider.status == PostulacionesStatus.initial) {
        pProvider.cargar(session.profileId);
      }
      // 4. Cargar recomendaciones IA
      rProvider.cargar(session.profileId);
    }
  }

  List<DisplayJob> _resolveDisplayJobs(
    VacantesProvider vProvider,
    RecomendacionesProvider rProvider,
    bool isEs,
    bool hasSession,
  ) {
    List<DisplayJob> list = [];

    // Prioridad 1: Recomendaciones IA activas
    if (rProvider.hasData && rProvider.recomendaciones.isNotEmpty) {
      for (final rec in rProvider.recomendaciones) {
        final match = vProvider.vacantes
            .where((v) => v.id == rec.vacanteId)
            .toList();

        final Vacante v = match.isNotEmpty
            ? match.first
            : Vacante(
                id: rec.vacanteId,
                empresaId: rec.empresaId,
                titulo: rec.titulo,
                descripcion: (rec.descripcion != null &&
                        rec.descripcion!.trim().isNotEmpty)
                    ? rec.descripcion!
                    : rec.explicacion,
                requisitos: rec.requisitos ?? [],
                ubicacion: rec.ubicacion ?? 'Remoto',
                categoria: rec.categoria ?? 'Tecnología',
                estado: VacanteEstado.activa,
                creadoEn: DateTime.now().subtract(const Duration(hours: 23)),
                salarioMin: rec.salarioMin ?? 3000,
                salarioMax: rec.salarioMax ?? 5000,
              );

        list.add(DisplayJob.fromVacante(
          v: v,
          isEs: isEs,
          customMatch: rec.scorePercent,
          rec: rec,
        ));
      }
    } else if (vProvider.vacantes.isNotEmpty) {
      // Si el candidato no tiene recomendaciones IA aún pero hay vacantes activas en el sistema,
      // mostrar las vacantes activas para que el usuario siempre vea oportunidades.
      for (final v in vProvider.vacantes) {
        list.add(DisplayJob.fromVacante(
          v: v,
          isEs: isEs,
        ));
      }
    } else if (!hasSession) {
      // Si el usuario no ha iniciado sesión (modo preview o testing), provee las del Figma como default
      list = DisplayJob.getFigmaDefaults(isEs);
    }

    // Aplicar filtro de Remoto si está activo
    if (_filterRemote) {
      list = list.where((j) {
        final loc = j.location.toLowerCase();
        final desc = j.vacante.descripcion.toLowerCase();
        return loc.contains('remoto') ||
            loc.contains('remote') ||
            desc.contains('remoto');
      }).toList();
    }

    // Aplicar filtro de categoría si está seleccionado
    if (_selectedCategory != null) {
      list = list.where((j) {
        return j.category
            .toLowerCase()
            .contains(_selectedCategory!.toLowerCase());
      }).toList();
    }

    // Aplicar filtro de ubicación si está seleccionado
    if (_selectedLocation != null && _selectedLocation != 'Colombia') {
      list = list.where((j) {
        return j.location
            .toLowerCase()
            .contains(_selectedLocation!.toLowerCase());
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final vProvider = context.watch<VacantesProvider>();
    final rProvider = context.watch<RecomendacionesProvider>();
    final perfilProvider = Provider.of<PerfilProvider?>(context);
    final isEs = context.watch<LocaleProvider>().isSpanish;

    final hasSession =
        authProvider.session != null && authProvider.session!.userId.isNotEmpty;
    final hasCv = perfilProvider?.hasCv ?? false;
    final profileId = authProvider.session?.profileId ?? '';

    // Resuelve lista de vacantes a renderizar según recomendaciones y filtros
    final jobs = _resolveDisplayJobs(vProvider, rProvider, isEs, hasSession);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 0.6, 1.0],
            colors: [
              Color(0xFFE8F1FC),
              Color(0xFFF1F5FC),
              Color(0xFFF5F8FD),
              Color(0xFFEDF2FA),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top Header unificado idéntico a Figma ──
              const TalentMatchTopHeader(),

              // ── Contenido con Pull-to-refresh ───────────────────
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: _cargar,
                      builder: buildHomeRefreshIndicator,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 1. Hero Section con Maletero Animado
                          HomeHeroSection(isSpanish: isEs),
                          const SizedBox(height: 20),

                          // 2. Barra de Búsqueda Figma
                          HomeSearchBar(
                            onTap: widget.onExplore,
                            isSpanish: isEs,
                          ),
                          const SizedBox(height: 16),

                          // 3. Chips de Filtro (✓ Remoto, Tecnología ⌵, Colombia ⌵)
                          HomeFilterChipsRow(
                            isSpanish: isEs,
                            filterRemote: _filterRemote,
                            selectedCategory: _selectedCategory,
                            selectedLocation: _selectedLocation,
                            onRemoteChanged: (val) {
                              setState(() => _filterRemote = val);
                            },
                            onCategorySelected: (cat) {
                              setState(() => _selectedCategory = cat);
                            },
                            onLocationSelected: (loc) {
                              setState(() => _selectedLocation = loc);
                            },
                          ),
                          const SizedBox(height: 24),

                          // 4. Encabezado de Sección: Recomendadas para ti
                          HomeSectionHeader(
                            isSpanish: isEs,
                            onSeeAll: widget.onExplore,
                          ),
                          const SizedBox(height: 14),

                          // 5. Lista de Tarjetas o Estados de Carga
                          if (hasSession &&
                              hasCv &&
                              rProvider.recomendaciones.isEmpty)
                            HomeAiAnalyzingCard(
                              isSpanish: isEs,
                              profileId: profileId,
                              onRefresh: () {
                                if (profileId.isNotEmpty) {
                                  rProvider.cargar(profileId);
                                }
                              },
                            )
                          else if (hasSession && !hasCv)
                            HomeAiEmptyStateCard(
                              isSpanish: isEs,
                              onCompleteProfile: () {
                                if (widget.onGoToProfile != null) {
                                  widget.onGoToProfile!();
                                } else {
                                  Navigator.pushNamed(context, '/profile');
                                }
                              },
                              onExplore: widget.onExplore,
                            )
                          else if (rProvider.status ==
                              RecomendacionesStatus.loading)
                            HomeAiAnalyzingCard(
                              isSpanish: isEs,
                              profileId: profileId,
                              onRefresh: () {
                                if (profileId.isNotEmpty) {
                                  rProvider.cargar(profileId);
                                }
                              },
                            )
                          else if (vProvider.status ==
                                  VacantesStatus.loading &&
                              jobs.isEmpty)
                            const HomeLoadingSkeletons()
                          else if (jobs.isEmpty)
                            HomeEmptyState(
                              isSpanish: isEs,
                              onClearFilters: () {
                                setState(() {
                                  _filterRemote = false;
                                  _selectedCategory = null;
                                  _selectedLocation = null;
                                });
                              },
                            )
                          else
                            ...jobs.map(
                              (item) => HomeJobCard(
                                item: item,
                                isSpanish: isEs,
                                isBookmarked:
                                    _bookmarkedIds.contains(item.id),
                                onBookmarkToggle: () {
                                  setState(() {
                                    if (_bookmarkedIds.contains(item.id)) {
                                      _bookmarkedIds.remove(item.id);
                                    } else {
                                      _bookmarkedIds.add(item.id);
                                    }
                                  });
                                },
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
      ),
    );
  }
}
