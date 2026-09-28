import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/vacante.dart';
import '../job_detail/job_detail_screen.dart';
import '../shared/providers/vacantes_provider.dart';

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

    return RefreshIndicator(
      onRefresh: () => vp.cargar(),
      color: kBlue,
      child: ListView(
        padding: const EdgeInsets.all(17),
        children: [
          const Text(AppStrings.exploreSubtitle, style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(AppStrings.exploreTitle,
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: kNavy)),
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
            const SizedBox(height: 12),
            ...vp.filtered.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExploreCard(vacante: v),
              ),
            ),
          ],
        ],
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

  String get _initial => vacante.ubicacion.trim().isNotEmpty ? vacante.ubicacion.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(vacante: vacante)),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kLine),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: kNavy.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 43, height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF3FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(_initial,
                    style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(vacante.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(vacante.ubicacion,
                      style: const TextStyle(color: kMuted, fontSize: 11)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: kMuted, size: 18),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: [
              _chip('📍 ${vacante.ubicacion}'),
              if (vacante.categoria != null) _chip(vacante.categoria!, blue: true),
            ]),
            const Divider(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(vacante.tiempoRelativo, style: const TextStyle(fontSize: 10, color: kMuted)),
              Text(vacante.salarioDisplay,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      );

  Widget _chip(String t, {bool blue = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: blue ? const Color(0xFFEAF1FF) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 10,
                color: blue ? const Color(0xFF245BC8) : const Color(0xFF596579))),
      );
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
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text(AppStrings.noResults, style: TextStyle(color: kMuted))),
      );
}
