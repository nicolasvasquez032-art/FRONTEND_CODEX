
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../legal/legal_screen.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/perfil_provider.dart';
import '../shared/widgets/app_toast.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/colombia_location_picker.dart';
import 'social_popup_helper.dart';
import 'widgets/auth_form_components.dart';
import 'widgets/social_auth_buttons.dart';

// ──────────────────────────────────────────────
// REGISTER SCREEN — TalentMatch
// ──────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  final int initialStep;
  final bool isSocialOnboarding;

  const RegisterScreen({
    super.key,
    this.initialStep = 0,
    this.isSocialOnboarding = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Form controllers ──
  final _formKey              = GlobalKey<FormState>();
  final _emailCtrl            = TextEditingController();
  final _passwordCtrl         = TextEditingController();
  final _confirmPasswordCtrl  = TextEditingController();
  final _fullNameCtrl         = TextEditingController();
  final _locationCtrl         = TextEditingController();
  final _skillsCtrl           = TextEditingController();
  final _educationCtrl        = TextEditingController();
  final _expCtrl              = TextEditingController(text: '0');

  // ── Company Form controllers ──
  final _companyNameCtrl     = TextEditingController();
  final _companyLocationCtrl = TextEditingController();
  final _companyWebsiteCtrl  = TextEditingController();
  final _companyDescCtrl     = TextEditingController();
  String _companySector      = 'Tecnología';
  String _companySize        = '11-50';
  int    _selectedCompanyColorIndex = 0;

  // ── State ──
  bool _obscurePassword       = true;
  bool _obscureConfirm        = true;
  bool _acceptedTerms         = false;
  int  _step                  = 0; // 0 = Cuenta, 1 = Perfil (candidato), 2 = Preferencias
  bool _isCompany             = false;

  // ── Floating animation controllers ──
  late final AnimationController _floatCtrl;
  late final AnimationController _starCtrl;
  late final Animation<double>   _floatAnim;
  late final Animation<double>   _starAnim;

  Timer? _oauthPollTimer;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;

    if (kIsWeb) {
      SocialPopupHelper.onWebMessage((data) async {
        final token = data['token']?.toString();
        final refresh = data['refreshToken']?.toString() ?? '';
        if (token != null && token.isNotEmpty && mounted) {
          _oauthPollTimer?.cancel();
          final auth = context.read<AuthProvider>();
          await auth.handleSocialAuthToken(token: token, refreshToken: refresh, isNewUser: true);
          if (mounted && auth.status == AuthStatus.authenticated) {
            AppToast.success(context, '¡Autenticado con éxito! Completa tu perfil.');
            setState(() {
              _step = 1;
              final session = auth.session;
              final email = session?.email;
              if (session != null && email != null && email.isNotEmpty) {
                if (_emailCtrl.text.isEmpty) _emailCtrl.text = email;
                if (_fullNameCtrl.text.isEmpty) {
                  _fullNameCtrl.text = email.split('@').first;
                }
              }
            });
          }
        }
      });
    }

    if (widget.isSocialOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final session = context.read<AuthProvider>().session;
        final email = session?.email;
        if (session != null && email != null && email.isNotEmpty) {
          if (_emailCtrl.text.isEmpty) _emailCtrl.text = email;
          if (_fullNameCtrl.text.isEmpty) {
            _fullNameCtrl.text = email.split('@').first;
          }
        }
      });
    }

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _starAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _starCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _oauthPollTimer?.cancel();
    _floatCtrl.dispose();
    _starCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _fullNameCtrl.dispose();
    _locationCtrl.dispose();
    _skillsCtrl.dispose();
    _educationCtrl.dispose();
    _expCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyLocationCtrl.dispose();
    _companyWebsiteCtrl.dispose();
    _companyDescCtrl.dispose();
    super.dispose();
  }

  // ── Steps ──
  List<String> get _stepLabels =>
      _isCompany ? ['Cuenta', 'Empresa'] : ['Cuenta', 'Perfil', 'Preferencias'];

  // ── Navigation ──
  void _nextStep() {
    // Validate current step fields inline
    if (_step == 0) {
      if (!_isCompany && _fullNameCtrl.text.trim().length < 2) {
        _snack('Ingresa tu nombre completo.');
        return;
      }
      if (!_emailCtrl.text.contains('@')) {
        _snack('Ingresa un correo electrónico válido.');
        return;
      }
      final pwd = _passwordCtrl.text;
      if (pwd.length < 8) {
        _snack('La contraseña debe tener al menos 8 caracteres.');
        return;
      }
      if (!RegExp(r'[A-Z]').hasMatch(pwd) || !RegExp(r'[a-z]').hasMatch(pwd)) {
        _snack('La contraseña debe incluir mayúscula y minúscula.');
        return;
      }
      if (!RegExp(r'[0-9]').hasMatch(pwd)) {
        _snack('La contraseña debe incluir al menos un número.');
        return;
      }
      if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>\-_\+=;\[\]~`\\]').hasMatch(pwd)) {
        _snack('La contraseña debe incluir al menos un carácter especial.');
        return;
      }
      if (pwd != _confirmPasswordCtrl.text) {
        _snack('Las contraseñas no coinciden.');
        return;
      }
      if (!_acceptedTerms) {
        _snack('Debes aceptar los términos y la política de privacidad.');
        return;
      }

      setState(() => _step = 1);
      return;
    }

    if (_isCompany && _step == 1) {
      if (_companyNameCtrl.text.trim().length < 2) {
        _snack('Ingresa el nombre o razón social de la empresa.');
        return;
      }
      if (_companyLocationCtrl.text.trim().isEmpty) {
        _snack('Selecciona o ingresa la ubicación de la empresa.');
        return;
      }
      _submit();
      return;
    }

    if (!_isCompany && _step == 1) {
      setState(() => _step = 2);
      return;
    }

    if (!_isCompany && _step == 2) {
      _submit();
      return;
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    if (widget.isSocialOnboarding) {
      final session = auth.session;
      var profileId = session?.profileId ?? '';
      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final perfilProv = context.read<PerfilProvider>();
      if (profileId.isEmpty) {
        await perfilProv.cargar();
        profileId = perfilProv.profile?.id ?? '';
      }

      if (profileId.isNotEmpty) {
        await perfilProv.guardar(
          profileId: profileId,
          fullName: _fullNameCtrl.text.trim().isNotEmpty
              ? _fullNameCtrl.text.trim()
              : (perfilProv.profile?.fullName ?? session?.email ?? 'Candidato'),
          skills: skills,
          experienceYears: int.tryParse(_expCtrl.text) ?? 0,
          location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
          education: _educationCtrl.text.trim().isNotEmpty ? _educationCtrl.text.trim() : null,
        );
      }
      if (mounted) {
        AppToast.success(context, '¡Perfil completado exitosamente!');
        auth.markProfileCompleted();
      }
      return;
    }

    if (_isCompany) {
      await auth.registerCompany(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        nombre: _companyNameCtrl.text.trim(),
      );

      if (auth.error == null) {
        final prefs = await SharedPreferences.getInstance();
        final email = _emailCtrl.text.trim();
        final companyName = _companyNameCtrl.text.trim();
        final session = auth.session;
        final uid = session?.userId ?? email;

        await prefs.setString('company_name_$uid', companyName);
        await prefs.setString('company_sector_$uid', _companySector);
        await prefs.setString('company_location_$uid', _companyLocationCtrl.text.trim());
        await prefs.setString('company_size_$uid', _companySize);
        await prefs.setString('company_website_$uid', _companyWebsiteCtrl.text.trim());
        await prefs.setString('company_desc_$uid', _companyDescCtrl.text.trim());
        await prefs.setInt('company_color_$uid', _selectedCompanyColorIndex);
        await prefs.setString('company_plan_$uid', 'Plan Gratuito');

        await prefs.setString('company_name_active', companyName);
        await prefs.setString('company_location_active', _companyLocationCtrl.text.trim());
      }
    } else {
      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await auth.registerCandidate(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _fullNameCtrl.text.trim(),
        skills: skills,
        experienceYears: int.tryParse(_expCtrl.text) ?? 0,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        education: _educationCtrl.text.trim().isEmpty ? null : _educationCtrl.text.trim(),
      );
    }

    if (!mounted) return;

    if (auth.error != null) {
      _snack(auth.error!, type: ToastType.error);
    } else {
      AppToast.success(context, '¡Cuenta creada! Por favor inicia sesión.');
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _snack(String msg, {ToastType type = ToastType.warning}) {
    AppToast.show(context, message: msg, type: type);
  }

  // ──────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final l10n   = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: kBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kNavy, size: 20),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: const BrandFull(iconSize: 28),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: kNavy, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¿Necesitas ayuda? Escríbenos a soporte@talentmatch.co')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2FF), kBg],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero ──
                _buildHero(),

                // ── Form Card ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _buildFormCard(auth, l10n),
                ),

                const SizedBox(height: 28),

                // ── Footer ──
                _buildFooter(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  // HERO SECTION
  // ──────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 320,
            height: 175,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Orbital ellipse behind
                Positioned.fill(
                  child: CustomPaint(painter: _OrbitalPainter()),
                ),

                // Floating cyan dot left
                Positioned(
                  left: 16,
                  bottom: 45,
                  child: AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value * 0.5),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: kCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating blue dot right
                Positioned(
                  right: 24,
                  bottom: 35,
                  child: AnimatedBuilder(
                    animation: _starAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _starAnim.value * 0.4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: kCyan.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3D Star — floating on upper right
                Positioned(
                  top: 15,
                  right: 32,
                  child: AnimatedBuilder(
                    animation: _starAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _starAnim.value),
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/talent_match_star.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),

                // 3D Briefcase — centered and floating smoothly
                Center(
                  child: AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/talent_match_briefcase.png',
                      width: 185,
                      height: 155,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Headline & subtitle cleanly below the illustration
        const Text(
          'Conecta con tu futuro.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: kNavy,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tu talento y las mejores oportunidades,\nen un mismo lugar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: kMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ──────────────────────────────────────
  // FORM CARD
  // ──────────────────────────────────────
  Widget _buildFormCard(AuthProvider auth, AppLocalizations? l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isCompany
                      ? 'PASO ${_step + 1} DE 2'
                      : 'PASO ${_step + 1} DE 3',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: kBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Tab stepper ──
          _buildStepper(),

          const SizedBox(height: 22),

          // ── Form ──
          Form(
            key: _formKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _step == 0
                  ? _buildStep0(l10n)
                  : (_isCompany
                      ? _buildCompanyStep1(l10n)
                      : (_step == 1
                          ? _buildStep1(l10n)
                          : _buildStep2(l10n))),
            ),
          ),

          const SizedBox(height: 22),

          // ── Primary Button ──
          _buildPrimaryButton(auth),

          // ── Social buttons (step 0 only) ──
          if (_step == 0) ...[
            const SizedBox(height: 20),
            _buildSocialDivider(l10n),
            const SizedBox(height: 16),
            _buildSocialButtons(),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // STEPPER
  // ──────────────────────────────────────
  Widget _buildStepper() {
    final labels = _stepLabels;
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i == _step;
        final isDone   = i < _step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: Column(
              children: [
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    color: isActive
                        ? kBlue
                        : isDone
                            ? kGreen
                            : kMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: isActive
                        ? kBlue
                        : isDone
                            ? kGreen
                            : kLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ──────────────────────────────────────
  // STEP 0 — Cuenta
  // ──────────────────────────────────────
  Widget _buildStep0(AppLocalizations? l10n) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Role selector ──
        const Text(
          '¿Cómo quieres conectar?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kNavy,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                icon: Icons.person_outline_rounded,
                title: 'Candidato',
                subtitle: 'Busco empleo',
                selected: !_isCompany,
                onTap: () => setState(() {
                  _isCompany = false;
                  _step = 0;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                icon: Icons.business_outlined,
                title: 'Empresa',
                subtitle: 'Busco talento',
                selected: _isCompany,
                onTap: () => setState(() {
                  _isCompany = true;
                  _step = 0;
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── Full name (candidate only) ──
        if (!_isCompany) ...[
          const _FieldLabel('Nombre completo'),
          const SizedBox(height: 6),
          _RegTextField(
            controller: _fullNameCtrl,
            hint: 'Ej. Juan Pérez',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
        ],

        // ── Email ──
        _FieldLabel(l10n?.loginEmailLabel ?? 'Correo electrónico'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _emailCtrl,
          hint: 'tu@correo.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        // Email domain suggestions
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _emailCtrl,
          builder: (context, value, child) {
            final text = value.text;
            if (!text.contains('@')) return const SizedBox.shrink();
            final parts      = text.split('@');
            final localPart  = parts[0];
            final typedDomain = parts.length > 1 ? parts[1].toLowerCase() : '';
            final allDomains  = ['gmail.com', 'hotmail.com', 'yahoo.com', 'outlook.com'];
            final suggestions = allDomains.where((d) => d.startsWith(typedDomain) && d != typedDomain).toList();
            if (suggestions.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestions.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(d, style: const TextStyle(fontSize: 11, color: kNavy)),
                      backgroundColor: kLine,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        _emailCtrl.text = '$localPart@$d';
                        _emailCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: _emailCtrl.text.length),
                        );
                      },
                    ),
                  )).toList(),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // ── Password ──
        _FieldLabel(l10n?.loginPasswordLabel ?? 'Contraseña'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _passwordCtrl,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        // Password requirements
        const SizedBox(height: 10),
        _PasswordRequirements(controller: _passwordCtrl),

        const SizedBox(height: 14),

        // ── Confirm password ──
        const _FieldLabel('Confirmar contraseña'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _confirmPasswordCtrl,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),

        const SizedBox(height: 18),

        // ── Terms ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                activeColor: kBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Acepto los ',
                  style: const TextStyle(fontSize: 12, color: kMuted),
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          LegalScreen.showModal(
                            context,
                            initialTab: 0,
                            onAccept: () => setState(() => _acceptedTerms = true),
                          );
                        },
                        child: const Text(
                          'Términos y condiciones',
                          style: TextStyle(
                            fontSize: 12,
                            color: kBlue,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' y la '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          LegalScreen.showModal(
                            context,
                            initialTab: 1,
                            onAccept: () => setState(() => _acceptedTerms = true),
                          );
                        },
                        child: const Text(
                          'Política de privacidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: kBlue,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  // STEP 1 (EMPRESA) — Perfil Corporativo
  // ──────────────────────────────────────
  Widget _buildCompanyStep1(AppLocalizations? l10n) {
    final colors = [
      const Color(0xFF2563EB), // Azul Royal
      const Color(0xFF0D9488), // Teal
      const Color(0xFF7C3AED), // Púrpura
      const Color(0xFF0284C7), // Cian
      const Color(0xFF059669), // Esmeralda
    ];

    final companyInitial = _companyNameCtrl.text.trim().isNotEmpty
        ? _companyNameCtrl.text.trim()[0].toUpperCase()
        : 'E';

    return Column(
      key: const ValueKey(101),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil Corporativo',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Completa los datos de tu empresa para posicionar tu marca empleadora y atraer al mejor talento.',
          style: TextStyle(fontSize: 12, color: kMuted, height: 1.4),
        ),
        const SizedBox(height: 18),

        // ── Logo / Identidad de la Empresa ──
        Center(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors[_selectedCompanyColorIndex],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[_selectedCompanyColorIndex].withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  companyInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Color de marca corporativa',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(colors.length, (idx) {
                  final isSel = _selectedCompanyColorIndex == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCompanyColorIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors[idx],
                        shape: BoxShape.circle,
                        border: isSel
                            ? Border.all(color: kNavy, width: 2.5)
                            : Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Nombre de la Empresa ──
        const _FieldLabel('Nombre de la Empresa / Razón Social'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _companyNameCtrl,
          hint: 'Ej. TechNova Solutions S.A.S.',
          prefixIcon: Icons.apartment_rounded,
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 14),

        // ── Sector / Industria ──
        const _FieldLabel('Sector o Industria'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Tecnología',
            'Fintech',
            'Salud',
            'Comercio',
            'Educación',
            'Servicios',
          ].map((sector) {
            final isSel = _companySector == sector;
            return ChoiceChip(
              label: Text(sector),
              selected: isSel,
              onSelected: (_) => setState(() => _companySector = sector),
              selectedColor: kBlue.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSel ? kBlue : kNavy,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSel ? kBlue : kLine),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // ── Ubicación de la Empresa ──
        const _FieldLabel('Ubicación de la Sede Principal'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _companyLocationCtrl,
          hint: 'Selecciona ciudad (ej. Bogotá, Colombia)',
          prefixIcon: Icons.location_on_outlined,
          readOnly: true,
          onTap: () async {
            final result = await showColombiaLocationPicker(context);
            if (result != null) setState(() => _companyLocationCtrl.text = result);
          },
        ),

        const SizedBox(height: 14),

        // ── Tamaño de la Empresa ──
        const _FieldLabel('Tamaño de la Empresa'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '1-10 (Startup)',
            '11-50 (Pequeña)',
            '51-200 (Mediana)',
            '200+ (Corporativa)',
          ].map((size) {
            final val = size.split(' ').first;
            final isSel = _companySize == val;
            return ChoiceChip(
              label: Text(size),
              selected: isSel,
              onSelected: (_) => setState(() => _companySize = val),
              selectedColor: kBlue.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSel ? kBlue : kNavy,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSel ? kBlue : kLine),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // ── Sitio Web Corporativo ──
        const _FieldLabel('Sitio Web o LinkedIn Corporativo (Opcional)'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _companyWebsiteCtrl,
          hint: 'https://miempresa.com',
          prefixIcon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),

        const SizedBox(height: 14),

        // ── Breve descripción ──
        const _FieldLabel('Descripción breve de la empresa (Opcional)'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _companyDescCtrl,
          hint: 'Ej. Empresa líder en desarrollo de soluciones cloud...',
          prefixIcon: Icons.edit_note_rounded,
        ),

        const SizedBox(height: 18),

        // ── Tarjeta Plan Gratuito ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Gratuito Activo (Free Tier)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14532D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tu cuenta incluye publicación de vacantes, postulación de candidatos y entrevistas sin costo.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF166534),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  // STEP 1 — Perfil Profesional
  // ──────────────────────────────────────
  Widget _buildStep1(AppLocalizations? l10n) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuéntanos sobre ti',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Esta información nos ayuda a encontrar las mejores oportunidades para ti.',
          style: TextStyle(fontSize: 12, color: kMuted),
        ),
        const SizedBox(height: 18),

        _FieldLabel(l10n?.registerLocationLabel ?? 'Ciudad / Ubicación'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _locationCtrl,
          hint: 'Selecciona tu ciudad',
          prefixIcon: Icons.location_on_outlined,
          readOnly: true,
          onTap: () async {
            final result = await showColombiaLocationPicker(context);
            if (result != null) setState(() => _locationCtrl.text = result);
          },
        ),

        const SizedBox(height: 14),
        _FieldLabel(l10n?.registerEducationLabel ?? 'Nivel educativo'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _educationCtrl,
          hint: 'Ej. Tecnólogo en Sistemas',
          prefixIcon: Icons.school_outlined,
        ),

        const SizedBox(height: 14),
        _FieldLabel(l10n?.registerExperienceYearsLabel ?? 'Años de experiencia'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _expCtrl,
          hint: '0',
          prefixIcon: Icons.work_outline_rounded,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  // STEP 2 — Habilidades
  // ──────────────────────────────────────
  Widget _buildStep2(AppLocalizations? l10n) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tus habilidades',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Agrega tus habilidades separadas por comas para conectar con las vacantes perfectas.',
          style: TextStyle(fontSize: 12, color: kMuted),
        ),
        const SizedBox(height: 18),

        _FieldLabel(l10n?.registerSkillsLabel ?? 'Habilidades'),
        const SizedBox(height: 6),
        _RegTextField(
          controller: _skillsCtrl,
          hint: 'Ej. Python, SQL, Comunicación',
          prefixIcon: Icons.star_outline_rounded,
          maxLines: 3,
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: kBlue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cuantas más habilidades agregues, mayor será tu compatibilidad con las vacantes.',
                  style: TextStyle(fontSize: 11, color: kNavy, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  // PRIMARY BUTTON
  // ──────────────────────────────────────
  Widget _buildPrimaryButton(AuthProvider auth) {
    final isLastStep = (_isCompany && _step == 1) || (!_isCompany && _step == 2);
    final label = isLastStep ? 'Crear cuenta' : 'Continuar';

    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: auth.loading ? null : const LinearGradient(
            colors: [Color(0xFF1667DC), kBlue],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: auth.loading ? kLine : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: auth.loading
              ? []
              : [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: auth.loading ? null : _nextStep,
          child: auth.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlue),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: kWhite, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  // SOCIAL DIVIDER
  // ──────────────────────────────────────
  Widget _buildSocialDivider(AppLocalizations? l10n) {
    return Row(
      children: [
        Expanded(child: Divider(color: kNavy.withValues(alpha: 0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            l10n?.registerOrWith ?? 'O regístrate con',
            style: const TextStyle(color: kMuted, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: kNavy.withValues(alpha: 0.1))),
      ],
    );
  }

  // ──────────────────────────────────────
  // SOCIAL BUTTONS
  // ──────────────────────────────────────
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: SocialAuthButton(
            iconWidget: const GoogleGLogo(size: 16),
            label: 'Google',
            onTap: () => _launchRegisterSocialOAuth(
              provider: 'google',
              providerName: 'Google',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SocialAuthButton(
            iconWidget: const FaIcon(
              FontAwesomeIcons.linkedin,
              color: Color(0xFF0077B5),
              size: 15,
            ),
            label: 'LinkedIn',
            onTap: () => _launchRegisterSocialOAuth(
              provider: 'linkedin',
              providerName: 'LinkedIn',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SocialAuthButton(
            iconWidget: const FaIcon(
              FontAwesomeIcons.facebook,
              color: Color(0xFF1877F2),
              size: 15,
            ),
            label: 'Facebook',
            onTap: () => _launchRegisterSocialOAuth(
              provider: 'facebook',
              providerName: 'Facebook',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchRegisterSocialOAuth({
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

    final sessionId = 'tm_reg_${DateTime.now().millisecondsSinceEpoch}_${math.Random.secure().nextInt(99999)}';
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
          name: 'TalentMatch_${provider}_Register',
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

      _startRegisterOAuthPolling(sessionId: sessionId, providerName: providerName);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'No se pudo abrir la ventana de $providerName: $e');
      }
    }
  }

  void _startRegisterOAuthPolling({
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
            if (token != null && token.isNotEmpty && mounted) {
              final auth = context.read<AuthProvider>();
              await auth.handleSocialAuthToken(token: token, refreshToken: refresh, isNewUser: true);
              if (mounted && auth.status == AuthStatus.authenticated) {
                AppToast.success(context, '¡Cuenta verificada! Cuéntanos sobre ti.');
                setState(() {
                  _step = 1;
                  final email = data['email']?.toString() ?? '';
                  if (_emailCtrl.text.isEmpty && email.isNotEmpty) {
                    _emailCtrl.text = email;
                    _fullNameCtrl.text = email.split('@').first;
                  }
                });
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  // ──────────────────────────────────────
  // FOOTER
  // ──────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('¿Ya tienes cuenta? ', style: TextStyle(color: kMuted, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Inicia sesión',
                style: TextStyle(color: kBlue, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 12, color: kMuted),
            SizedBox(width: 4),
            Text(
              'Tu talento, en un espacio seguro.',
              style: TextStyle(fontSize: 11, color: kMuted),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// TYPEDEFS HACIA WIDGETS MODULARES
// ──────────────────────────────────────────────
typedef _OrbitalPainter = OrbitalPainter;
typedef _RoleCard = RoleSelectorCard;
typedef _FieldLabel = FormFieldLabel;
typedef _RegTextField = FormTextInputField;

typedef _PasswordRequirements = PasswordRequirementsBox;
