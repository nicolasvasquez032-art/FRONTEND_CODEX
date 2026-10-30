import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_provider.dart';
import '../company/publicar_vacante_screen.dart';
import '../company/mis_vacantes_screen.dart';
import '../company/company_profile_screen.dart';
import '../company/premium_subscription_screen.dart';
import '../shared/providers/vacantes_provider.dart';

import '../shared/widgets/glass_background.dart';

class CompanyShell extends StatefulWidget {
  const CompanyShell({super.key});

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MisVacantesScreen(),
      PublicarVacanteScreen(onPublished: () => setState(() => _currentIndex = 0)),
      const CompanyProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF2F5FA),
      body: GlassBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 66,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.82),
                        Colors.white.withValues(alpha: 0.65),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _CompanyNavTab(
                      isSelected: _currentIndex == 0,
                      label: l10n.navCompanyMyJobs,
                      selectedIcon: Icons.business_center_rounded,
                      unselectedIcon: Icons.business_center_outlined,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _CompanyNavTab(
                      isSelected: _currentIndex == 1,
                      label: l10n.navCompanyPublish,
                      selectedIcon: Icons.add_circle_rounded,
                      unselectedIcon: Icons.add_circle_outline_rounded,
                      onTap: () {
                        final session = context.read<AuthProvider>().session;
                        final vacantes = context.read<VacantesProvider>().vacantes
                            .where((v) => v.empresaId == session?.userId).toList();
                            
                        if (session != null && !session.isPremium && vacantes.length >= 2) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()));
                          return;
                        }
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _CompanyNavTab(
                      isSelected: _currentIndex == 2,
                      label: l10n.navCompanyProfile,
                      selectedIcon: Icons.person_rounded,
                      unselectedIcon: Icons.person_outline_rounded,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _CompanyNavTab extends StatelessWidget {
  final bool isSelected;
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;

  const _CompanyNavTab({
    required this.isSelected,
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEBF2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            size: 26,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
