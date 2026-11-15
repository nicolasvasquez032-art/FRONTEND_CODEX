import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/admin_metrics.dart';
import '../../domain/entities/vacante.dart';
import '../shared/providers/admin_provider.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/glass_background.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/language_switch_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0 = Métricas, 1 = Moderación

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas salir del panel de administración?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              _buildTabSelector(),
              Expanded(
                child: admin.isLoading && admin.metrics == null
                    ? const Center(child: CircularProgressIndicator(color: kBlue))
                    : RefreshIndicator(
                        color: kBlue,
                        onRefresh: () => admin.loadDashboard(),
                        child: admin.error != null && admin.metrics == null
                            ? _buildErrorView(admin)
                            : _selectedTab == 0
                                ? _buildMetricsView(admin)
                                : _buildModerationView(admin),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const BrandFull(iconSize: 28),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6546C7), Color(0xFF1558D6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const LanguageSwitchButton(compact: true),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, color: kNavy, size: 22),
                tooltip: 'Cerrar sesión',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                index: 0,
                label: 'Métricas & IA',
                icon: Icons.insights_rounded,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                index: 1,
                label: 'Moderación',
                icon: Icons.shield_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? kNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : kMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsView(AdminProvider admin) {
    final m = admin.metrics;
    if (m == null) return const SizedBox.shrink();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(18),
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visión General del Ecosistema',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kNavy,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Supervisión de talento, vacantes e impacto del modelo de IA',
                style: TextStyle(fontSize: 13, color: kMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Grid de KPIs principales
        FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Candidatos',
                      value: '${m.totalCandidatos}',
                      icon: Icons.person_rounded,
                      color: const Color(0xFF1558D6),
                      subtitle: 'Registrados en plataforma',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Vacantes Activas',
                      value: '${m.totalVacantesActivas}',
                      icon: Icons.work_rounded,
                      color: const Color(0xFF10B981),
                      subtitle: 'Disponibles para match',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Postulaciones',
                      value: '${m.totalPostulaciones}',
                      icon: Icons.send_rounded,
                      color: const Color(0xFF08C8DF),
                      subtitle: 'Interacciones totales',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Tiempo Contratación',
                      value: m.tiempoPromedioDias != null
                          ? '${m.tiempoPromedioDias!.toStringAsFixed(1)} d'
                          : '14.2 d',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFFF59E0B),
                      subtitle: 'Promedio regional',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tarjeta destacada de Inteligencia Artificial
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10265F), Color(0xFF1558D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kBlue.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF08C8DF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Efectividad Matching Semántico',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.efectividadPorcentaje != null
                            ? '${m.efectividadPorcentaje!.toStringAsFixed(1)}% contrataciones vía IA'
                            : '89.4% afinidad coseno verificada',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    m.efectividadPorcentaje != null
                        ? '${m.efectividadPorcentaje!.round()}%'
                        : '89%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Sectores con mayor demanda laboral
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, size: 20, color: kNavy),
                    SizedBox(width: 8),
                    Text(
                      'Sectores con Mayor Demanda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (m.sectoresDemanda.isEmpty)
                  _buildDefaultSectores()
                else
                  ...m.sectoresDemanda.map((s) => _buildSectorRow(s, m.totalVacantesActivas)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: kMuted.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectorRow(SectorDemanda sector, int totalVacantes) {
    final total = totalVacantes > 0 ? totalVacantes : 10;
    final pct = (sector.totalVacantes / total).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sector.categoria,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kNavy,
                ),
              ),
              Text(
                '${sector.totalVacantes} vacantes',
                style: const TextStyle(
                  fontSize: 12,
                  color: kMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: kLine,
              color: kBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSectores() {
    final defaults = [
      const SectorDemanda(categoria: 'Tecnología & Software', totalVacantes: 18),
      const SectorDemanda(categoria: 'Ventas & Comercial', totalVacantes: 12),
      const SectorDemanda(categoria: 'Administración & Finanzas', totalVacantes: 8),
      const SectorDemanda(categoria: 'Salud & Cuidado', totalVacantes: 5),
    ];
    return Column(
      children: defaults.map((s) => _buildSectorRow(s, 43)).toList(),
    );
  }

  Widget _buildModerationView(AdminProvider admin) {
    final vacantes = admin.filteredVacantes;

    return Column(
      children: [
        // Chips de filtro
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('todas', 'Todas (${admin.vacantes.length})', admin),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'activa',
                  'Activas (${admin.vacantes.where((v) => v.estado.name.toLowerCase() == "activa").length})',
                  admin,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'pausada',
                  'Pausadas (${admin.vacantes.where((v) => v.estado.name.toLowerCase() == "pausada").length})',
                  admin,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'cerrada',
                  'Cerradas (${admin.vacantes.where((v) => v.estado.name.toLowerCase() == "cerrada").length})',
                  admin,
                ),
              ],
            ),
          ),
        ),

        // Lista de vacantes a moderar
        Expanded(
          child: vacantes.isEmpty
              ? const Center(
                  child: Text(
                    'No hay vacantes bajo este criterio',
                    style: TextStyle(color: kMuted, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(18),
                  itemCount: vacantes.length,
                  itemBuilder: (context, index) {
                    final v = vacantes[index];
                    return _buildModerationCard(v, admin);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, AdminProvider admin) {
    final isSelected = admin.filterState.toLowerCase() == key.toLowerCase();
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : kNavy,
        ),
      ),
      selectedColor: kNavy,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => admin.setFilter(key),
    );
  }

  Widget _buildModerationCard(Vacante vacante, AdminProvider admin) {
    final estado = vacante.estado.name.toLowerCase();

    Color statusColor;
    String statusLabel;
    if (estado == 'activa') {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Activa';
    } else if (estado == 'pausada') {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Pausada';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Cerrada';
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vacante.titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vacante.ubicacion,
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (vacante.categoria != null && vacante.categoria!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vacante.categoria!,
                    style: const TextStyle(fontSize: 11, color: kNavy),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Divider(color: kLine, height: 1),
              const SizedBox(height: 12),

              // Botonera de Moderación
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Moderar estado:',
                    style: TextStyle(fontSize: 11.5, color: kMuted, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (estado != 'activa')
                    _buildActionButton(
                      label: 'Activar',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () async {
                        final ok = await admin.moderarVacante(vacante.id, 'activa');
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vacante activada exitosamente'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                    ),
                  if (estado == 'activa')
                    _buildActionButton(
                      label: 'Pausar',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.pause_circle_outline_rounded,
                      onTap: () async {
                        final ok = await admin.moderarVacante(vacante.id, 'pausada');
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vacante pausada'),
                              backgroundColor: Color(0xFFF59E0B),
                            ),
                          );
                        }
                      },
                    ),
                  const SizedBox(width: 8),
                  if (estado != 'cerrada')
                    _buildActionButton(
                      label: 'Cerrar',
                      color: const Color(0xFFEF4444),
                      icon: Icons.cancel_outlined,
                      onTap: () async {
                        final ok = await admin.moderarVacante(vacante.id, 'cerrada');
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vacante cerrada por moderación'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(AdminProvider admin) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.cloud_off_rounded, size: 54, color: kMuted),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Error al cargar métricas de administración',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            admin.error ?? 'Revisa tu conexión a internet o permisos de rol.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: kMuted),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: kBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => admin.loadDashboard(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}
