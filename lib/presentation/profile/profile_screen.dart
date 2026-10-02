import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/profile.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/perfil_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/providers/notificaciones_provider.dart';
import 'cv_upload_widget.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final profileId = context.read<AuthProvider>().session?.profileId ?? '';
    final pp = context.read<PerfilProvider>();
    if (profileId.isNotEmpty && pp.status == PerfilStatus.initial) {
      await pp.cargar(profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PerfilProvider>();
    final auth = context.watch<AuthProvider>();
    final session = auth.session;
    final postulacionesCount = context.watch<PostulacionesProvider>().postulaciones.length;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 100;

    // Calculamos el % de perfil completado dinámicamente
    int completeness = 20; // Base por crear cuenta
    if (pp.profile != null) {
      if (pp.profile!.skills.isNotEmpty) completeness += 30;
      if (pp.profile!.location?.isNotEmpty == true || pp.profile!.education?.isNotEmpty == true) completeness += 20;
      if (pp.profile!.experienceYears > 0) completeness += 10;
      if (pp.profile!.cvText?.isNotEmpty == true) completeness += 20;
    }

    final initial = pp.profile?.initial ?? (session?.userId.isNotEmpty == true ? 'T' : 'T');
    final name = pp.profile?.fullName ?? 'Tu Perfil';

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: () async {
          final profileId = session?.profileId ?? '';
          if (profileId.isNotEmpty) {
            final pp = context.read<PerfilProvider>();
            final pop = context.read<PostulacionesProvider>();
            final userId = session?.userId ?? '';
            await pp.cargar(profileId);
            await pop.cargar(userId);
          }
        },
        color: kBlue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              backgroundColor: kBlue,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fondo Degradado Premium
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kNavy, kBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Patrón de fondo sutil
                    Positioned(
                      top: -50,
                      right: -50,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    // Contenido del Avatar
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: kNavy.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: kBlue),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Candidato',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    if (context.watch<NotificacionesProvider>().noLeidasCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${context.watch<NotificacionesProvider>().noLeidasCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    if (pp.profile == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<PerfilProvider>(),
                          child: EditProfileScreen(profile: pp.profile!),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Contenido desplazable
            SliverToBoxAdapter(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    // Tarjeta de Estadísticas
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: kNavy.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(label: 'Completado', value: completeness, isPercent: true),
                          Container(width: 1, height: 40, color: kLine),
                          _StatItem(label: 'Postulaciones', value: postulacionesCount),
                          Container(width: 1, height: 40, color: kLine),
                          const _StatItem(label: 'Vistas', value: 12),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (pp.status == PerfilStatus.loading)
                            const _ProfileSkeleton()
                          else if (pp.status == PerfilStatus.error)
                            _ErrorCard(pp.error ?? 'Error al cargar', onRetry: () {
                              final pid = session?.profileId ?? '';
                              if (pid.isNotEmpty) context.read<PerfilProvider>().cargar(pid);
                            })
                          else ...[
                            // CV Upload
                            const CvUploadWidget(),
                            const SizedBox(height: 20),

                            // Skills
                            if (pp.profile != null && pp.profile!.skills.isNotEmpty)
                              _SkillsCard(skills: pp.profile!.skills),
                            const SizedBox(height: 20),

                            // Details
                            if (pp.profile != null) _DetailsCard(profile: pp.profile!),
                            const SizedBox(height: 40),
                          ],
                          
                          // Logout SIEMPRE visible
                          const SizedBox(height: 20),
                          _LogoutButton(),
                          SizedBox(height: bottomPadding),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final bool isPercent;

  const _StatItem({required this.label, required this.value, this.isPercent = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return Text(
              '${val.toInt()}${isPercent ? '%' : ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kNavy),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ────────────────────────────────────────────────
// Tarjeta de habilidades
// ────────────────────────────────────────────────

class _SkillsCard extends StatelessWidget {
  final List<String> skills;
  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.code_outlined, color: kBlue, size: 18),
              SizedBox(width: 8),
              Text(AppStrings.skillsLabel,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kNavy)),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: skills.map((s) => _SkillChip(s)).toList(),
            ),
          ],
        ),
      );
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF3FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF245BC8), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}

// ────────────────────────────────────────────────
// Tarjeta de detalles (ubicación, educación)
// ────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final Profile profile;
  const _DetailsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final items = <_DetailItem>[
      if (profile.location != null && profile.location!.isNotEmpty)
        _DetailItem(Icons.location_on_outlined, 'Ubicación', profile.location!),
      if (profile.education != null && profile.education!.isNotEmpty)
        _DetailItem(Icons.school_outlined, 'Educación', profile.education!),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline, color: kBlue, size: 18),
            SizedBox(width: 8),
            Text('Información', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kNavy)),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => _DetailRow(item)),
        ],
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}

class _DetailRow extends StatelessWidget {
  final _DetailItem item;
  const _DetailRow(this.item);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(item.icon, color: kMuted, size: 17),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.label, style: const TextStyle(fontSize: 10, color: kMuted)),
              Text(item.value, style: const TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      );
}

// ────────────────────────────────────────────────
// Botón cerrar sesión
// ────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout_outlined, size: 18),
          label: const Text(AppStrings.logout),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            side: BorderSide(color: Colors.red.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cerrar sesión'),
                content: const Text('¿Deseas cerrar tu sesión actual?'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
                    child: const Text('Salir'),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await context.read<AuthProvider>().logout();
            }
          },
        ),
      );
}

// ────────────────────────────────────────────────
// Tarjeta de error con reintentar
// ────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorCard(this.msg, {required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Icon(Icons.wifi_off_outlined, size: 44, color: kMuted),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      );
}

// ────────────────────────────────────────────────────────
// Widget Custom: Skeleton de Perfil
// ────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Esqueleto de CV
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            // Esqueleto de titulo de skills
            Container(width: 120, height: 18, color: Colors.white),
            const SizedBox(height: 16),
            // Esqueleto de chips de skills
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: List.generate(4, (i) => Container(
                width: 80 + (i * 15.0),
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              )),
            ),
            const SizedBox(height: 24),
            // Esqueleto de formulario
            Container(width: 150, height: 18, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 50, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
            const SizedBox(height: 16),
            Container(height: 50, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          ],
        ),
      ),
    );
  }
}

