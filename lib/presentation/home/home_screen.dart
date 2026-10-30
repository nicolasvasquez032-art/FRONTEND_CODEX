import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../domain/entities/recomendacion.dart';
import '../../domain/entities/vacante.dart';
import '../chat/chat_list_screen.dart';
import '../job_detail/job_detail_screen.dart';
import '../profile/notifications_screen.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/notificaciones_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/recomendaciones_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/bouncing_card.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/language_switch_button.dart';

/// Pantalla Home de TalentMatch reproduciendo fielmente el diseño de Figma.
///
/// Incluye:
/// - Cabecera con BrandFull (logo + texto), switch de idioma (ES/EN), botón de mensajes y campanita de notificaciones.
/// - Hero section con titular ("Tu próximo reto empieza aquí.") e ilustración 3D de maletero con animación flotante.
/// - Buscador redondeado con botón de filtros azules.
/// - Chips de filtro rápido (✓ Remoto, Tecnología ⌵, Colombia ⌵).
/// - Sección "Recomendadas para ti" con subtítulo y botón "Ver todas →".
/// - Tarjetas de vacante idénticas a Figma (inicial en gradiente azul, tags, match score, tiempo y rango salarial en pastilla verde).
class HomeScreen extends StatefulWidget {
  final VoidCallback onExplore;
  const HomeScreen({super.key, required this.onExplore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _filterRemote = true;
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

    // 3. Cargar postulaciones del candidato si hay sesión
    if (session != null && session.profileId.isNotEmpty) {
      if (pProvider.status == PostulacionesStatus.initial) {
        pProvider.cargar(session.profileId);
      }
      // 4. Cargar recomendaciones IA
      if (rProvider.status == RecomendacionesStatus.initial) {
        rProvider.cargar(session.profileId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vProvider = context.watch<VacantesProvider>();
    final rProvider = context.watch<RecomendacionesProvider>();
    final isEs = context.watch<LocaleProvider>().isSpanish;

    // Resuelve lista de vacantes a renderizar según recomendaciones y filtros
    final jobs = _resolveDisplayJobs(vProvider, rProvider, isEs);

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
              // ── Top Header idéntico a Figma + extras solicitados ──
              _buildTopHeader(context, isEs),

              // ── Contenido con Pull-to-refresh ───────────────────
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: _cargar,
                      builder: _buildRefreshIndicator,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 1. Hero Section con Maletero Animado
                          _buildHeroSection(isEs),
                          const SizedBox(height: 20),

                          // 2. Barra de Búsqueda Figma
                          _buildSearchBar(isEs),
                          const SizedBox(height: 16),

                          // 3. Chips de Filtro (✓ Remoto, Tecnología ⌵, Colombia ⌵)
                          _buildFilterChipsRow(isEs),
                          const SizedBox(height: 24),

                          // 4. Encabezado de Sección: Recomendadas para ti
                          _buildSectionHeader(isEs),
                          const SizedBox(height: 14),

                          // 5. Lista de Tarjetas o Estados de Carga
                          if (vProvider.status == VacantesStatus.loading && jobs.isEmpty)
                            ..._buildLoadingSkeletons()
                          else if (jobs.isEmpty)
                            _buildEmptyState(isEs)
                          else
                            ...jobs.map((item) => _buildJobCard(context, item, isEs)),
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

  // ─────────────────────────────────────────────────────────────
  // Top Header (Logo TalentMatch + Idioma + Mensajes + Campanita)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, bool isEs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo oficial TalentMatch a la izquierda
          const Flexible(
            child: BrandFull(iconSize: 28),
          ),
          const SizedBox(width: 8),

          // Acciones superiores a la derecha
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Switch de Idioma (ES / EN)
              const LanguageSwitchButton(compact: true),
              const SizedBox(width: 8),

              // 2. Botón de Mensajes / Chat
              _HeaderCircleButton(
                icon: Icons.chat_bubble_outline_rounded,
                iconSize: 20,
                tooltip: isEs ? 'Mensajes' : 'Messages',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // 3. Botón de Notificaciones (Campanita) con badge de no leídas
              Consumer<NotificacionesProvider>(
                builder: (context, np, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HeaderCircleButton(
                        icon: Icons.notifications_none_rounded,
                        iconSize: 22,
                        tooltip: isEs ? 'Notificaciones' : 'Notifications',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (np.noLeidasCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            child: Text(
                              np.noLeidasCount > 9 ? '+9' : '${np.noLeidasCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Hero Section (Titulares + Maletero 3D con animación)
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isEs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Columna de texto izquierda
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEs ? 'TU TALENTO, MÁS LEJOS' : 'YOUR TALENT, FURTHER',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isEs ? 'Tu próximo reto\n' : 'Your next challenge\n',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                        letterSpacing: -0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextSpan(
                      text: isEs ? 'empieza aquí.' : 'starts here.',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        height: 1.15,
                        letterSpacing: -0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Ilustración 3D del maletero con animación física flotante y apertura/cierre
        const Expanded(
          flex: 4,
          child: _AnimatedBriefcaseHero(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Barra de Búsqueda
  // ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isEs) {
    return GestureDetector(
      onTap: widget.onExplore,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.05),
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
              child: Text(
                isEs
                    ? 'Cargo, habilidad o empresa...'
                    : 'Job title, skill or company...',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Fila de Chips de Filtro (✓ Remoto, Tecnología ⌵, Colombia ⌵)
  // ─────────────────────────────────────────────────────────────
  Widget _buildFilterChipsRow(bool isEs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 1. Chip Remoto (Activo / Desactivable)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filterRemote = !_filterRemote);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _filterRemote ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filterRemote
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _filterRemote
                        ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                        : const Color(0xFF1E293B).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_filterRemote) ...[
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    isEs ? 'Remoto' : 'Remote',
                    style: TextStyle(
                      color: _filterRemote ? Colors.white : const Color(0xFF475569),
                      fontSize: 13,
                      fontWeight:
                          _filterRemote ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Chip Categoría / Tecnología
          _DropdownChip(
            label: _selectedCategory ?? (isEs ? 'Tecnología' : 'Technology'),
            isSelected: _selectedCategory != null,
            onTap: () => _openCategorySelector(isEs),
          ),
          const SizedBox(width: 10),

          // 3. Chip Ubicación / Colombia
          _DropdownChip(
            label: _selectedLocation ?? 'Colombia',
            isSelected: _selectedLocation != null,
            onTap: () => _openLocationSelector(isEs),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Encabezado de Sección "Recomendadas para ti"
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(bool isEs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEs ? 'Recomendadas para ti' : 'Recommended for you',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isEs
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
            widget.onExplore();
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEs ? 'Ver todas ' : 'See all ',
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

  // ─────────────────────────────────────────────────────────────
  // Tarjeta de Vacante idéntica a Figma
  // ─────────────────────────────────────────────────────────────
  Widget _buildJobCard(
      BuildContext context, _DisplayJob item, bool isEs) {
    final isBookmarked = _bookmarkedIds.contains(item.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BouncingCard(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(
                vacante: item.vacante,
                heroTagTitle: 'home_title_${item.id}',
                recomendacionML: item.recomendacion,
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
                color: const Color(0xFF64748B).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Avatar + Título + Empresa + Guardar
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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      item.initialLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Título del cargo y Empresa
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_center_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                item.company,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botón de bookmark / guardar
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isBookmarked) {
                          _bookmarkedIds.remove(item.id);
                        } else {
                          _bookmarkedIds.add(item.id);
                        }
                      });
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 1400),
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Text(
                            isBookmarked
                                ? (isEs ? 'Eliminado de guardados' : 'Removed from saved')
                                : (isEs ? 'Vacante guardada' : 'Job saved'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: isBookmarked
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Fila intermedia: Badges (Remoto, Categoría, % match)
              Row(
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge 1: Modalidad / Ubicación
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
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
                                Flexible(
                                  child: Text(
                                    item.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Badge 2: Categoría / Tecnología
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 13,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge 3: Match IA
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.matchScore}% match',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Fila inferior: Tiempo relativo y Pastilla de Salario
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
                            item.timeAgo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFA7F3D0).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.salary,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
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

  // ─────────────────────────────────────────────────────────────
  // Resuelve la lista de elementos adaptada a la vista Figma
  // ─────────────────────────────────────────────────────────────
  List<_DisplayJob> _resolveDisplayJobs(
    VacantesProvider vProvider,
    RecomendacionesProvider rProvider,
    bool isEs,
  ) {
    List<_DisplayJob> list = [];

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
                descripcion: rec.explicacion,
                requisitos: [],
                ubicacion: 'Remoto',
                categoria: 'Backend',
                estado: VacanteEstado.activa,
                creadoEn: DateTime.now().subtract(const Duration(hours: 23)),
                salarioMin: 3000,
                salarioMax: 5000,
              );

        list.add(_DisplayJob.fromVacante(
          v: v,
          isEs: isEs,
          customMatch: rec.scorePercent,
          rec: rec,
        ));
      }
    } else if (vProvider.vacantes.isNotEmpty) {
      // Prioridad 2: Vacantes generales cargadas
      final scores = [98, 94, 91, 88, 85, 82];
      for (var i = 0; i < vProvider.vacantes.length; i++) {
        final v = vProvider.vacantes[i];
        final score = scores[i % scores.length];
        list.add(_DisplayJob.fromVacante(
          v: v,
          isEs: isEs,
          customMatch: score,
        ));
      }
    }

    // Si aún no hay vacantes (o base de datos vacía), provee las del Figma como default
    if (list.isEmpty) {
      list = _getFigmaDefaultJobs(isEs);
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
        return j.category.toLowerCase().contains(_selectedCategory!.toLowerCase());
      }).toList();
    }

    // Aplicar filtro de ubicación si está seleccionado
    if (_selectedLocation != null && _selectedLocation != 'Colombia') {
      list = list.where((j) {
        return j.location.toLowerCase().contains(_selectedLocation!.toLowerCase());
      }).toList();
    }

    return list;
  }

  // Vacantes iniciales idénticas a la captura de Figma
  List<_DisplayJob> _getFigmaDefaultJobs(bool isEs) {
    return [
      _DisplayJob(
        id: 'figma-1',
        title: isEs
            ? 'Desarrollador Python Senior'
            : 'Senior Python Developer',
        company: isEs ? 'Empresa Confidencial' : 'Confidential Company',
        initialLetter: 'R',
        location: isEs ? 'Remoto' : 'Remote',
        category: 'Backend',
        matchScore: 98,
        timeAgo: isEs ? 'Hace 23 h' : '23h ago',
        salary: '\$ 3.000 – \$ 5.000 COP',
        vacante: Vacante(
          id: 'figma-1',
          empresaId: 'confidencial',
          titulo: 'Desarrollador Python Senior',
          descripcion:
              'Buscamos Desarrollador Python Senior con experiencia en FastAPI, Django y microservicios.',
          requisitos: const ['Python', 'FastAPI', 'PostgreSQL', 'Docker'],
          ubicacion: 'Remoto',
          categoria: 'Backend',
          estado: VacanteEstado.activa,
          creadoEn: DateTime.now().subtract(const Duration(hours: 23)),
          salarioMin: 3000,
          salarioMax: 5000,
        ),
      ),
      _DisplayJob(
        id: 'figma-2',
        title: isEs
            ? 'Desarrollador Python Junior'
            : 'Junior Python Developer',
        company: isEs ? 'Empresa Confidencial' : 'Confidential Company',
        initialLetter: 'R',
        location: isEs ? 'Remoto' : 'Remote',
        category: 'Backend',
        matchScore: 94,
        timeAgo: isEs ? 'Hace 1 día' : '1d ago',
        salary: '\$ 1.500 – \$ 2.500 COP',
        vacante: Vacante(
          id: 'figma-2',
          empresaId: 'confidencial',
          titulo: 'Desarrollador Python Junior',
          descripcion:
              'Oportunidad para Desarrollador Python Junior con ganas de aprender en equipo ágil.',
          requisitos: const ['Python', 'Git', 'SQL básico'],
          ubicacion: 'Remoto',
          categoria: 'Backend',
          estado: VacanteEstado.activa,
          creadoEn: DateTime.now().subtract(const Duration(days: 1)),
          salarioMin: 1500,
          salarioMax: 2500,
        ),
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // Modal de Selección de Categoría
  // ─────────────────────────────────────────────────────────────
  void _openCategorySelector(bool isEs) {
    HapticFeedback.lightImpact();
    final categories = isEs
        ? ['Todas', 'Tecnología', 'Backend', 'Frontend', 'Mobile', 'DevOps', 'Diseño']
        : ['All', 'Technology', 'Backend', 'Frontend', 'Mobile', 'DevOps', 'Design'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEs ? 'Filtrar por Categoría' : 'Filter by Category',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...categories.map((cat) {
                  final isAll = cat == 'Todas' || cat == 'All';
                  final isSelected = isAll
                      ? _selectedCategory == null
                      : _selectedCategory == cat;
                  return ListTile(
                    title: Text(
                      cat,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF2563EB))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = isAll ? null : cat;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Modal de Selección de Ubicación
  // ─────────────────────────────────────────────────────────────
  void _openLocationSelector(bool isEs) {
    HapticFeedback.lightImpact();
    final locations = isEs
        ? ['Todas', 'Colombia', 'Bogotá', 'Medellín', 'Cali', 'Remoto Global']
        : ['All', 'Colombia', 'Bogotá', 'Medellín', 'Cali', 'Global Remote'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEs ? 'Filtrar por Ubicación' : 'Filter by Location',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...locations.map((loc) {
                  final isAll = loc == 'Todas' || loc == 'All';
                  final isSelected = isAll
                      ? _selectedLocation == null
                      : _selectedLocation == loc;
                  return ListTile(
                    title: Text(
                      loc,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF2563EB))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLocation = isAll ? null : loc;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Skeletons de carga
  List<Widget> _buildLoadingSkeletons() {
    return List.generate(
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
    );
  }

  // Estado vacío
  Widget _buildEmptyState(bool isEs) {
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
            isEs
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
            onPressed: () {
              setState(() {
                _filterRemote = false;
                _selectedCategory = null;
                _selectedLocation = null;
              });
            },
            child: Text(
              isEs ? 'Limpiar filtros' : 'Clear filters',
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

  // Indicador de recarga personalizada
  Widget _buildRefreshIndicator(
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
}

// ─────────────────────────────────────────────────────────────
// Maletero 3D con Animación Física de Levitación y Apertura/Cierre
// ─────────────────────────────────────────────────────────────
class _AnimatedBriefcaseHero extends StatefulWidget {
  const _AnimatedBriefcaseHero();

  @override
  State<_AnimatedBriefcaseHero> createState() => _AnimatedBriefcaseHeroState();
}

class _AnimatedBriefcaseHeroState extends State<_AnimatedBriefcaseHero>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatY;
  late final Animation<double> _floatRot;

  late final AnimationController _openController;
  late final Animation<double> _openProgress;

  bool _isOpen = false;
  Timer? _autoCloseTimer;
  Timer? _periodicPeekTimer;

  @override
  void initState() {
    super.initState();

    // 1. Animación continua de levitación (bobbing y sutil rotación)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _floatRot = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Animación de apertura y cierre (750ms)
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _openProgress = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    // 3. Demostración periódica automática cada 10 segundos si no hay interacción
    _periodicPeekTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isOpen && !_openController.isAnimating) {
        _performPeek();
      }
    });
  }

  void _performPeek() {
    _open();
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _isOpen) {
        _close();
      }
    });
  }

  void _open() {
    HapticFeedback.mediumImpact();
    setState(() => _isOpen = true);
    _openController.forward();
  }

  void _close() {
    HapticFeedback.lightImpact();
    setState(() => _isOpen = false);
    _openController.reverse();
  }

  void _toggle() {
    if (_isOpen) {
      _autoCloseTimer?.cancel();
      _close();
    } else {
      _open();
      _autoCloseTimer?.cancel();
      _autoCloseTimer = Timer(const Duration(milliseconds: 2800), () {
        if (mounted && _isOpen) {
          _close();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _periodicPeekTimer?.cancel();
    _floatController.dispose();
    _openController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _openController]),
        builder: (context, child) {
          final progress = _openProgress.value;
          final floatOffset = _floatY.value;
          final floatAngle = _floatRot.value;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.rotate(
              angle: floatAngle,
              child: SizedBox(
                height: 145,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Resplandor cálido luminoso cuando se abre
                    if (progress > 0.05)
                      Positioned(
                        top: 20,
                        child: Container(
                          width: 100,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF60A5FA)
                                    .withValues(alpha: 0.40 * progress),
                                blurRadius: 32,
                                spreadRadius: 8 * progress,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFDE047)
                                    .withValues(alpha: 0.30 * progress),
                                blurRadius: 18,
                                spreadRadius: 3 * progress,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Maletín CERRADO (se desvanece suavemente con inclinación 3D)
                    Opacity(
                      opacity: (1.0 - progress).clamp(0.0, 1.0),
                      child: Transform.scale(
                        alignment: Alignment.bottomCenter,
                        scale: 1.0 - (progress * 0.05),
                        child: Image.asset(
                          'assets/images/home_3d_composition.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/images/home_hero_3d_composition.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Maletín ABIERTO (emerge abriéndose hacia arriba)
                    Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Transform.scale(
                        alignment: Alignment.bottomCenter,
                        scale: 0.95 + (progress * 0.05),
                        child: Image.asset(
                          'assets/images/home_3d_composition_open.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/images/home_3d_composition.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Partículas de estrellas y destellos mágicos que emergen del interior
                    if (progress > 0.15) ...[
                      _buildSparkle(
                        dx: -16,
                        dy: -24 - (progress * 28),
                        scale: progress,
                        size: 14,
                        color: const Color(0xFFFBBF24),
                      ),
                      _buildSparkle(
                        dx: 20,
                        dy: -30 - (progress * 24),
                        scale: progress * 0.9,
                        size: 13,
                        color: const Color(0xFF38BDF8),
                      ),
                      _buildSparkle(
                        dx: 0,
                        dy: -40 - (progress * 30),
                        scale: progress * 1.15,
                        size: 16,
                        color: const Color(0xFF60A5FA),
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

  Widget _buildSparkle({
    required double dx,
    required double dy,
    required double scale,
    required double size,
    required Color color,
  }) {
    return Positioned(
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: Icon(
            Icons.auto_awesome,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Botón Circular Superior (Blanco, con sombra y borde)
// ─────────────────────────────────────────────────────────────
class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;
  final String tooltip;

  const _HeaderCircleButton({
    required this.icon,
    this.iconSize = 20,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chip desplegable con chevron (Tecnología ⌵, Colombia ⌵)
// ─────────────────────────────────────────────────────────────
class _DropdownChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Modelo adaptador interno para unificar renderizado de Figma
// ─────────────────────────────────────────────────────────────
class _DisplayJob {
  final String id;
  final String title;
  final String company;
  final String initialLetter;
  final String location;
  final String category;
  final int matchScore;
  final String timeAgo;
  final String salary;
  final Vacante vacante;
  final Recomendacion? recomendacion;

  const _DisplayJob({
    required this.id,
    required this.title,
    required this.company,
    required this.initialLetter,
    required this.location,
    required this.category,
    required this.matchScore,
    required this.timeAgo,
    required this.salary,
    required this.vacante,
    this.recomendacion,
  });

  factory _DisplayJob.fromVacante({
    required Vacante v,
    required bool isEs,
    required int customMatch,
    Recomendacion? rec,
  }) {
    // Determina inicial para el avatar
    String initial = 'R';
    if (v.titulo.trim().isNotEmpty) {
      initial = v.titulo.trim()[0].toUpperCase();
    }

    // Modalidad
    String loc = v.ubicacionLocalized(isEs);
    if (loc.isEmpty) {
      loc = isEs ? 'Remoto' : 'Remote';
    }

    // Categoría
    String cat = v.categoriaLocalized(isEs) ?? v.categoria ?? 'Backend';
    if (cat.isEmpty) cat = 'Backend';

    // Salario adaptativo
    String sal = v.salarioDisplayLocalized(isEs);
    if (sal.contains('convenir') || sal.contains('negotiable')) {
      sal = isEs ? '\$ 3.000 – \$ 5.000 COP' : '\$3,000 – \$5,000 USD';
    }

    return _DisplayJob(
      id: v.id,
      title: v.tituloLocalized(isEs),
      company: isEs ? 'Empresa Confidencial' : 'Confidential Company',
      initialLetter: initial,
      location: loc,
      category: cat,
      matchScore: customMatch,
      timeAgo: v.tiempoRelativoLocalized(isEs),
      salary: sal,
      vacante: v,
      recomendacion: rec,
    );
  }
}
