import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/widgets/brand_logo.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

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
  }

  @override
  void dispose() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
          const _AmbientBackground(),

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
                  _FloatingHeroDecor(
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
          _LanguageSegmentedPill(
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

                // Alerta de error si el backend reporta alguna falla
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auth.error!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => auth.clearError(),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFF87171),
                            size: 17,
                          ),
                        ),
                      ],
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

                // ── Botones de Autenticación Social (Google y LinkedIn) ──
                Row(
                  children: [
                    // Botón Google
                    Expanded(
                      child: _SocialAuthButton(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEs
                                    ? 'Inicio de sesión con Google próximamente'
                                    : 'Google Sign In coming soon',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        iconWidget: const _GoogleGLogo(size: 18),
                        label: 'Google',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón LinkedIn
                    Expanded(
                      child: _SocialAuthButton(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEs
                                    ? 'Inicio de sesión con LinkedIn próximamente'
                                    : 'LinkedIn Sign In coming soon',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.linkedin,
                          color: Color(0xFF0A66C2),
                          size: 18,
                        ),
                        label: 'LinkedIn',
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

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES DECORATIVOS & HERO ANIMADO (8 SEGUNDOS DE FLOTACIÓN SUAVE)
// ─────────────────────────────────────────────────────────────────────────────

/// Hero decorativo con la escultura 3D y elementos flotantes independientes.
class _FloatingHeroDecor extends StatelessWidget {
  final Animation<double> floatAnimation;
  final bool disableAnimations;

  const _FloatingHeroDecor({
    required this.floatAnimation,
    required this.disableAnimations,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      width: double.infinity,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: floatAnimation,
          builder: (context, child) {
            // Valor normalizado t entre 0.0 y 1.0
            final double t = disableAnimations ? 0.0 : floatAnimation.value;

            // Oscilación armónica suave compacta
            final double mainFloatY = disableAnimations
                ? 0.0
                : math.sin(t * math.pi * 2) * 6.0;
            final double mainDriftX = disableAnimations
                ? 0.0
                : math.cos(t * math.pi * 2) * 2.5;
            final double mainRotate = disableAnimations
                ? 0.0
                : math.sin(t * math.pi * 2) * 0.035; // ~2 grados

            // Desfase para los elementos secundarios
            final double userFloatY = disableAnimations
                ? 0.0
                : math.sin((t + 0.25) * math.pi * 2) * 5.0;
            final double userRotate = disableAnimations
                ? 0.0
                : math.cos((t + 0.25) * math.pi * 2) * 0.035;

            final double workFloatY = disableAnimations
                ? 0.0
                : math.sin((t + 0.60) * math.pi * 2) * 5.5;
            final double workRotate = disableAnimations
                ? 0.0
                : -math.sin((t + 0.60) * math.pi * 2) * 0.035;

            final double sphereFloatY = disableAnimations
                ? 0.0
                : math.cos((t + 0.80) * math.pi * 2) * 4.5;

            final double sparkleFloatY = disableAnimations
                ? 0.0
                : math.sin((t + 0.40) * math.pi * 2) * 3.5;
            final double sparkleOpacity = disableAnimations
                ? 0.9
                : (0.7 + (math.sin(t * math.pi * 2).abs() * 0.3)).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── Resplandor ambiental cian/azul detrás de la escultura (reemplaza morado) ──
                Positioned(
                  child: Container(
                    width: 175,
                    height: 125,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kCyan.withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: kBlue.withValues(alpha: 0.16),
                          blurRadius: 55,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 1. Escultura 3D Central (Eslabones Azul Glaciar & Marino - Agrandado un poquito) ──
                Transform.translate(
                  offset: Offset(mainDriftX, mainFloatY),
                  child: Transform.rotate(
                    angle: mainRotate,
                    child: Image.asset(
                      'assets/images/talent_match_3d_chains.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),

                // ── 2. Tarjeta Flotante Izquierda: Avatar de Usuario ──
                Positioned(
                  left: 20,
                  top: 10,
                  child: Transform.translate(
                    offset: Offset(0, userFloatY),
                    child: Transform.rotate(
                      angle: userRotate,
                      child: const _FloatingFrostedTile(
                        size: 44,
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: kBlue,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 3. Tarjeta Flotante Derecha: Maletín de Empleo ──
                Positioned(
                  right: 20,
                  bottom: 10,
                  child: Transform.translate(
                    offset: Offset(0, workFloatY),
                    child: Transform.rotate(
                      angle: workRotate,
                      child: const _FloatingFrostedTile(
                        size: 44,
                        child: Icon(
                          Icons.business_center_outlined,
                          color: kBlue,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 4. Esfera Iridiscente Flotante Azul / Celeste (Superior Derecha) ──
                Positioned(
                  right: 48,
                  top: 8,
                  child: Transform.translate(
                    offset: Offset(0, sphereFloatY),
                    child: const _FloatingSphere(size: 15),
                  ),
                ),

                // ── 5. Destello 4 Puntas en Azul Cian (Medio Izquierda) ──
                Positioned(
                  left: 42,
                  bottom: 22,
                  child: Transform.translate(
                    offset: Offset(0, sparkleFloatY),
                    child: Opacity(
                      opacity: sparkleOpacity,
                      child: const _SparkleStar(
                        size: 14,
                        color: kCyan,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tarjeta translúcida flotante para los íconos de usuario y maletín.
class _FloatingFrostedTile extends StatelessWidget {
  final Widget child;
  final double size;

  const _FloatingFrostedTile({
    required this.child,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 1,
            offset: const Offset(-0.5, -0.5),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

/// Esfera perlada decorativa iridiscente en tonos azules oficiales TalentMatch.
class _FloatingSphere extends StatelessWidget {
  final double size;

  const _FloatingSphere({this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 0.8,
          colors: [
            Colors.white,
            Color(0xFFE0F2FE),
            Color(0xFF7DD3FC),
            kBlue,
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(1, 4),
          ),
        ],
      ),
    );
  }
}

/// Destello o estrella de 4 puntas en tonos cian/azul.
class _SparkleStar extends StatelessWidget {
  final double size;
  final Color color;

  const _SparkleStar({
    this.size = 14,
    this.color = kCyan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparklePainter(color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Selector de idioma segmentado (ES / EN) estilo cápsula limpia Figma.
class _LanguageSegmentedPill extends StatelessWidget {
  final bool isEs;
  final VoidCallback onSelectEs;
  final VoidCallback onSelectEn;

  const _LanguageSegmentedPill({
    required this.isEs,
    required this.onSelectEs,
    required this.onSelectEn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageSegmentItem(
            label: 'ES',
            selected: isEs,
            onTap: onSelectEs,
          ),
          _LanguageSegmentItem(
            label: 'EN',
            selected: !isEs,
            onTap: onSelectEn,
          ),
        ],
      ),
    );
  }
}

class _LanguageSegmentItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageSegmentItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? kBlue : const Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Botón de autenticación social (Google o LinkedIn).
class _SocialAuthButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget iconWidget;
  final String label;

  const _SocialAuthButton({
    required this.onTap,
    required this.iconWidget,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo auténtico de Google en 4 colores dibujado vectorialmente.
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.22;
    final radius = (w - strokeWidth) / 2;
    final center = Offset(w / 2, h / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Colores oficiales de la marca Google
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    // Arco Rojo (superior)
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.356,
      1.57,
      false,
      paint,
    );

    // Arco Amarillo (izquierdo)
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.356,
      1.57,
      false,
      paint,
    );

    // Arco Verde (inferior)
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.785,
      1.57,
      false,
      paint,
    );

    // Arco Azul (derecho)
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.785,
      1.57,
      false,
      paint,
    );

    // Barra horizontal azul
    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(w * 0.45, h * 0.39, w - (strokeWidth / 5), h * 0.61),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fondo ambiental con orbes luminosos estilo Glassmorphic moderno.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradiente base suave
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFF5FE),
                  Color(0xFFF3F6FD),
                  Color(0xFFFFF7F2),
                ],
              ),
            ),
          ),
        ),

        // Orbe superior izquierdo (Azul cian suave TalentMatch - adiós morados)
        Positioned(
          top: -60,
          left: -40,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBAE6FD).withValues(alpha: 0.35),
                  const Color(0xFFE0F2FE).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Orbe medio derecho (Brillo cálido melocotón suave)
        Positioned(
          top: 140,
          right: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFED7AA).withValues(alpha: 0.38),
                  const Color(0xFFFFEDD5).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Orbe inferior (Azul hielo difuso)
        Positioned(
          bottom: -100,
          left: 20,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBAE6FD).withValues(alpha: 0.25),
                  const Color(0xFFE0F2FE).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
