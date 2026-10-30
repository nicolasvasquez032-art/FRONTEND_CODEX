import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/perfil_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import 'cv_upload_widget.dart';
import 'edit_profile_screen.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/talentmatch_top_header.dart';

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
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final isEs = localeProvider.locale.languageCode == 'es';

    int completeness = 20;
    if (pp.profile != null) {
      if (pp.profile!.skills.isNotEmpty) completeness += 30;
      if (pp.profile!.location?.isNotEmpty == true ||
          pp.profile!.education?.isNotEmpty == true) {
        completeness += 20;
      }
      if (pp.profile!.experienceYears > 0) completeness += 10;
      if (pp.profile!.cvText?.isNotEmpty == true) completeness += 20;
    }

    final initial =
        pp.profile?.initial ?? (session?.userId.isNotEmpty == true ? 'T' : 'T');
    final name = pp.profile?.fullName ?? l10n.profileTitle;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background now handled by CandidateShell
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TalentMatchTopHeader(),
            Expanded(
              child: RefreshIndicator(
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 600),
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
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
                                    fontSize: 34,
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
                                l10n.profileCandidateRole,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kNavy.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
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
                            label: l10n.profileStatsCompleted,
                            value: completeness,
                            isPercent: true,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: kNavy.withValues(alpha: 0.1),
                          ),
                          _StatItem(
                            label: l10n.profileStatsApplications,
                            value: pop.postulaciones.length,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: kNavy.withValues(alpha: 0.1),
                          ),
                          _StatItem(label: l10n.profileStatsViews, value: 12),
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
                              title: l10n.profilePersonalData,
                              subtitle: l10n.profilePersonalDataSubtitle,
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
                              title: l10n.profileExperience,
                              subtitle: l10n.profileExperienceSubtitle,
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
                              title: l10n.profileEducation,
                              subtitle: l10n.profileEducationSubtitle,
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
                              title: l10n.profileSkills,
                              subtitle: l10n.profileSkillsSubtitle,
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
                              icon: Icons.language,
                              title: l10n.profileLanguage,
                              subtitle: isEs ? l10n.profileLanguageSpanish : l10n.profileLanguageEnglish,
                              onTap: () => _showLanguageDialog(context, localeProvider, l10n),
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.settings_outlined,
                              title: l10n.profileSettings,
                              onTap: () {},
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.help_outline,
                              title: l10n.profileHelp,
                              onTap: () {},
                            ),
                            _Divider(),
                            _ActionTile(
                              icon: Icons.logout,
                              title: l10n.profileLogout,
                              isDestructive: true,
                              onTap: () async {
                                await context.read<AuthProvider>().logout();
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
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currentCode = localeProvider.locale.languageCode;
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.language, color: kBlue, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    l10n.profileSelectLanguageTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: const Text('🇪🇸', style: TextStyle(fontSize: 26)),
                title: Text(
                  l10n.profileLanguageSpanish,
                  style: TextStyle(
                    fontWeight: currentCode == 'es' ? FontWeight.w800 : FontWeight.w500,
                    color: currentCode == 'es' ? kBlue : kNavy,
                  ),
                ),
                trailing: currentCode == 'es'
                    ? const Icon(Icons.check_circle, color: kBlue)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  localeProvider.setLocale(const Locale('es'));
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 26)),
                title: Text(
                  l10n.profileLanguageEnglish,
                  style: TextStyle(
                    fontWeight: currentCode == 'en' ? FontWeight.w800 : FontWeight.w500,
                    color: currentCode == 'en' ? kBlue : kNavy,
                  ),
                ),
                trailing: currentCode == 'en'
                    ? const Icon(Icons.check_circle, color: kBlue)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
  }
}

class _BentoContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _BentoContainer({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
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
