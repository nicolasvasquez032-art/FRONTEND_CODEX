import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/vacante.dart';
import '../job_detail/job_detail_screen.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/bouncing_card.dart';
import '../shared/widgets/animated_empty_state.dart';
import 'map_screen.dart';

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
    final topPadding = MediaQuery.paddingOf(context).top + 15;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 100;

    return Scaffold(
      backgroundColor: Colors.transparent, // Mantiene el color del shell
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => vp.cargar(),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(17, topPadding, 17, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Row(
                  children: [
                    Icon(Icons.travel_explore, size: 16, color: kBlue),
                    SizedBox(width: 6),
                    Text(
                      AppStrings.exploreSubtitle,
                      style: TextStyle(
                        color: kBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Explorar\n',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kNavy, height: 1.2),
                      ),
                      TextSpan(
                        text: 'Empleos',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: kBlue, height: 1.1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Buscador ──
                TextField(
                  controller: _searchController,
                  onChanged: (v) => vp.setQuery(v),
                  decoration: InputDecoration(
                    hintText: AppStrings.searchJobHint,
                    prefixIcon: const Icon(Icons.search, color: kMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: kMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              vp.clearQuery();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filtros Rápidos ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Backend',
                        isSelected: vp.filtroCategoria == 'Backend',
                        onTap: () => vp.setCategoriaFiltro('Backend'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Frontend',
                        isSelected: vp.filtroCategoria == 'Frontend',
                        onTap: () => vp.setCategoriaFiltro('Frontend'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Fullstack',
                        isSelected: vp.filtroCategoria == 'Fullstack',
                        onTap: () => vp.setCategoriaFiltro('Fullstack'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '+\$5000',
                        isSelected: vp.filtroSalarioMin == 5000,
                        onTap: () => vp.setSalarioFiltro(5000),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '+\$8000',
                        isSelected: vp.filtroSalarioMin == 8000,
                        onTap: () => vp.setSalarioFiltro(8000),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Contenido ──
                if (vp.status == VacantesStatus.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (vp.status == VacantesStatus.error)
                  _ErrorState(vp.error ?? 'Error al cargar', onRetry: () => vp.cargar())
                else if (vp.filtered.isEmpty)
                  const _EmptyState()
                else ...[
                  Text(
                    '${vp.filtered.length} vacante${vp.filtered.length != 1 ? 's' : ''} encontrada${vp.filtered.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ]),
            ),
          ),
          if (vp.filtered.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(17, 0, 17, bottomPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final v = vp.filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExploreCard(vacante: v),
                    );
                  },
                  childCount: vp.filtered.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
          },
          backgroundColor: kBlue,
          icon: const Icon(Icons.map_outlined, color: Colors.white),
          label: const Text('Ver Mapa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// _ExploreCard — navega al detalle
// ────────────────────────────────────────────────────────

class _ExploreCard extends StatelessWidget {
  final Vacante vacante;
  const _ExploreCard({required this.vacante});

  @override
  Widget build(BuildContext context) {
    return BouncingCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(vacante: vacante, heroTagTitle: 'explore_title_${vacante.id}')),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kLine.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: kNavy.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyMark(vacante.ubicacion),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'explore_title_${vacante.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            vacante.titulo,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.business_center_outlined, size: 12, color: kMuted),
                          SizedBox(width: 4),
                          Text('Empresa Confidencial', style: TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kLine.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark_border_rounded, size: 18, color: kMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PremiumTag(icon: Icons.location_on_outlined, text: vacante.ubicacion),
                if (vacante.categoria != null)
                  _PremiumTag(icon: Icons.category_outlined, text: vacante.categoria!, isBlue: true),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 12, color: kMuted),
                    const SizedBox(width: 4),
                    Text(vacante.tiempoRelativo, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w500)),
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
        letters,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
      ),
    );
  }
}

class _PremiumTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBlue;
  const _PremiumTag({required this.icon, required this.text, this.isBlue = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isBlue ? const Color(0xFFEEF2FF) : kLine.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isBlue ? kBlue : kMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isBlue ? kBlue : kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorState(this.msg, {required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          const Icon(Icons.wifi_off_outlined, size: 44, color: kMuted),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const AnimatedEmptyState(
        icon: Icons.search_off_rounded,
        title: AppStrings.noResults,
        subtitle: 'Intenta ajustar tus filtros o buscar con otros\ntérminos para encontrar más vacantes.',
      );
}

// ────────────────────────────────────────────────────────
// Widget: Chip de Filtro Interactivo
// ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? kBlue : kLine),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kMuted,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
