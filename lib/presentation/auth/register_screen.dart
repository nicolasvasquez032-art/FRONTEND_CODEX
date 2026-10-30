
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/colombia_location_picker.dart';
import '../../core/utils/validators.dart';

// ──────────────────────────────────────────────
// REGISTER SCREEN — TalentMatch
// ──────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  // ── Steps ──
  List<String> get _stepLabels =>
      _isCompany ? ['Cuenta'] : ['Cuenta', 'Perfil', 'Preferencias'];

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
    }
    if (!_isCompany && _step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    if (_isCompany) {
      await auth.registerCompany(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
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
      _snack(auth.error!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada! Por favor inicia sesión.'),
          backgroundColor: kGreen,
        ),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                      ? 'PASO 1 DE 1'
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
                  : _step == 1
                      ? _buildStep1(l10n)
                      : _buildStep2(l10n),
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
                        onTap: () => _snack('Términos y condiciones próximamente'),
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
                        onTap: () => _snack('Política de privacidad próximamente'),
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
    final isLastStep = _isCompany || _step == 2;
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
          child: _SocialButton(
            icon: FontAwesomeIcons.google,
            iconColor: const Color(0xFFDB4437),
            label: 'Google',
            onTap: () => _snack('Integración con Google próximamente'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: FontAwesomeIcons.linkedin,
            iconColor: const Color(0xFF0077B5),
            label: 'LinkedIn',
            onTap: () => _snack('Integración con LinkedIn próximamente'),
          ),
        ),
      ],
    );
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
// ORBITAL PAINTER
// ──────────────────────────────────────────────
class _OrbitalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1558D6).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.save();
    canvas.translate(size.width * 0.42, size.height * 0.45);
    canvas.scale(1.0, 0.38);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.width * 0.92, height: size.height * 0.92),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────
// ROLE CARD WIDGET
// ──────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final bool     selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kBlue : kLine,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected ? kBlue.withValues(alpha: 0.12) : kLine,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: selected ? kBlue : kMuted, size: 18),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? kBlue : kLine, width: 2),
                    color: selected ? kBlue : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 10, color: kWhite)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? kNavy : kText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// FIELD LABEL
// ──────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kNavy,
        ),
      );
}

// ──────────────────────────────────────────────
// REUSABLE TEXT FIELD
// ──────────────────────────────────────────────
class _RegTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const _RegTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kMuted, fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: kMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE7EBF2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.5),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// PASSWORD REQUIREMENTS
// ──────────────────────────────────────────────
class _PasswordRequirements extends StatelessWidget {
  final TextEditingController controller;
  const _PasswordRequirements({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final pwd  = value.text;
        final eval = Validators.evaluatePassword(pwd);

        final Color barColor = pwd.isEmpty
            ? Colors.grey.shade300
            : switch (eval.strength) {
                PasswordStrength.weak => Colors.redAccent,
                PasswordStrength.medium => Colors.orangeAccent,
                PasswordStrength.strong => const Color(0xFF10B981),
              };

        final String strengthLabel = pwd.isEmpty
            ? ''
            : switch (eval.strength) {
                PasswordStrength.weak => 'Seguridad: Débil',
                PasswordStrength.medium => 'Seguridad: Media',
                PasswordStrength.strong => 'Seguridad: Fuerte',
              };

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pwd.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strengthLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                    ),
                    Text(
                      '${eval.metCount}/4 requisitos',
                      style: const TextStyle(fontSize: 10, color: kMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: eval.fraction,
                    minHeight: 5,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const Text(
                'La contraseña debe tener:',
                style: TextStyle(fontSize: 11, color: kNavy, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _Req(text: 'Mínimo 8 caracteres',          met: eval.hasMinLength),
              _Req(text: 'Una mayúscula y una minúscula', met: eval.hasUpperAndLower),
              _Req(text: 'Al menos un número',           met: eval.hasNumber),
              _Req(text: 'Un carácter especial',         met: eval.hasSpecialChar),
            ],
          ),
        );
      },
    );
  }
}

class _Req extends StatelessWidget {
  final String text;
  final bool met;
  const _Req({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: met ? kGreen : kMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: met ? kGreen : kMuted,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SOCIAL BUTTON
// ──────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final FaIconData icon;
  final Color      iconColor;
  final String     label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        backgroundColor: Colors.white,
        side: const BorderSide(color: kLine, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: kNavy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
