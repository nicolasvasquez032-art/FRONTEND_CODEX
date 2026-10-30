import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/animated_empty_state.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/talentmatch_top_header.dart';
import '../job_detail/job_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

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
    final l10n = AppLocalizations.of(context);
    final isEs = context.watch<LocaleProvider>().isSpanish;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TalentMatchTopHeader(),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: _cargar,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(17, 10, 17, 16),
                    sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    const Icon(Icons.timeline_outlined, size: 16, color: kBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isEs ? AppStrings.applicationsSubtitle : 'Tracking',
                        style: const TextStyle(
                          color: kBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.applicationsTitle}\n',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kBlue, height: 1.1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (postsProvider.status == PostulacionesStatus.loading)
                  const _ShimmerApplicationsList()
                else if (postsProvider.status == PostulacionesStatus.error)
                  _ErrorCard(postsProvider.error ?? (isEs ? 'Error' : 'Error'), onRetry: _cargar)
                else if (postsProvider.postulaciones.isEmpty)
                  _EmptyCard(l10n)
                else ...[
                  // Contador
                  Text(
                    '${postsProvider.postulaciones.length} ${isEs ? (postsProvider.postulaciones.length != 1 ? 'postulaciones' : 'postulación') : (postsProvider.postulaciones.length != 1 ? 'applications' : 'application')}',
                    style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ]),
            ),
          ),
          if (postsProvider.postulaciones.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(17, 0, 17, bottomPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = postsProvider.postulaciones[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * (index % 10)),
                      duration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PostulacionCard(
                          postulacion: p,
                          vacante: _findVacante(vacProvider, p.vacanteId),
                          isSpanish: isEs,
                        ),
                      ),
                    );
                  },
                  childCount: postsProvider.postulaciones.length,
                ),
              ),
            ),
                ],
              ),
            ),
          ],
        ),
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
  final bool isSpanish;

  const _PostulacionCard({required this.postulacion, required this.vacante, this.isSpanish = true});

  @override
  Widget build(BuildContext context) => GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    vacante?.tituloLocalized(isSpanish) ?? (isSpanish ? 'Vacante' : 'Job'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (postulacion.scoreMatch != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(postulacion.scoreMatch! * 100).toStringAsFixed(0)}% Match',
                      style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                // Menú de opciones (Cancelar)
                if (postulacion.estado == PostulacionEstado.postulado)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: kMuted, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) async {
                      if (value == 'cancelar') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(isSpanish ? 'Cancelar postulación' : 'Cancel application', style: const TextStyle(fontWeight: FontWeight.w800)),
                            content: Text(
                              isSpanish
                                  ? '¿Estás seguro de que deseas retirar tu postulación a esta vacante? No podrás deshacer esta acción.'
                                  : 'Are you sure you want to withdraw your application? This action cannot be undone.',
                              style: const TextStyle(color: kMuted, height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(isSpanish ? 'Volver' : 'Go back', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), elevation: 0),
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(isSpanish ? 'Sí, retirarme' : 'Yes, withdraw', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final prov = context.read<PostulacionesProvider>();
                          final ok = await prov.cancelar(postulacion.id);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(prov.error ?? (isSpanish ? 'Error al cancelar' : 'Error cancelling'), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'cancelar',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 8),
                            Text(isSpanish ? 'Retirar postulación' : 'Withdraw application', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(postulacion.fecha),
              style: const TextStyle(color: kMuted, fontSize: 11),
            ),
            const SizedBox(height: 24),

            // ── Timeline Visual ──
            _TimelineTracker(currentState: postulacion.estado, isSpanish: isSpanish),

            if (vacante != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 40,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isSpanish ? 'Ver detalles de la vacante' : 'View job details',
                    style: const TextStyle(color: kBlue, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return isSpanish ? 'Postulado hoy' : 'Applied today';
    if (diff.inDays == 1) return isSpanish ? 'Postulado ayer' : 'Applied yesterday';
    return isSpanish ? 'Postulado hace ${diff.inDays} días' : 'Applied ${diff.inDays}d ago';
  }
}

// ────────────────────────────────────────────────────────
// Widget: Rastreador de línea de tiempo de la postulación
// ────────────────────────────────────────────────────────

class _TimelineTracker extends StatelessWidget {
  final PostulacionEstado currentState;
  final bool isSpanish;

  const _TimelineTracker({required this.currentState, this.isSpanish = true});

  @override
  Widget build(BuildContext context) {
    final isRechazado = currentState == PostulacionEstado.rechazado;
    
    int currentStep = 0;
    if (currentState == PostulacionEstado.entrevista) currentStep = 1;
    if (currentState == PostulacionEstado.contratado) currentStep = 2;
    if (isRechazado) currentStep = -1; // Detenido

    return Row(
      children: [
        _buildNode(
          label: isSpanish ? 'Enviada' : 'Submitted',
          isActive: currentStep >= 0 || isRechazado, 
          isDone: currentStep > 0 || isRechazado,
          isError: false,
        ),
        _buildLine(isActive: currentStep > 0 || isRechazado),
        _buildNode(
          label: isSpanish ? 'En revisión' : 'Under Review',
          isActive: currentStep >= 1 || isRechazado,
          isDone: currentStep > 1,
          isError: false,
        ),
        _buildLine(isActive: currentStep > 1 || (isRechazado && currentStep >= 1)),
        if (isRechazado)
          _buildNode(
            label: isSpanish ? 'Cerrada' : 'Closed',
            isActive: true,
            isDone: true,
            isError: true,
          )
        else
          _buildNode(
            label: isSpanish ? 'Aceptado' : 'Accepted',
            isActive: currentStep >= 2,
            isDone: currentStep == 2,
            isError: false,
          ),
      ],
    );
  }

  Widget _buildNode({required String label, required bool isActive, required bool isDone, required bool isError}) {
    Color color = kLine;
    if (isError) {
      color = const Color(0xFFEF4444);
    } else if (isActive) {
      color = kBlue;
    }

    return Column(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isError ? Icons.close : (isDone ? Icons.check : Icons.circle),
            size: 14,
            color: isActive ? color : Colors.transparent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? (isError ? const Color(0xFFEF4444) : kNavy) : kMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? kBlue : kLine,
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyCard(this.l10n);

  @override
  Widget build(BuildContext context) => AnimatedEmptyState(
        icon: Icons.fact_check_outlined,
        title: l10n.applicationsEmpty,
        subtitle: AppStrings.noApplicationsDesc,
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

// ────────────────────────────────────────────────────────
// Widget: Shimmer de Esqueletos para Postulaciones
// ────────────────────────────────────────────────────────

class _ShimmerApplicationsList extends StatelessWidget {
  const _ShimmerApplicationsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLine.withValues(alpha: 0.5)),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 80, height: 12, color: Colors.white),
                    Container(width: 60, height: 12, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Container(width: 180, height: 18, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 120, height: 12, color: Colors.white),
                const SizedBox(height: 16),
                Container(width: double.infinity, height: 1, color: Colors.white),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 100, height: 26, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                    Container(width: 80, height: 26, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  ],
                )
              ],
            ),
          ),
        ),
      )),
    );
  }
}
