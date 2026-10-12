import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_provider.dart';
import '../company/publicar_vacante_screen.dart';
import '../company/mis_vacantes_screen.dart';
import '../company/company_profile_screen.dart';
import '../company/premium_subscription_screen.dart';
import '../shared/providers/vacantes_provider.dart';

class CompanyShell extends StatefulWidget {
  const CompanyShell({super.key});

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const MisVacantesScreen(),
    PublicarVacanteScreen(onPublished: () => setState(() => _currentIndex = 0)),
    const CompanyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: kBg,
      body: _PremiumIndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: kNavy.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: NavigationBar(
                  height: 65,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: kBlue.withValues(alpha: 0.15),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) {
                    if (idx == 1) {
                      final session = context.read<AuthProvider>().session;
                      final vacantes = context.read<VacantesProvider>().vacantes
                          .where((v) => v.empresaId == session?.userId).toList();
                          
                      if (session != null && !session.isPremium && vacantes.length >= 2) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()));
                        return;
                      }
                    }
                    setState(() => _currentIndex = idx);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.business_center_outlined),
                      selectedIcon: const Icon(Icons.business_center, color: kBlue),
                      label: l10n.navCompanyMyJobs,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.add_circle_outline),
                      selectedIcon: const Icon(Icons.add_circle, color: kBlue),
                      label: l10n.navCompanyPublish,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person, color: kBlue),
                      label: l10n.navCompanyProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumIndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const _PremiumIndexedStack({required this.index, required this.children});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(children.length, (i) {
        final active = index == i;
        return IgnorePointer(
          ignoring: !active,
          child: AnimatedOpacity(
            opacity: active ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: active ? Offset.zero : const Offset(0, 0.04),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: children[i],
            ),
          ),
        );
      }),
    );
  }
}
