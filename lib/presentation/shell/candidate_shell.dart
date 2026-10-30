import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/notificaciones_provider.dart';
import '../shared/widgets/glass_background.dart';

import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../applications/applications_screen.dart';
import '../profile/profile_screen.dart';

class CandidateShell extends StatefulWidget {
  const CandidateShell({super.key});

  @override
  State<CandidateShell> createState() => _CandidateShellState();
}

class _CandidateShellState extends State<CandidateShell> {
  int _tab = 0;
  bool _isNavBarVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().session?.userId ?? '';
      if (userId.isNotEmpty) {
        context.read<NotificacionesProvider>().cargar(userId);
      }
    });
  }

  void _setNavBarVisibility(bool isVisible) {
    if (_isNavBarVisible != isVisible) {
      setState(() => _isNavBarVisible = isVisible);
    }
  }

  void _goTo(int tab) {
    if (_tab != tab) {
      HapticFeedback.vibrate();
      setState(() => _tab = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final pages = [
      HomeScreen(key: const ValueKey(0), onExplore: () => _goTo(1)),
      const ExploreScreen(key: ValueKey(1)),
      const ApplicationsScreen(key: ValueKey(2)),
      const ProfileScreen(key: ValueKey(3)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FA),
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            _setNavBarVisibility(false);
          } else if (notification.direction == ScrollDirection.forward) {
            _setNavBarVisibility(true);
          }
          return false;
        },
        child: GlassBackground(
          child: _PremiumIndexedStack(
            index: _tab,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1.3),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isNavBarVisible ? 1.0 : 0.0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        _FigmaNavTab(
                          index: 0,
                          isSelected: _tab == 0,
                          label: l10n.navHome,
                          selectedIcon: Icons.home_rounded,
                          unselectedIcon: Icons.home_outlined,
                          onTap: () => _goTo(0),
                        ),
                        _FigmaNavTab(
                          index: 1,
                          isSelected: _tab == 1,
                          label: l10n.navExplore,
                          selectedIcon: Icons.search_rounded,
                          unselectedIcon: Icons.search_rounded,
                          onTap: () => _goTo(1),
                        ),
                        _FigmaNavTab(
                          index: 2,
                          isSelected: _tab == 2,
                          label: l10n.navApplications,
                          selectedIcon: Icons.work_rounded,
                          unselectedIcon: Icons.work_outline_rounded,
                          onTap: () => _goTo(2),
                        ),
                        _FigmaNavTab(
                          index: 3,
                          isSelected: _tab == 3,
                          label: l10n.navProfile,
                          selectedIcon: Icons.person_rounded,
                          unselectedIcon: Icons.person_outline_rounded,
                          onTap: () => _goTo(3),
                        ),
                      ],
                    ),
                  ),
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

/// Elemento individual de navegación idéntico al diseño de Figma.
class _FigmaNavTab extends StatelessWidget {
  final int index;
  final bool isSelected;
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;

  const _FigmaNavTab({
    required this.index,
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
