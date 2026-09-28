import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/vacante.dart';
import '../job_detail/job_detail_screen.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/vacantes_provider.dart';

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
    // Carga diferida para no bloquear el build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final vProvider = context.read<VacantesProvider>();
    final pProvider = context.read<PostulacionesProvider>();
    final session = context.read<AuthProvider>().session;

    if (vProvider.status == VacantesStatus.initial) {
      await vProvider.cargar();
    }
    if (pProvider.status == PostulacionesStatus.initial &&
        session != null &&
        session.profileId.isNotEmpty) {
      await pProvider.cargar(session.profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vProvider = context.watch<VacantesProvider>();

    return RefreshIndicator(
      onRefresh: _cargar,
      color: kBlue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 20, 17, 24),
        children: [
          // ── Saludo ──
          const Text('Buenos días 👋', style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(
            'Oportunidades\npara ti',
            style: TextStyle(fontSize: 27, height: 1.1, fontWeight: FontWeight.w800, color: kNavy),
          ),
          const SizedBox(height: 18),

          // ── Barra de búsqueda (tap → explorar) ──
          GestureDetector(
            onTap: widget.onExplore,
            child: Container(
              height: 47,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  const Icon(Icons.search, color: kMuted, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(AppStrings.searchHint, style: TextStyle(color: kMuted, fontSize: 13)),
                  ),
                  Container(
                    width: 35, height: 35,
                    decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.search, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Sección Vacantes ──
          _sectionHead(AppStrings.recommended, AppStrings.seeAll, widget.onExplore),

          // Estado de carga / error / datos
          if (vProvider.status == VacantesStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vProvider.status == VacantesStatus.error)
            _ErrorCard(vProvider.error ?? 'Error al cargar vacantes', onRetry: _cargar)
          else if (vProvider.vacantes.isEmpty)
            const _EmptyCard()
          else
            ...vProvider.vacantes.take(4).map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JobCard(vacante: v),
                  ),
                ),

          // ── Banner IA ──
          const SizedBox(height: 6),
          _AiBanner(),
          const SizedBox(height: 4),

          // ── Funcionalidades ──
          _sectionHead(AppStrings.features, null, null),
          Row(children: const [
            Expanded(child: _FeatureCard(Icons.notifications_none, AppStrings.alertsTitle, AppStrings.alertsDesc)),
            SizedBox(width: 10),
            Expanded(child: _FeatureCard(Icons.location_on_outlined, AppStrings.localTitle, AppStrings.localDesc)),
          ]),
        ],
      ),
    );
  }

  Widget _sectionHead(String title, String? action, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.only(top: 21, bottom: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy)),
            ),
            if (action != null)
              TextButton(
                onPressed: onTap,
                child: Text(action, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────
// _JobCard — tarjeta de vacante (navega a JobDetailScreen)
// ────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final Vacante vacante;
  const _JobCard({required this.vacante});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _CompanyMark(vacante.ubicacion),
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
              _Tag('📍 ${vacante.ubicacion}'),
              if (vacante.categoria != null) _Tag(vacante.categoria!, blue: true),
            ]),
            const Divider(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(vacante.tiempoRelativo, style: const TextStyle(fontSize: 10, color: kMuted)),
              Text(vacante.salarioDisplay,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w700)),
            ]),
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
      width: 43, height: 43,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(11)),
      child: Text(letters, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool blue;
  const _Tag(this.text, {this.blue = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: blue ? const Color(0xFFEAF1FF) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: blue ? const Color(0xFF245BC8) : const Color(0xFF596579))),
      );
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorCard(this.msg, {required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: kLine), borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Icon(Icons.wifi_off_outlined, size: 40, color: kMuted),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: kLine), borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(children: [
          Icon(Icons.work_outline, size: 44, color: kBlue),
          SizedBox(height: 12),
          Text('Sin vacantes disponibles', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
          SizedBox(height: 6),
          Text('Pronto habrá nuevas oportunidades para ti',
              textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12)),
        ]),
      );
}

class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: kBannerGradient),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.aiBadge, style: TextStyle(fontSize: 9, color: Color(0xFFD9E6FF), fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text(AppStrings.aiTitle, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text(AppStrings.aiDesc, style: TextStyle(color: Color(0xFFD9E6FF), fontSize: 12, height: 1.4)),
          ],
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const _FeatureCard(this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: kLine), borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kBlue),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 5),
            Text(text, style: const TextStyle(color: kMuted, fontSize: 10, height: 1.45)),
          ],
        ),
      );
}
