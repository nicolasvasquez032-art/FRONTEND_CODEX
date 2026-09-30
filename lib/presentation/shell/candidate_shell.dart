import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
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

  void _goTo(int tab) => setState(() => _tab = tab);

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
      appBar: _tab == 3 ? null : AppBar(
        title: const BrandFull(iconSize: 30),
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
                if (ok == true && mounted) {
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
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: pages[_tab],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: AppStrings.navExplore,
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: AppStrings.navApplications,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}
