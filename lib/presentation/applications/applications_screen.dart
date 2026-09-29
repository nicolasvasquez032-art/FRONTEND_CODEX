import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../job_detail/job_detail_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final session = context.read<AuthProvider>().session;
    if (session == null || session.profileId.isEmpty) return;
    await context.read<PostulacionesProvider>().cargar(session.profileId);
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostulacionesProvider>();
    final vacProvider = context.watch<VacantesProvider>();

    return RefreshIndicator(
      onRefresh: _cargar,
      color: kBlue,
      child: ListView(
        padding: const EdgeInsets.all(17),
        children: [
          const Text(AppStrings.applicationsSubtitle, style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(AppStrings.applicationsTitle,
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: kNavy)),
          const SizedBox(height: 20),

          if (postsProvider.status == PostulacionesStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (postsProvider.status == PostulacionesStatus.error)
            _ErrorCard(postsProvider.error ?? 'Error', onRetry: _cargar)
          else if (postsProvider.postulaciones.isEmpty)
            _EmptyCard()
          else ...[
            // Contador
            Text(
              '${postsProvider.postulaciones.length} postulación${postsProvider.postulaciones.length != 1 ? 'es' : ''}',
              style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ...postsProvider.postulaciones.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostulacionCard(
                  postulacion: p,
                  vacante: _findVacante(vacProvider, p.vacanteId),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Vacante? _findVacante(VacantesProvider vp, String vacanteId) {
    try {
      return vp.vacantes.cast<Vacante>().firstWhere(
        (v) => v.id == vacanteId,
      );
    } catch (_) {
      return null;
    }
  }
}

// ────────────────────────────────────────────────────────
// _PostulacionCard — tarjeta con estado visual tipo badge
// ────────────────────────────────────────────────────────

class _PostulacionCard extends StatelessWidget {
  final Postulacion postulacion;
  final Vacante? vacante;

  const _PostulacionCard({required this.postulacion, required this.vacante});

  Color get _badgeColor {
    switch (postulacion.estado) {
      case PostulacionEstado.postulado:  return const Color(0xFF3B82F6);
      case PostulacionEstado.entrevista: return const Color(0xFFF59E0B);
      case PostulacionEstado.rechazado:  return const Color(0xFFEF4444);
      case PostulacionEstado.contratado: return const Color(0xFF22C55E);
    }
  }

  Color get _badgeBg {
    switch (postulacion.estado) {
      case PostulacionEstado.postulado:  return const Color(0xFFEFF6FF);
      case PostulacionEstado.entrevista: return const Color(0xFFFFFBEB);
      case PostulacionEstado.rechazado:  return const Color(0xFFFEF2F2);
      case PostulacionEstado.contratado: return const Color(0xFFF0FDF4);
    }
  }

  IconData get _badgeIcon {
    switch (postulacion.estado) {
      case PostulacionEstado.postulado:  return Icons.send_outlined;
      case PostulacionEstado.entrevista: return Icons.calendar_today_outlined;
      case PostulacionEstado.rechazado:  return Icons.cancel_outlined;
      case PostulacionEstado.contratado: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: kNavy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono de estado
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(_badgeIcon, color: _badgeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vacante?.titulo ?? 'Vacante',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kNavy),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        postulacion.estado.label,
                        style: TextStyle(color: _badgeColor, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (postulacion.scoreMatch != null)
                      Text(
                        '${(postulacion.scoreMatch! * 100).toStringAsFixed(0)}% match',
                        style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(postulacion.fecha),
                    style: const TextStyle(color: kMuted, fontSize: 10),
                  ),
                  if (vacante != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(vacante: vacante!),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kLine),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Ver detalles',
                          style: TextStyle(color: kBlue, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }
}

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(children: [
          Icon(Icons.fact_check_outlined, size: 48, color: kBlue),
          SizedBox(height: 12),
          Text(AppStrings.noApplications,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kNavy)),
          SizedBox(height: 8),
          Text(AppStrings.noApplicationsDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 12, height: 1.5)),
        ]),
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
