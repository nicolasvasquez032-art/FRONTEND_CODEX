import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/perfil_repository_impl.dart';
import 'data/repositories/postulacion_repository_impl.dart';
import 'data/repositories/recomendacion_repository_impl.dart';
import 'data/repositories/vacante_repository_impl.dart';
import 'data/repositories/notificacion_repository_impl.dart';
import 'core/notifications/fcm_service.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/shared/providers/auth_provider.dart';
import 'presentation/shared/providers/perfil_provider.dart';
import 'presentation/shared/providers/postulaciones_provider.dart';
import 'presentation/shared/providers/recomendaciones_provider.dart';
import 'presentation/shared/providers/vacantes_provider.dart';
import 'presentation/shared/providers/notificaciones_provider.dart';
import 'presentation/shell/candidate_shell.dart';
import 'presentation/shell/company_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TalentMatchApp());
}

class TalentMatchApp extends StatelessWidget {
  const TalentMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Composición de dependencias ──────────────────────────────────────
    final storage          = SecureStorage();
    final apiClient        = ApiClient(storage);
    final authRepo         = AuthRepositoryImpl(apiClient, storage);
    final vacanteRepo      = VacanteRepositoryImpl(apiClient);
    final postulacionRepo  = PostulacionRepositoryImpl(apiClient);
    final perfilRepo       = PerfilRepositoryImpl(apiClient);
    final recomendacionRepo = RecomendacionRepositoryImpl(apiClient);
    final notificacionRepo = NotificacionRepositoryImpl(apiClient);

    // Inicializar FCM
    final fcmService = FcmService(notificacionRepo);
    fcmService.initialize();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        // Sprint F-2: Vacantes y Postulaciones
        ChangeNotifierProvider(create: (_) => VacantesProvider(vacanteRepo)),
        ChangeNotifierProvider(create: (_) => PostulacionesProvider(postulacionRepo)),
        // Sprint F-5: Perfil completo
        ChangeNotifierProvider(create: (_) => PerfilProvider(perfilRepo)),
        // Sprint F-3: Recomendaciones IA (con fallback al listado general)
        ChangeNotifierProvider(create: (_) => RecomendacionesProvider(recomendacionRepo)),
        // Sprint F-6: Notificaciones
        ChangeNotifierProvider(create: (_) => NotificacionesProvider(notificacionRepo)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TalentMatch',
        theme: AppTheme.theme,
        themeMode: ThemeMode.light,
        home: const _AppRouter(),
      ),
    );
  }
}

/// Router raíz que reacciona al estado de autenticación.
/// - AuthStatus.unknown      → pantalla de carga (splash)
/// - AuthStatus.authenticated → CandidateShell
/// - AuthStatus.unauthenticated → LoginScreen
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);
    final role = context.select<AuthProvider, String?>((p) => p.session?.role);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (status) {
        AuthStatus.unknown         => const _SplashScreen(),
        AuthStatus.authenticated   => role == 'company' ? const CompanyShell() : const CandidateShell(),
        AuthStatus.unauthenticated => const LoginScreen(),
      },
    );
  }
}

/// Pantalla de carga mientras se verifica la sesión en SharedPreferences.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 80, height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kLogoGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: kBlue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: const Text('T', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TalentMatch',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kNavy),
              ),
              const SizedBox(height: 8),
              const Text(
                'Empleo inteligente para tu futuro',
                style: TextStyle(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlue),
              ),
            ],
          ),
        ),
      );
}
