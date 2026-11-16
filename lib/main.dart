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
import 'presentation/shared/widgets/brand_logo.dart';

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

class TalentMatchApp extends StatefulWidget {
  const TalentMatchApp({super.key});

  @override
  State<TalentMatchApp> createState() => _TalentMatchAppState();
}

class _TalentMatchAppState extends State<TalentMatchApp> {
  late final SecureStorage _storage;
  late final ApiClient _apiClient;
  late final AuthRepositoryImpl _authRepo;
  late final AuthProvider _authProvider;
  late final VacantesProvider _vacantesProvider;
  late final PostulacionesProvider _postulacionesProvider;
  late final PerfilProvider _perfilProvider;
  late final RecomendacionesProvider _recomendacionesProvider;
  late final NotificacionesProvider _notificacionesProvider;
  late final ChatProvider _chatProvider;
  late final AdminProvider _adminProvider;
  late final LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    // ── Composición de dependencias única y persistente ───────────────────
    _storage = SecureStorage();
    _apiClient = ApiClient(_storage);
    _authRepo = AuthRepositoryImpl(_apiClient, _storage);
    _authProvider = AuthProvider(_authRepo);

    final vacanteRepo = VacanteRepositoryImpl(_apiClient);
    final postulacionRepo = PostulacionRepositoryImpl(_apiClient);
    final perfilRepo = PerfilRepositoryImpl(_apiClient);
    final recomendacionRepo = RecomendacionRepositoryImpl(_apiClient);
    final notificacionRepo = NotificacionRepositoryImpl(_apiClient);
    final adminRepo = AdminRepositoryImpl(_apiClient);

    _vacantesProvider = VacantesProvider(vacanteRepo);
    _postulacionesProvider = PostulacionesProvider(postulacionRepo);
    _perfilProvider = PerfilProvider(perfilRepo);
    _recomendacionesProvider = RecomendacionesProvider(recomendacionRepo);
    _notificacionesProvider = NotificacionesProvider(notificacionRepo);
    _chatProvider = ChatProvider();
    _adminProvider = AdminProvider(adminRepo);
    _localeProvider = LocaleProvider();

    // Conectar interceptor global de sesión expirada (401 definitivo)
    ApiClient.onSessionExpired = (message) {
      _authProvider.handleSessionExpired(message);
    };

    // Conectar reseteo atómico de todos los providers en memoria
    AuthProvider.onSessionReset = () {
      _perfilProvider.limpiar();
      _postulacionesProvider.limpiar();
      _notificacionesProvider.limpiar();
      _chatProvider.limpiar();
    };

    // Inicializar FCM una sola vez al arrancar
    final fcmService = FcmService(notificacionRepo);
    fcmService.initialize();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _vacantesProvider.dispose();
    _postulacionesProvider.dispose();
    _perfilProvider.dispose();
    _recomendacionesProvider.dispose();
    _notificacionesProvider.dispose();
    _chatProvider.dispose();
    _adminProvider.dispose();
    _localeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _vacantesProvider),
        ChangeNotifierProvider.value(value: _postulacionesProvider),
        ChangeNotifierProvider.value(value: _perfilProvider),
        ChangeNotifierProvider.value(value: _recomendacionesProvider),
        ChangeNotifierProvider.value(value: _notificacionesProvider),
        ChangeNotifierProvider.value(value: _chatProvider),
        ChangeNotifierProvider.value(value: _adminProvider),
        ChangeNotifierProvider.value(value: _localeProvider),
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
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo oficial animado
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: const BrandLogo(size: 76),
              ),
              const SizedBox(height: 22),
              const Text(
                'TalentMatch',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kNavy, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Empleo inteligente para tu futuro',
                style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlue),
              ),
            ],
          ),
        ),
      );
}
