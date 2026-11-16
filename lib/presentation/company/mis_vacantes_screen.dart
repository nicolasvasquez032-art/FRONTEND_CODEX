import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../../domain/entities/vacante.dart';
import '../job_detail/job_detail_screen.dart';
import 'candidatos_vacante_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../shared/widgets/bouncy_tap.dart';
import '../shared/widgets/shimmer_cards.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/widgets/glass_card.dart';

class MisVacantesScreen extends StatefulWidget {
  const MisVacantesScreen({super.key});

  @override
  State<MisVacantesScreen> createState() => _MisVacantesScreenState();
}

class _MisVacantesScreenState extends State<MisVacantesScreen> {
  double? _promedioMatch;
  bool _calculandoPromedio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VacantesProvider>().cargar();
    });
  }

  void _recalcularMatch(List<Vacante> vacantes) {
    final totalCandidatos = vacantes.fold<int>(0, (sum, v) => sum + v.totalPostulaciones);
    if (totalCandidatos == 0) {
      if (_promedioMatch != null) {
        setState(() => _promedioMatch = null);
      }
      return;
    }
    if (_calculandoPromedio) return;
    _calculandoPromedio = true;
    final postProv = context.read<PostulacionesProvider>();

    Future.microtask(() async {
      try {
        double totalScore = 0;
        int count = 0;

        for (final v in vacantes) {
          if (v.totalPostulaciones > 0) {
            final postulaciones = await postProv.listarPorVacante(v.id);
            for (final p in postulaciones) {
              if (p.scoreMatch != null) {
                final sc = p.scoreMatch! <= 1.0 ? p.scoreMatch! * 100 : p.scoreMatch!;
                totalScore += sc;
                count++;
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _promedioMatch = count > 0 ? (totalScore / count) : 85.0;
            _calculandoPromedio = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _calculandoPromedio = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vacantesProvider = context.watch<VacantesProvider>();
    final session = context.watch<AuthProvider>().session;
    
    // Filtramos localmente para mostrar solo las vacantes de esta empresa
    final misVacantes = vacantesProvider.vacantes
        .where((v) => v.empresaId == session?.userId)
        .toList();

    final totalCandidatos = misVacantes.fold<int>(0, (sum, v) => sum + v.totalPostulaciones);
    if (totalCandidatos > 0 && _promedioMatch == null && !_calculandoPromedio) {
      _recalcularMatch(misVacantes);
    }

    return Scaffold(
      backgroundColor: kBg,
      body: LiquidPullToRefresh(
        color: kBlue,
        backgroundColor: Colors.white,
        animSpeedFactor: 2.0,
        showChildOpacityTransition: false,
        onRefresh: () async {
          await context.read<VacantesProvider>().cargar();
          if (!mounted) return;
          _promedioMatch = null;
          final vp = this.context.read<VacantesProvider>();
          final uid = this.context.read<AuthProvider>().session?.userId;
          final vacs = vp.vacantes.where((v) => v.empresaId == uid).toList();
          _recalcularMatch(vacs);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _buildDashboardHeader(misVacantes),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            if (vacantesProvider.status == VacantesStatus.loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: VacanteShimmerCard(),
                    ),
                    childCount: 3,
                  ),
                ),
              )
            else if (misVacantes.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              )
            else ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Tus Ofertas Recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: misVacantes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final v = misVacantes[index];
                    return _VacanteCard(key: ValueKey(v.id), vacante: v);
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Padding para el BottomNavBar
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(List<Vacante> misVacantes) {
    final isEs = context.watch<LocaleProvider>().isSpanish;
    final activas = misVacantes.where((v) => v.estado == VacanteEstado.activa).length;
    final totalCandidatos = misVacantes.fold<int>(0, (sum, v) => sum + v.totalPostulaciones);
    final matchScoreStr = totalCandidatos == 0
        ? '--'
        : (_promedioMatch != null ? '${_promedioMatch!.toInt()}%' : '...');

    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fondo azul premium con curvas
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)], // Slate 900 a Blue 900
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Stack(
              children: [
                // Decoraciones de fondo (círculos tenues)
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05))),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05))),
                ),
                // Contenido textual
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FadeInDown(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isEs ? 'RECURSOS HUMANOS' : 'HUMAN RESOURCES', style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                const SizedBox(height: 6),
                                const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              ],
                            ),
                          ),
                          FadeInDown(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.sync, color: Colors.white),
                                onPressed: () => context.read<VacantesProvider>().cargar(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FadeInDown(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          isEs
                              ? 'Aquí tienes un resumen del rendimiento\nde tus publicaciones activas.'
                              : 'Here is a performance summary\nof your active job listings.', 
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tarjetas Flotantes superpuestas
          Positioned(
            top: 200, // Empieza antes de que termine el fondo azul
            left: 0,
            right: 0,
            child: SizedBox(
              height: 125, // Altura de las tarjetas
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                clipBehavior: Clip.none,
                children: [
                  FadeInUp(delay: const Duration(milliseconds: 200), child: _buildStatCard(isEs ? 'Activas' : 'Active', activas.toString(), Icons.work, Colors.blueAccent)),
                  const SizedBox(width: 16),
                  FadeInUp(delay: const Duration(milliseconds: 300), child: _buildStatCard(isEs ? 'Candidatos' : 'Candidates', totalCandidatos.toString(), Icons.people, const Color(0xFF10B981))),
                  const SizedBox(width: 16),
                  FadeInUp(delay: const Duration(milliseconds: 400), child: _buildStatCard(isEs ? 'Match Score' : 'Match Score', matchScoreStr, Icons.auto_awesome, const Color(0xFFF59E0B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      width: 140,
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      customShadows: [
        BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: color.withValues(alpha: 0.5), size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kNavy, height: 1.1)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isEs = context.watch<LocaleProvider>().isSpanish;
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center_outlined, size: 64, color: kMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              isEs ? 'Aún no has publicado vacantes' : 'You have not posted any vacancies yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
            ),
            const SizedBox(height: 8),
            Text(
              isEs
                  ? 'Ve a la pestaña "Publicar" para\nempezar a atraer talento.'
                  : 'Go to the "Post" tab to\nstart attracting talent.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _VacanteCard extends StatefulWidget {
  final Vacante vacante;
  const _VacanteCard({super.key, required this.vacante});

  @override
  State<_VacanteCard> createState() => _VacanteCardState();
}

class _VacanteCardState extends State<_VacanteCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _descripcionLimpia(bool isEs) {
    return widget.vacante
        .descripcionLocalized(isEs)
        .replaceAll(RegExp(r'\n\n\*Salario expresado en [A-Z]{3}\*'), '');
  }

  Future<void> _handleDelete(bool isEs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEs ? 'Eliminar Vacante' : 'Delete Vacancy'),
        content: Text(isEs
            ? '¿Estás seguro de que deseas eliminar esta vacante de forma permanente?'
            : 'Are you sure you want to permanently delete this vacancy?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isEs ? 'Cancelar' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(isEs ? 'Eliminar' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<VacantesProvider>();
      
      // Reproduce la animación de salida
      await _animController.forward();
      
      final ok = await provider.eliminarVacante(widget.vacante.id);
      
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isEs ? 'Vacante eliminada' : 'Vacancy deleted'),
            backgroundColor: Colors.redAccent,
          ));
        } else {
          // Revertimos la animación si falla
          _animController.reverse();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.error ?? (isEs ? 'Error al eliminar vacante' : 'Error deleting vacancy')),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;
    final bool isActiva = widget.vacante.estado == VacanteEstado.activa;
    
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: kButtonGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: kBlue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.business_center, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vacante.tituloLocalized(isEs),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kNavy, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.vacante.categoriaLocalized(isEs) ?? (isEs ? 'Sin categoría' : 'Uncategorized'),
                        style: const TextStyle(fontSize: 12, color: kBlue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isActiva ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (isActiva ? Colors.green : Colors.orange).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActiva ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.vacante.estado.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isActiva ? Colors.green : Colors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _handleDelete(isEs),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: kLine, height: 1),
          ),
          Text(
            _descripcionLimpia(isEs),
            style: const TextStyle(fontSize: 13, color: kMuted, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: kNavy),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        widget.vacante.ubicacionLocalized(isEs),
                        style: const TextStyle(fontSize: 11, color: kNavy, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_outlined, size: 16, color: kBlue),
                  const SizedBox(width: 4),
                  Text(
                    widget.vacante.salarioDisplayLocalized(isEs),
                    style: const TextStyle(fontSize: 13, color: kNavy, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: BouncyTap(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => JobDetailScreen(vacante: widget.vacante))
                    );
                  },
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kBlue.withValues(alpha: 0.5), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(isEs ? 'Vista Previa' : 'Preview', style: const TextStyle(color: kBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: BouncyTap(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => CandidatosVacanteScreen(vacante: widget.vacante))
                    );
                  },
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        backgroundColor: kBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: kBlue,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isEs ? 'Ver Candidatos ' : 'View Candidates ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${widget.vacante.totalPostulaciones}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
