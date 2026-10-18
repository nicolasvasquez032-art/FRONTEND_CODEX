import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/notificaciones_provider.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/language_switch_button.dart';
import '../shared/widgets/glass_background.dart';

// Las pantallas de contenido se importarán aquí en Sprints F-2 a F-6.
// Por ahora usamos placeholders visuales idénticos al wireframe.
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../applications/applications_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/notifications_screen.dart';
import '../chat/chat_list_screen.dart';

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
    final auth    = context.watch<AuthProvider>();
    final session = auth.session;
    final initial = session != null && session.userId.isNotEmpty ? 'T' : 'T';
    final l10n    = AppLocalizations.of(context);

    final pages = [
      HomeScreen(key: const ValueKey(0), onExplore: () => _goTo(1)),
      const ExploreScreen(key: ValueKey(1)),
      const ApplicationsScreen(key: ValueKey(2)),
      const ProfileScreen(key: ValueKey(3)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FA),
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _tab == 3 ? null : AppBar(
        title: const BrandFull(iconSize: 30),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          // Ícono de notificaciones con badge
          Consumer<NotificacionesProvider>(
            builder: (context, np, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: kNavy, size: 28),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                  ),
                  if (np.noLeidasCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${np.noLeidasCount > 9 ? '+9' : np.noLeidasCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Botón temporal de Chat para pruebas
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: kNavy, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatListScreen(),
                ),
              );
            },
          ),
          // Selector de idioma rápido
          const LanguageSwitchButton(),
          const SizedBox(width: 4),
          // Avatar del usuario
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onLongPress: () async {
                // Logout en long press del avatar (acceso rápido para desarrollo)
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l10n.profileLogout),
                    content: Text(l10n.profileLogoutConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonConfirm)),
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
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.70),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: kNavy.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.7),
                      blurRadius: 1,
                      offset: const Offset(-0.5, -0.5),
                    ),
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
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home, color: kBlue),
                      label: l10n.navHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.search),
                      selectedIcon: const Icon(Icons.search, color: kBlue),
                      label: l10n.navExplore,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.fact_check_outlined),
                      selectedIcon: const Icon(Icons.fact_check, color: kBlue),
                      label: l10n.navApplications,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person, color: kBlue),
                      label: l10n.navProfile,
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
