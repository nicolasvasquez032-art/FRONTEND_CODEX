import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/app_toast.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'social_popup_helper.dart';
import 'widgets/auth_background_decor.dart';
import 'widgets/auth_language_pill.dart';
import 'widgets/social_auth_buttons.dart';

/// Pantalla de Inicio de Sesión de TalentMatch.
///
/// Implementa fielmente el diseño de Figma con:
/// - Escultura 3D decorativa independiente con flotación orgánica de 8 segundos y sutil giro en el plano.
/// - Elementos flotantes desacoplados (avatar de usuario, maletín de empleo, esfera iridiscente y destellos).
/// - Formulario con efecto glassmorphic (vidrio esmerilado translúcido) completamente estático.
/// - Conexiones intactas de autenticación (email, contraseña, recuperación, Google, LinkedIn, registro).
/// - Selector de idioma interactivo (ES / EN) integrado con [LocaleProvider].
/// - Soporte para áreas seguras, teclado virtual y reducción de movimiento (accesibilidad).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  // Controlador para la flotación suave de 8 segundos de los elementos decorativos
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    if (kIsWeb) {
      SocialPopupHelper.onWebMessage((data) async {
        final token = data['token']?.toString();
        final refresh = data['refreshToken']?.toString() ?? '';
        final isNewUser = data['is_new_user'] == true;
        if (token != null && token.isNotEmpty && mounted) {
          _oauthPollTimer?.cancel();
          final auth = context.read<AuthProvider>();
          await auth.handleSocialAuthToken(
            token: token,
            refreshToken: refresh,
            isNewUser: isNewUser,
          );
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIncomingOAuthToken();
    });
  }

  void _checkIncomingOAuthToken() {
    final uri = Uri.base;
    final token = uri.queryParameters['token'];
    final refresh = uri.queryParameters['refresh'] ?? uri.queryParameters['refreshToken'] ?? '';
    final isNewUser = uri.queryParameters['is_new_user'] == 'true';
    if (token != null && token.isNotEmpty) {
      final auth = context.read<AuthProvider>();
      auth.handleSocialAuthToken(
        token: token,
        refreshToken: refresh,
        isNewUser: isNewUser,
      );
    }
  }

  Timer? _oauthPollTimer;

  @override
  void dispose() {
    _oauthPollTimer?.cancel();
    _floatCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (mounted && auth.error != null) {
      AppToast.error(context, auth.error!);
    }
  }

  /// Abre inmediatamente la ventana oficial emergente de autenticación del proveedor (Google, Facebook o LinkedIn).
  Future<void> _launchSocialOAuth({
    required String provider,
    required String providerName,
  }) async {
    String origin = '';
    if (kIsWeb) {
      try {
        origin = Uri.base.origin;
      } catch (_) {
        origin = '';
      }
    }

    final sessionId = 'tm_${DateTime.now().millisecondsSinceEpoch}_${math.Random.secure().nextInt(99999)}';
    final queryParams = <String, String>{
      'session_id': sessionId,
    };
    if (origin.isNotEmpty) {
      queryParams['redirect_origin'] = origin;
    }

    final oauthUrl = Uri.parse('$kBaseUrl/auth/oauth/$provider/authorize').replace(
      queryParameters: queryParams,
    );

    try {
      if (kIsWeb) {
        SocialPopupHelper.openPopup(
          oauthUrl.toString(),
          name: 'TalentMatch_${provider}_Auth',
        );
      } else {
        final launched = await launchUrl(
          oauthUrl,
          mode: LaunchMode.inAppBrowserView,
        );
        if (!launched) {
          await launchUrl(oauthUrl, mode: LaunchMode.platformDefault);
        }
      }

      // Inicia sondeo de sesión para sincronizar automáticamente el token en Android/móvil
      _startOAuthPolling(sessionId: sessionId, providerName: providerName);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'No se pudo abrir la ventana de $providerName: $e');
      }
    }
  }

  /// Sondeo no bloqueante que detecta cuando el usuario aprueba en el navegador.
  void _startOAuthPolling({
    required String sessionId,
    required String providerName,
  }) {
    _oauthPollTimer?.cancel();

    if (mounted) {
      AppToast.info(context, 'Conectando con $providerName...');
    }

    int attempts = 0;
    _oauthPollTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) async {
      attempts++;
      if (attempts > 180) {
        // Detener después de ~63 segundos
        timer.cancel();
        return;
      }

      try {
        final resp = await http.get(
          Uri.parse('$kBaseUrl/auth/oauth/session/$sessionId'),
        ).timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          if (data['status'] == 'completed') {
            timer.cancel();
            try {
              await closeInAppWebView();
            } catch (_) {}

            final token = data['token']?.toString();
            final refresh = data['refreshToken']?.toString() ?? '';
            final isNewUser = data['is_new_user'] == true;
            if (token != null && token.isNotEmpty && mounted) {
              final auth = context.read<AuthProvider>();
              await auth.handleSocialAuthToken(
                token: token,
                refreshToken: refresh,
                isNewUser: isNewUser,
              );
            }
          }
        }
      } catch (_) {}
    });
  }



  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isEs = localeProvider.isSpanish;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    // Colores y tipografía del diseño oficial
    const Color titleColor = kNavy;
    const Color subtitleColor = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── 1. Fondo de gradiente suave con orbes difusos ──
          const AmbientBackground(),

          // ── 2. Contenido desplazable seguro ante teclado ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Barra Superior: Logo TalentMatch y Selector de Idioma ──
                  _buildTopBar(context, isEs, localeProvider),

                  const SizedBox(height: 2),

                  // ── Hero Decorativo 3D con Flotación Suave de 8 Segundos ──
                  FloatingHeroDecor(
                    floatAnimation: _floatCtrl,
                    disableAnimations: disableAnimations,
                  ),

                  const SizedBox(height: 6),

                  // ── Titulares Principales ──
                  Text(
                    isEs
                        ? 'Tu talento merece\nun gran empleo.'
                        : 'Your talent deserves\na great career.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEs
                        ? 'Conecta con tu próxima oportunidad.'
                        : 'Connect with your next opportunity.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                      letterSpacing: -0.1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Tarjeta Glassmórfica Estática del Formulario ──
                  _buildGlassFormCard(context, auth, isEs),

                  const SizedBox(height: 14),

                  // ── Pie de Página: Registro ──
                  _buildFooter(context, isEs),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barra superior con el ícono de la marca y el selector de idioma ES / EN.
  Widget _buildTopBar(
    BuildContext context,
    bool isEs,
    LocaleProvider localeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo TalentMatch oficial
          const BrandFull(iconSize: 36),

          // Selector de Idioma (ES / EN) estilo cápsula limpia Figma
          AuthLanguagePill(
            isEs: isEs,
            onSelectEs: () => localeProvider.setLocale(const Locale('es')),
            onSelectEn: () => localeProvider.setLocale(const Locale('en')),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de vidrio esmerilado (Glassmorphism) que contiene los campos y acciones.
  Widget _buildGlassFormCard(
    BuildContext context,
    AuthProvider auth,
    bool isEs,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7),
                blurRadius: 1,
                offset: const Offset(-0.5, -0.5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera interna: Iniciar sesión + Candado decorativo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEs ? 'Iniciar sesión' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 19,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),

                // Alerta de error si el backend reporta alguna falla con diseño Glassmorphic
                if (auth.error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.92),
                                const Color(0xFFFEE2E2).withValues(alpha: 0.50),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5).withValues(alpha: 0.8),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => auth.clearError(),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF991B1B).withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFFB91C1C),
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Campo: Correo Electrónico ──
                Text(
                  isEs ? 'Correo electrónico' : 'Email address',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isEs
                          ? 'Ingresa tu correo electrónico'
                          : 'Please enter your email';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return isEs
                          ? 'Ingresa un correo electrónico válido'
                          : 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    hint: 'tu@correo.com',
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Campo: Contraseña ──
                Text(
                  isEs ? 'Contraseña' : 'Password',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return isEs
                          ? 'Ingresa tu contraseña'
                          : 'Please enter your password';
                    }
                    if (v.length < 8) {
                      return isEs
                          ? 'La contraseña debe tener al menos 8 caracteres'
                          : 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    hint: isEs
                        ? 'Introduce tu contraseña'
                        : 'Enter your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Enlace: ¿Olvidaste tu contraseña? ──
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        isEs
                            ? '¿Olvidaste tu contraseña?'
                            : 'Forgot your password?',
                        style: const TextStyle(
                          color: kBlue,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Botón Principal: Entrar → ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isEs ? 'Entrar' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Divisor: o continúa con ──
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        isEs ? 'o continúa con' : 'or continue with',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Botones de Autenticación Social (Google, LinkedIn y Facebook) ──
                Row(
                  children: [
                    // Botón Google
                    Expanded(
                      child: SocialAuthButton(
                        onTap: () => _launchSocialOAuth(
                          provider: 'google',
                          providerName: 'Google',
                        ),
                        iconWidget: const GoogleGLogo(size: 16),
                        label: 'Google',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón LinkedIn
                    Expanded(
                      child: SocialAuthButton(
                        onTap: () => _launchSocialOAuth(
                          provider: 'linkedin',
                          providerName: 'LinkedIn',
                        ),
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.linkedin,
                          color: Color(0xFF0A66C2),
                          size: 15,
                        ),
                        label: 'LinkedIn',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón Facebook
                    Expanded(
                      child: SocialAuthButton(
                        onTap: () => _launchSocialOAuth(
                          provider: 'facebook',
                          providerName: 'Facebook',
                        ),
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.facebook,
                          color: Color(0xFF1877F2),
                          size: 15,
                        ),
                        label: 'Facebook',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Estilo común para los campos de entrada de texto.
  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF94A3B8),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  /// Pie de página para navegar a la pantalla de registro.
  Widget _buildFooter(BuildContext context, bool isEs) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                isEs ? '¿Aún no tienes cuenta? ' : "Don't have an account? ",
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEs ? 'Regístrate' : 'Sign up',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: kBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: kBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}






