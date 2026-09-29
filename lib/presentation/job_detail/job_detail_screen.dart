import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/vacante.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../explore/map_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Vacante vacante;
  const JobDetailScreen({super.key, required this.vacante});

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostulacionesProvider>();
    final session = context.read<AuthProvider>().session;
    final yaPostulado = postsProvider.yaPostulado(vacante.id);

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar con gradiente ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: kBlue,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: kBannerGradient),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vacante.categoria != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          vacante.categoria!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      vacante.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenido ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Info rápida
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadatos clave
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(Icons.location_on_outlined, vacante.ubicacion),
                          _InfoChip(Icons.access_time_outlined, vacante.tiempoRelativo),
                          _InfoChip(Icons.attach_money_outlined, vacante.salarioDisplay, accent: true),
                        ],
                      ),
                      if (vacante.latitud != null && vacante.longitud != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapScreen(focusedVacante: vacante),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_outlined, size: 18, color: kBlue),
                            label: const Text('Ver ubicación en el mapa', style: TextStyle(color: kBlue)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kLine),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Descripción
                      const Text(
                        'Descripción del cargo',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kNavy),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vacante.descripcion,
                        style: const TextStyle(color: kMuted, fontSize: 13, height: 1.65),
                      ),

                      // Requisitos
                      if (vacante.requisitos.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Requisitos',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kNavy),
                        ),
                        const SizedBox(height: 12),
                        ...vacante.requisitos.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  width: 7, height: 7,
                                  decoration: const BoxDecoration(
                                    color: kBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: const TextStyle(color: kMuted, fontSize: 13, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      bottomNavigationBar: _PostularseBar(
        vacante: vacante,
        yaPostulado: yaPostulado,
        candidatoId: session?.profileId ?? '',
      ),
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

  const _PostularseBar({
    required this.vacante,
    required this.yaPostulado,
    required this.candidatoId,
  });

  Future<void> _postularse(BuildContext context) async {
    if (candidatoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa tu perfil antes de postularte.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF22C55E),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Te postulaste a "${vacante.titulo}"!',
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
            provider.error ?? 'Ya estás postulado a esta vacante.',
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: yaPostulado
              ? _doneButton()
              : _applyButton(context),
        ),
      ),
    );
  }

  Widget _applyButton(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          key: const ValueKey('apply'),
          onPressed: () => _postularse(context),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_outlined, size: 18),
              SizedBox(width: 10),
              Text('Postularme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Ya estás postulado',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
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
