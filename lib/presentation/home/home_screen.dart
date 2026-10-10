import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_ext.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../shared/widgets/bouncing_card.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/entities/vacante.dart';
import '../job_detail/job_detail_screen.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/recomendaciones_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/ai_explanation_tile.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onExplore;
  const HomeScreen({super.key, required this.onExplore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final session    = context.read<AuthProvider>().session;
    final vProvider  = context.read<VacantesProvider>();
    final pProvider  = context.read<PostulacionesProvider>();
    final rProvider  = context.read<RecomendacionesProvider>();

    // 1. Siempre cargar vacantes (fallback del ML)
    if (vProvider.status == VacantesStatus.initial) {
      await vProvider.cargar();
    }

    // 2. Cargar postulaciones del candidato
    if (pProvider.status == PostulacionesStatus.initial &&
        session != null &&
        session.profileId.isNotEmpty) {
      await pProvider.cargar(session.profileId);
    }

    // 3. Intentar cargar recomendaciones IA (puede fallar → fallback)
    if (rProvider.status == RecomendacionesStatus.initial &&
        session != null &&
        session.profileId.isNotEmpty) {
      await rProvider.cargar(session.profileId);
    }
  }

  Widget _buildLottieRefresh(
      BuildContext context,
      RefreshIndicatorMode refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent,
      ) {
    final double percentage = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

    return Container(
      height: pulledExtent,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Opacity(
          opacity: percentage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child: SpinPerfect(
                  infinite: true,
                  spins: 2,
                  animate: refreshState == RefreshIndicatorMode.refresh || refreshState == RefreshIndicatorMode.armed,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: kBlue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: const Icon(Icons.auto_awesome, color: kBlue, size: 24),
                  ),
                ),
              ),
              if (percentage > 0.8)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Escaneando vacantes IA...', style: TextStyle(color: kBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vProvider = context.watch<VacantesProvider>();
    final rProvider = context.watch<RecomendacionesProvider>();
    final topPadding = MediaQuery.paddingOf(context).top + 15;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 100;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, // Background now handled by CandidateShell
      body: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _cargar,
                builder: _buildLottieRefresh,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(17, topPadding, 17, bottomPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Saludo Clean Tech ───────────────────────────────────────────
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: kBlue),
                          const SizedBox(width: 6),
                          Text(
                            'Recomendaciones para ti',
                            style: TextStyle(
                              color: kBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 600),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Encuentra Tu\n',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: context.text, height: 1.2),
                            ),
                            const TextSpan(
                              text: 'Trabajo Ideal',
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: kBlue, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Barra de búsqueda Premium ───────────────
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 600),
                      child: GestureDetector(
                        onTap: widget.onExplore,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: kNavy.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
                                ],
                              ),
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: kMuted, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(AppStrings.searchHint, style: const TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5C83F6), Color(0xFF2A5AF1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: kBlue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                    // ── Sección principal: IA o fallback ─────────────────
                    if (rProvider.status == RecomendacionesStatus.loading ||
                        vProvider.status == VacantesStatus.loading)
                      ..._buildLoading()
                    else if (rProvider.hasData)
                      ..._buildRecomendaciones(rProvider)
                    else if (rProvider.isFallback)
                      ..._buildFallback(vProvider)
                    else if (vProvider.status == VacantesStatus.error)
                      ...[
                        _sectionHead(AppStrings.recommended, AppStrings.seeAll, widget.onExplore),
                        _ErrorCard(vProvider.error ?? 'Error al cargar vacantes', onRetry: _cargar),
                      ]
                    else
                      ..._buildFallback(vProvider),

                    // ── Banner IA ─────────────────────────────────────────
                    const SizedBox(height: 8),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 600),
                      child: _AiBanner(isMlActive: rProvider.hasData),
                    ),
                    const SizedBox(height: 4),

                    // ── Funcionalidades ───────────────────────────────────
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 600),
                      child: _sectionHead(AppStrings.features, null, null),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 600),
                      child: const Row(children: [
                        Expanded(child: _FeatureCard(Icons.notifications_none, AppStrings.alertsTitle, AppStrings.alertsDesc)),
                        SizedBox(width: 10),
                        Expanded(child: _FeatureCard(Icons.location_on_outlined, AppStrings.localTitle, AppStrings.localDesc)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ],
          ),
    );
  }

  // ────────────────────────────────────────────────
  // Secciones
  // ────────────────────────────────────────────────

  List<Widget> _buildLoading() => [
    _sectionHead(AppStrings.recommended, null, null),
    ...List.generate(3, (index) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: context.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        highlightColor: context.surface,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    )),
  ];

  /// Lista de recomendaciones IA con badge de compatibilidad
  List<Widget> _buildRecomendaciones(RecomendacionesProvider rProvider) {
    return [
      _sectionHead('Recomendadas para ti ✦', AppStrings.seeAll, widget.onExplore),
      // Banner pequeño de estado IA
      _IaStatusChip(),
      const SizedBox(height: 10),
      ...rProvider.top4.asMap().entries.map(
        (entry) {
          final index = entry.key;
          final r = entry.value;
          return FadeInUp(
            delay: Duration(milliseconds: 100 * index),
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AiExplanationTile(
                recomendacion: r,
                onTap: () => _navigateToDetail(r, heroTag: 'ml_title_${r.vacanteId}'),
              ),
            ),
          );
        },
      ),
    ];
  }

  /// Fallback: muestra las vacantes generales sin score IA
  List<Widget> _buildFallback(VacantesProvider vProvider) {
    return [
      _sectionHead(AppStrings.recommended, AppStrings.seeAll, widget.onExplore),
      if (vProvider.vacantes.isEmpty)
        const _EmptyCard()
      else
        ...vProvider.vacantes.take(4).toList().asMap().entries.map(
          (entry) {
            final index = entry.key;
            final v = entry.value;
            return FadeInUp(
              delay: Duration(milliseconds: 100 * index),
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JobCard(vacante: v),
              ),
            );
          },
        ),
    ];
  }

  /// Navega al detalle buscando la vacante en el provider o usando un placeholder
  void _navigateToDetail(Recomendacion r, {String? heroTag}) {
    // Busca la vacante cargada en VacantesProvider (puede o no estar cargada)
    final vProvider = context.read<VacantesProvider>();
    final match = vProvider.vacantes
        .where((v) => v.id == r.vacanteId)
        .toList();

    if (match.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(
          vacante: match.first, heroTagTitle: heroTag, recomendacionML: r,
        )),
      );
    } else {
      // Si no está en caché, navega con una vacante mínima reconstruida
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            vacante: _recomendacionToVacanteMin(r),
            heroTagTitle: heroTag,
            recomendacionML: r,
          ),
        ),
      );
    }
  }

  Widget _sectionHead(String title, String? action, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.only(top: 21, bottom: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.text)),
            ),
            if (action != null)
              TextButton(
                onPressed: onTap,
                child: Text(action, style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );
}

// ────────────────────────────────────────────────
// Helper: convierte Recomendacion a Vacante mínima
// para poder navegar al detalle aunque no esté en caché
// ────────────────────────────────────────────────

Vacante _recomendacionToVacanteMin(Recomendacion r) => Vacante(
      id: r.vacanteId,
      empresaId: r.empresaId,
      titulo: r.titulo,
      descripcion: '',
      requisitos: [],
      ubicacion: '',
      estado: VacanteEstado.activa,
      creadoEn: DateTime.now(),
    );

// ────────────────────────────────────────────────
// _IaStatusChip
// ────────────────────────────────────────────────

class _IaStatusChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kMatchBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 13, color: kMatchText),
            SizedBox(width: 5),
            Text(
              'Motor IA activo — resultados personalizados',
              style: TextStyle(color: kMatchText, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

// ────────────────────────────────────────────────
// _JobCard — tarjeta premium de vacante (modo fallback)
// ────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final Vacante vacante;
  const _JobCard({required this.vacante});

  @override
  Widget build(BuildContext context) {
    return BouncingCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(vacante: vacante, heroTagTitle: 'home_title_${vacante.id}')),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: kNavy.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'home_logo_${vacante.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: _CompanyMark(vacante.ubicacion),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'home_title_${vacante.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            vacante.titulo,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.text, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business_center_outlined, size: 12, color: context.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Empresa Confidencial', 
                              style: TextStyle(color: context.textMuted, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.line.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bookmark_border_rounded, size: 18, color: context.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _JobTag(icon: Icons.location_on_outlined, text: vacante.ubicacion),
                if (vacante.categoria != null)
                  _JobTag(icon: Icons.category_outlined, text: vacante.categoria!, isBlue: true),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: context.textMuted),
                    const SizedBox(width: 4),
                    Text(vacante.tiempoRelativo, style: TextStyle(fontSize: 11, color: context.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vacante.salarioDisplay,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _CompanyMark extends StatelessWidget {
  final String text;
  const _CompanyMark(this.text);

  @override
  Widget build(BuildContext context) {
    final letters = text.trim().isNotEmpty ? text.trim()[0].toUpperCase() : '?';
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C83F6), Color(0xFF2A5AF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: kBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Text(
        letters,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
      ),
    );
  }
}

class _JobTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBlue;
  const _JobTag({required this.icon, required this.text, this.isBlue = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isBlue ? const Color(0xFFEEF2FF) : context.line.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isBlue ? kBlue : context.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isBlue ? kBlue : context.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorCard(this.msg, {required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.surface, border: Border.all(color: context.line), borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Icon(Icons.wifi_off_outlined, size: 40, color: context.textMuted),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: Text('Reintentar')),
        ]),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.surface, border: Border.all(color: context.line), borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Icon(Icons.work_outline, size: 44, color: kBlue),
          const SizedBox(height: 12),
          Text('Sin vacantes disponibles', style: TextStyle(fontWeight: FontWeight.w800, color: context.text)),
          const SizedBox(height: 6),
          Text('Pronto habrá nuevas oportunidades para ti',
              textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 12)),
        ]),
      );
}

// ────────────────────────────────────────────────
// _AiBanner — muestra estado del motor IA
// ────────────────────────────────────────────────

class _AiBanner extends StatelessWidget {
  final bool isMlActive;
  const _AiBanner({required this.isMlActive});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: kBannerGradient),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(AppStrings.aiBadge,
                  style: TextStyle(fontSize: 9, color: Color(0xFFD9E6FF), fontWeight: FontWeight.w800)),
              const Spacer(),
              if (isMlActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, color: kGreen, size: 7),
                    SizedBox(width: 4),
                    Text('ACTIVO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                  ]),
                ),
            ]),
            const SizedBox(height: 8),
            Text(AppStrings.aiTitle,
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(AppStrings.aiDesc,
                style: TextStyle(color: Color(0xFFD9E6FF), fontSize: 12, height: 1.4)),
          ],
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const _FeatureCard(this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: kNavy.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
              ]
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kBlue, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kNavy)),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(color: kMuted, fontSize: 11, height: 1.45)),
          ],
        ),
      ),
    ),
  );
}
