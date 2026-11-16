import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
import 'data/repositories/admin_repository_impl.dart';
import 'core/notifications/fcm_service.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/shared/providers/auth_provider.dart';
import 'presentation/shared/providers/perfil_provider.dart';
import 'presentation/shared/providers/postulaciones_provider.dart';
import 'presentation/shared/providers/recomendaciones_provider.dart';
import 'presentation/shared/providers/vacantes_provider.dart';
import 'presentation/shared/providers/notificaciones_provider.dart';
import 'presentation/shared/providers/chat_provider.dart';
import 'presentation/shared/providers/admin_provider.dart';
import 'presentation/shared/providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/shell/candidate_shell.dart';
import 'presentation/shell/company_shell.dart';
import 'presentation/shell/admin_shell.dart';
import 'presentation/onboarding/onboarding_screen.dart';

/// DSN de Sentry configurable en tiempo de compilación:
/// `flutter build apk --dart-define=SENTRY_DSN=https://xxx@sentry.io/yyy`
const String kSentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await initializeDateFormatting('en', null);

  if (kSentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = kSentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment = kDebugMode ? 'development' : 'production';
      },
      appRunner: () => runApp(const TalentMatchApp()),
    );
  } else {
    runApp(const TalentMatchApp());
  }
}

class TalentMatchApp extends StatelessWidget {
  const TalentMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Composición de dependencias ──────────────────────────────────────
    final storage           = SecureStorage();
    final apiClient         = ApiClient(storage);
    final authRepo          = AuthRepositoryImpl(apiClient, storage);
    final authProvider      = AuthProvider(authRepo);
    final vacanteRepo       = VacanteRepositoryImpl(apiClient);
    final postulacionRepo   = PostulacionRepositoryImpl(apiClient);
    final perfilRepo        = PerfilRepositoryImpl(apiClient);
    final recomendacionRepo = RecomendacionRepositoryImpl(apiClient);
    final notificacionRepo  = NotificacionRepositoryImpl(apiClient);
    final adminRepo         = AdminRepositoryImpl(apiClient);

    final vacantesProvider        = VacantesProvider(vacanteRepo);
    final postulacionesProvider   = PostulacionesProvider(postulacionRepo);
    final perfilProvider          = PerfilProvider(perfilRepo);
    final recomendacionesProvider = RecomendacionesProvider(recomendacionRepo);
    final notificacionesProvider  = NotificacionesProvider(notificacionRepo);
    final chatProvider            = ChatProvider();
    final adminProvider           = AdminProvider(adminRepo);
    final localeProvider          = LocaleProvider();

    // Conectar interceptor global de sesión expirada (401 definitivo)
    ApiClient.onSessionExpired = (message) {
      authProvider.handleSessionExpired(message);
    };

    // Conectar reseteo atómico de todos los providers en memoria
    AuthProvider.onSessionReset = () {
      perfilProvider.limpiar();
      postulacionesProvider.limpiar();
      notificacionesProvider.limpiar();
      chatProvider.limpiar();
    };

    // Inicializar FCM
    final fcmService = FcmService(notificacionRepo);
    fcmService.initialize();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: vacantesProvider),
        ChangeNotifierProvider.value(value: postulacionesProvider),
        ChangeNotifierProvider.value(value: perfilProvider),
        ChangeNotifierProvider.value(value: recomendacionesProvider),
        ChangeNotifierProvider.value(value: notificacionesProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider.value(value: adminProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TalentMatch',
            theme: AppTheme.theme,
            themeMode: ThemeMode.light,
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorObservers: [SentryNavigatorObserver()],
            home: child,
          );
        },
        child: const _AppRouter(),
      ),
    );
  }
}

/// Router raíz que reacciona al estado de autenticación.
/// - AuthStatus.unknown      → pantalla de carga (splash)
/// - AuthStatus.authenticated → CandidateShell (o RegisterScreen si es nuevo usuario social)
/// - AuthStatus.unauthenticated → LoginScreen
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);
    final role = context.select<AuthProvider, String?>((p) => p.session?.role);
    final needsProfileCompletion = context.select<AuthProvider, bool>((p) => p.needsProfileCompletion);
    final hasSeenOnboarding = context.select<AuthProvider, bool>((p) => p.hasSeenOnboarding);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (status) {
        AuthStatus.unknown         => const _SplashScreen(key: ValueKey('splash_screen')),
        AuthStatus.authenticated   => needsProfileCompletion
            ? const RegisterScreen(
                key: ValueKey('social_onboarding'),
                initialStep: 1,
                isSocialOnboarding: true,
              )
            : switch (role) {
                'admin'   => const AdminShell(key: ValueKey('admin_shell')),
                'company' => const CompanyShell(key: ValueKey('company_shell')),
                _         => const CandidateShell(key: ValueKey('candidate_shell')),
              },
        AuthStatus.unauthenticated => hasSeenOnboarding
            ? const LoginScreen(key: ValueKey('login_screen'))
            : const OnboardingScreen(key: ValueKey('onboarding_screen')),
      },
    );
  }
}

/// Pantalla de carga mientras se verifica la sesión en SharedPreferences.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

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
