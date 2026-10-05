import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_ext.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/perfil_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import 'cv_upload_widget.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<AuthProvider>().session;
      if (session != null && session.profileId.isNotEmpty) {
        context.read<PerfilProvider>().cargar(session.profileId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final pp = context.watch<PerfilProvider>();
    final pop = context.watch<PostulacionesProvider>();

    int completeness = 20;
    if (pp.profile != null) {
      if (pp.profile!.skills.isNotEmpty) completeness += 30;
      if (pp.profile!.location?.isNotEmpty == true ||
          pp.profile!.education?.isNotEmpty == true)
        completeness += 20;
      if (pp.profile!.experienceYears > 0) completeness += 10;
      if (pp.profile!.cvText?.isNotEmpty == true) completeness += 20;
    }

    final initial =
        pp.profile?.initial ?? (session?.userId.isNotEmpty == true ? 'T' : 'T');
    final name = pp.profile?.fullName ?? 'Tu Perfil';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          Colors.transparent, // Background now handled by CandidateShell
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
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.white.withValues(alpha: 0.3)),
                        // Avatar
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            FadeInDown(
                              duration: const Duration(milliseconds: 600),
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kBlue.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: kBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FadeInUp(
                              delay: const Duration(milliseconds: 100),
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kNavy,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                'Candidato',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kNavy.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: kNavy),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 500),
                    child: _BentoContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'Completado',
                            value: completeness,
                            isPercent: true,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: kNavy.withValues(alpha: 0.1),
                          ),
                          _StatItem(
                            label: 'Postulaciones',
                            value: pop.postulaciones.length,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: kNavy.withValues(alpha: 0.1),
                          ),
                          _StatItem(label: 'Vistas', value: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (pp.status == PerfilStatus.loading)
                    const _ProfileSkeleton()
                  else if (pp.status == PerfilStatus.error)
                    _BentoContainer(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 10),
                          Text(
                            pp.error ?? 'Error',
                            style: const TextStyle(color: kNavy),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 500),
                      child: const _BentoContainer(child: CvUploadWidget()),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 500),
                      child: _BentoContainer(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ActionTile(
                              icon: Icons.person_outline,
                              title: 'Datos Personales',
                              subtitle: 'Información básica de contacto',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(
                                      section: EditProfileSection.personal,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.work_outline,
                              title: 'Experiencia',
                              subtitle: 'Añade tu historial laboral',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(
                                      section: EditProfileSection.experience,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.school_outlined,
                              title: 'Educación',
                              subtitle: 'Estudios y certificaciones',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(
                                      section: EditProfileSection.education,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.star_border,
                              title: 'Habilidades',
                              subtitle: 'Destaca tus conocimientos',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(
                                      section: EditProfileSection.skills,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 500),
                      child: _BentoContainer(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ActionTile(
                              icon: Icons.settings_outlined,
                              title: 'Configuración',
                              onTap: () {},
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.help_outline,
                              title: 'Ayuda y Soporte',
                              onTap: () {},
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.logout,
                              title: 'Cerrar Sesión',
                              isDestructive: true,
                              onTap: () async {
                                await context.read<AuthProvider>().logout();
                                // _AppRouter reacciona a AuthStatus.unauthenticated.
                                // No navegar manualmente aquí: hacerlo crea una segunda
                                // LoginScreen sobre el router raíz y rompe el siguiente login.
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _BentoContainer({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: kNavy.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final bool isPercent;

  const _StatItem({
    required this.label,
    required this.value,
    this.isPercent = false,
  });

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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: kNavy,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: kMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : kNavy;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : kBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : kBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red.withValues(alpha: 0.5) : kMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 66, color: kNavy.withValues(alpha: 0.05));
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.5),
      highlightColor: Colors.white,
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
