import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/profile.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/perfil_provider.dart';
import 'cv_upload_widget.dart';
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
    final pp      = context.watch<PerfilProvider>();
    final auth    = context.watch<AuthProvider>();
    final session = auth.session;

    return RefreshIndicator(
      onRefresh: () async {
        final profileId = session?.profileId ?? '';
        if (profileId.isNotEmpty) {
          await context.read<PerfilProvider>().cargar(profileId);
        }
      },
      color: kBlue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 20, 17, 40),
        children: [
          // ── Encabezado ─────────────────────────────────────
          const Text(
            AppStrings.profileSubtitle,
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.profileTitle,
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: kNavy),
          ),
          const SizedBox(height: 20),

          // ── Estado de carga ─────────────────────────────────
          if (pp.status == PerfilStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (pp.status == PerfilStatus.error)
            _ErrorCard(pp.error ?? 'Error al cargar perfil', onRetry: _cargar)
          else ...[
            // ── Tarjeta de perfil ───────────────────────────
            _ProfileCard(
              profile: pp.profile,
              session: session,
              onEditTap: () {
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
            const SizedBox(height: 16),

            // ── Widget de CV ────────────────────────────────
            const CvUploadWidget(),
            const SizedBox(height: 16),

            // ── Habilidades ─────────────────────────────────
            if (pp.profile != null && pp.profile!.skills.isNotEmpty)
              _SkillsCard(skills: pp.profile!.skills),
            const SizedBox(height: 16),

            // ── Detalles del perfil ─────────────────────────
            if (pp.profile != null) _DetailsCard(profile: pp.profile!),
            const SizedBox(height: 16),

            // ── Botón cerrar sesión ─────────────────────────
            _LogoutButton(),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Tarjeta principal del perfil
// ────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final Profile? profile;
  final dynamic session;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.profile,
    required this.session,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial  = profile?.initial ?? (session?.userId.isNotEmpty == true ? 'T' : 'T');
    final name     = profile?.fullName ?? 'Tu perfil';
    final expYears = profile?.experienceYears ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: kNavy.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + nombre ──
          Row(
            children: [
              Container(
                width: 56, height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: kLogoGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kBlue.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.work_outline, size: 13, color: kMuted),
                      const SizedBox(width: 4),
                      Text(
                        expYears == 1 ? '1 año de experiencia' : '$expYears años de experiencia',
                        style: const TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // ── Botón editar ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text(AppStrings.editProfile),
              onPressed: onEditTap,
              style: FilledButton.styleFrom(
                backgroundColor: kBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
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
