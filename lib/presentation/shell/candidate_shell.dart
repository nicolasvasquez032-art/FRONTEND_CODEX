import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/brand_logo.dart';

// Las pantallas de contenido se importarán aquí en Sprints F-2 a F-6.
// Por ahora usamos placeholders visuales idénticos al wireframe.
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
    final auth    = context.watch<AuthProvider>();
    final session = auth.session;
    final initial = session != null && session.userId.isNotEmpty ? 'T' : 'T';

    final pages = [
      HomeScreen(key: const ValueKey(0), onExplore: () => _goTo(1)),
      const ExploreScreen(key: ValueKey(1)),
      const ApplicationsScreen(key: ValueKey(2)),
      const ProfileScreen(key: ValueKey(3)),
    ];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _tab == 3 ? null : AppBar(
        title: const BrandFull(iconSize: 30),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
        actions: [
          // Avatar del usuario
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onLongPress: () async {
                // Logout en long press del avatar (acceso rápido para desarrollo)
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Deseas cerrar sesión?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, salir')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
              child: CircleAvatar(
                backgroundColor: const Color(0xFFE7EFFF),
                child: Text(
                  initial,
                  style: const TextStyle(color: kBlue, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            _setNavBarVisibility(false);
          } else if (notification.direction == ScrollDirection.forward) {
            _setNavBarVisibility(true);
          }
          return false;
        },
        child: _PremiumIndexedStack(
          index: _tab,
          children: pages,
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isNavBarVisible ? 1.0 : 0.0,
          child: SafeArea(
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
                  selectedIndex: _tab,
                  onDestinationSelected: _goTo,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home, color: kBlue),
                      label: AppStrings.navHome,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search),
                      selectedIcon: Icon(Icons.search, color: kBlue),
                      label: AppStrings.navExplore,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check, color: kBlue),
                      label: AppStrings.navApplications,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person, color: kBlue),
                      label: AppStrings.navProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ), // AnimatedOpacity
      ), // AnimatedSlide
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
