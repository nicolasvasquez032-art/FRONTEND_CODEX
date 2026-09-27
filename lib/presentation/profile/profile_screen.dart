import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../shared/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final session = auth.session;

    return ListView(
      padding: const EdgeInsets.all(17),
      children: [
        const Text(AppStrings.profileSubtitle, style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 4),
        const Text(AppStrings.profileTitle, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: kNavy)),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kLine),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera del perfil ──
              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFDDE9FF),
                  child: Text(
                    session?.userId.isNotEmpty == true ? 'T' : 'T',
                    style: const TextStyle(color: kBlue, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tu perfil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy)),
                    Text('Candidato', style: TextStyle(color: kMuted, fontSize: 12)),
                  ]),
                ),
              ]),

              const Divider(height: 28),

              // ── Habilidades ──
              const Text(AppStrings.skillsLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: const [
                  _Skill('Java'), _Skill('Python'), _Skill('Bases de datos'), _Skill('Desarrollo web'),
                ],
              ),

              const SizedBox(height: 16),

              // ── Preferencias ──
              const Text(AppStrings.preferencesLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              const Text(
                'Fusagasugá · Remoto / Híbrido · Jornada completa',
                style: TextStyle(color: kMuted, fontSize: 12),
              ),

              const SizedBox(height: 20),

              // ── Botones ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(AppStrings.editProfile),
                  onPressed: () {
                    // Sprint F-5: navegar a edit_profile_screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edición de perfil disponible en Sprint F-5')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_outlined, size: 18),
                  label: const Text(AppStrings.logout),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Deseas cerrar sesión?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<AuthProvider>().logout();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Skill extends StatelessWidget {
  final String label;
  const _Skill(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Color(0xFF245BC8), fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
